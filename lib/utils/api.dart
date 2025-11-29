import 'dart:convert';
import 'dart:io';

import 'package:appwrite/models.dart';
import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:appwrite/appwrite.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:http/http.dart' as http;
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AccountStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class BaseAPI extends ChangeNotifier {
  late User _currentUser;
  AccountStatus _status = AccountStatus.uninitialized;

  final Client _client = Client();
  String? _jwt;
  late Account _account;
  Map cachedTimetables = {};
  Map cachedPfpVersions = {};
  Map cachedNames = {};
  List? cachedFriends;
  Future<void>? caching;

  User get currentUser => _currentUser;
  AccountStatus get status => _status;
  String? get email => _currentUser.email;
  String? get userid => _currentUser.$id;
  Client get client => _client;

  BaseAPI() {
    init();
    loadUser();
  }

  init() {
    _client
        .setEndpoint(MyRunshawConfig.endpoint)
        .setProject(MyRunshawConfig.projectId);
    _account = Account(_client);
  }

  loadUser() async {
    try {
      final User user = await _account.get();
      _currentUser = user;
      _account = Account(_client);
      _status = AccountStatus.authenticated;
      if (!kIsWeb) {
        if (!Platform.isLinux) {
          OneSignal.login(_currentUser.$id);
        }
      }
    } catch (e) {
      _status = AccountStatus.unauthenticated;
    }
    notifyListeners();
  }

  String getJsonFromJWT(String splitToken) {
    String normalizedSource = base64Url.normalize(splitToken);
    return utf8.decode(base64Url.decode(normalizedSource));
  }

  Future<String> getJwt() async {
    // As of v1.2.5, this is the preferred way to get a JWT for API requests as it prevents unnecessary API calls
    // to get a new JWT if the current one is still valid.
    if (_jwt == null) {
      // Normal on first API call after cold start
      _jwt = await _account.createJWT().then((Jwt jwt) => jwt.jwt);
      debugLog("JWT is null, creating new one");
      debugLog("New JWT: $_jwt");
      return _jwt!;
    }
    // Split the JWT into its three parts - header, payload, signature
    final String splitToken = _jwt!.split(".")[1]; // Payload

    final maybeValidJwt = getJsonFromJWT(splitToken);

    if ((jsonDecode(maybeValidJwt)["exp"] * 1000) <
        DateTime.now().millisecondsSinceEpoch) {
      // Appwrite uses seconds, not milliseconds, since epoch

      // JWT is expired
      debugLog("JWT is expired, creating new one");
      debugLog(
          "Original expired at ${jsonDecode(maybeValidJwt)["exp"] * 1000}, now is ${DateTime.now().millisecondsSinceEpoch}");
      _jwt = await _account.createJWT().then((Jwt jwt) => jwt.jwt);
      debugLog("New JWT: $_jwt");
      return _jwt!;
    } else {
      // JWT is still valid
      debugLog("JWT is still valid");
      return _jwt!;
    }
  }

  Future<User?> createUser(
      {required String email, required String password}) async {
    String userId = "";
    userId = email
        .replaceAll(MyRunshawConfig.emailExtension, "")
        .toLowerCase()
        .split("-")
        .first;

    loadUser();
    final user = await _account.create(
      userId: userId,
      email: "$userId${MyRunshawConfig.emailExtension}",
      password: password,
    );
    _currentUser = user;
    _status = AccountStatus.authenticated;
    await createEmailSession(email: email, password: password);
    notifyListeners();
    loadUser();

    RegExp regExp = RegExp(r'-\d{6}');
    if (regExp.hasMatch(email)) {
      final String code =
          regExp.firstMatch(email)!.group(0)!.replaceAll("-", "");
      await setCode(
        code,
      );
    } else {
      await setCode("000000");
    }
    return _currentUser;
  }

  Future<String> getCode() async {
    Preferences result = await account!.getPrefs();
    return result.data["code"];
  }

  Future<void> setCode(String code) async {
    await account!.updatePrefs(prefs: {"code": code});
  }

  Future<void> cacheTimetables() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache

    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable/batch_get'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );
    cachedTimetables = jsonDecode(response.body);
  }

  Future<void> cacheFriends() async {
    final friends = await getFriends(force: true);

    cachedFriends = friends;
    notifyListeners();
    return;
  }

  Future<void> cachePfpVersions() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();
    cachedPfpVersions = {};

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache!

    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/cache/get/pfp-versions'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );
    cachedPfpVersions = jsonDecode(response.body);
  }

  Future<void> cacheNames() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache!

    final response = await http.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/name/get/batch'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );

    cachedNames = jsonDecode(response.body);
  }

  Future<void> createEmailSession(
      {required String email, required String password}) async {
    if (email.contains("-")) {
      email = email.split("-").first.replaceAll(MyRunshawConfig.emailExtension, "");
    } else {
      email = email.replaceAll(MyRunshawConfig.emailExtension, "");
    }
    await _account.createEmailPasswordSession(
      email: "$email${MyRunshawConfig.emailExtension}",
      password: password,
    );
    _currentUser = await Account(_client).get();
    if (!kIsWeb) {
      if (!Platform.isLinux) {
        OneSignal.login(_currentUser.$id);
      }
    }
    _status = AccountStatus.authenticated;
    await cacheFriends(); // most other cache functions need friends to be cached first
    caching = Future.wait([
      cachePfpVersions(),
      cacheTimetables(),
      cacheNames(),
    ]);
    await caching;
  }

  String getPfpUrl(String userId, {bool isPreview = false}) {
    String urlPath = "/view";
    const int previewSize = MyRunshawConfig.previewImageResolution;

    if (isPreview) {
      // Used to save data when rendering in small widgets, as used on the home page
      urlPath = "/preview?";
    }
    if (cachedPfpVersions.containsKey(userId)) {
      return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId$urlPath?project=${MyRunshawConfig.projectId}&version=${cachedPfpVersions[userId]}&width=$previewSize&height=$previewSize";
    }
    return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId$urlPath?project=${MyRunshawConfig.projectId}&version=0";
  }

  Future<void> incrementPfpVersion() async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/cache/update/pfp-version'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    if (response.statusCode != 200) {
      throw "Error incrementing pfp version";
    }
    await cachePfpVersions();
    await Aptabase.instance.trackEvent(
      "updated-pfp",
    );
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSessions();
      _jwt = null;
      _status = AccountStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  String humanResponse(String body) {
    final jsonBody = jsonDecode(body);
    if (jsonBody["error"] != null) {
      return jsonBody["error"];
    } else if (jsonBody["message"] != null) {
      return jsonBody["message"];
    } else {
      // Shouldn't happen
      return "Operation complete";
    }
  }

  Future<void> syncTimetable(timetable) async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'timetable': timetable}),
    );
    if (response.statusCode != 201) {
      throw "Error syncing timetable";
    }
    await Aptabase.instance.trackEvent(
      "synced-timetable",
    );
    return;
  }

  Future<void> associateTimetableUrl(String url) async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable/associate'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': url}),
    );
    if (response.statusCode != 201) {
      throw "Error associating timetable";
    }
    await Aptabase.instance.trackEvent(
      "associated-timetable",
    );
    return;
  }

  Future<void> refreshUser() async {
    _currentUser = await account!.get();
  }

  Future<List<Event>> fetchEvents(
      {String? userId,
      bool includeAll = false,
      bool allowCache = false}) async {
    userId ??= user!.$id;

    List<Event> timetable = [];
    String query = "";
    if (userId != user!.$id) {
      query = "?user_id=$userId";
    }

    Map events;

    if (!cachedTimetables.containsKey(userId) || !allowCache) {
      debugLog("Fetching timetable for $userId");
      final String jwtToken = await getJwt();

      final response = await http.get(
        Uri.parse(
            '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable$query'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }
      events = jsonDecode(response.body)["timetable"];
    } else {
      if (cachedTimetables[userId].runtimeType == String) {
        // Legacy API support; not sure why this happend but sometimes the timetable is a string and sometimes it's a map :/
        events = jsonDecode(cachedTimetables[userId]);
      } else {
        events = cachedTimetables[userId];
      }
    }

    for (final event in events["data"]) {
      final String start = event["dtstart"]["dt"];
      final String end = event["dtend"]["dt"];

      final DateTime startDateTime = DateTime.parse(start);
      final DateTime endDateTime = DateTime.parse(end);

      final startOfToday = DateTime.now().subtract(
        Duration(
          hours: DateTime.now().hour,
          minutes: DateTime.now().minute,
          seconds: DateTime.now().second,
        ),
      );

      if (!includeAll) {
        if (startDateTime.isBefore(startOfToday) &&
            endDateTime.isBefore(startOfToday)) {
          // Skip past events that have already happened!
          // Starting at the beginning of the day prevents aspire weirdness
          continue;
        }
      }
      timetable.add(Event(
        summary: event['summary'],
        location: event['location'],
        start: startDateTime,
        end: endDateTime,
        description: event["description"],
        uid: event["uid"],
      ));
    }
    return timetable;
  }

  Future<String> sendFriendRequest(String userId) async {
    final String jwtToken = await getJwt();

    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiver_id': userId}),
    );
    await cacheFriends();
    return humanResponse(response.body);
  }

  Future<void> blockUser(String userId) async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/block'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'blocked_id': userId}),
    );
    if (response.statusCode != 201) {
      throw "Error blocking user";
    }
    await cacheFriends();
    return;
  }

  Future<bool> respondToFriendRequest(
      String userId, bool accept, int id) async {
    final String jwtToken = await getJwt();
    final response = await http.put(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests/${id.toString()}'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': accept ? 'accept' : 'decline',
      }),
    );
    await cacheFriends();
    return response.statusCode == 200;
  }

  Future<List> getFriends({bool force = false}) async {
    if (cachedFriends != null && !force) {
      return Future.value(cachedFriends);
    }

    final String jwtToken = await getJwt();
    List<Map> friends = [];

    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/friends'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    for (final friend in jsonDecode(response.body)) {
      if (friend["receiver_id"] == user!.$id) {
        friends.add({
          "userid": friend["sender_id"],
          "status": friend["status"],
          "id": friend["id"],
          "created_at": friend["created_at"],
          "updated_at": friend["updated_at"],
        });
      } else {
        friends.add(
          {
            "userid": friend["receiver_id"],
            "status": friend["status"],
            "id": friend["id"],
            "created_at": friend["created_at"],
            "updated_at": friend["updated_at"],
          },
        );
      }
    }
    return friends;
  }

  Future<List> getFriendRequests() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests?status=pending'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    return jsonDecode(response.body);
  }

  Future<String> getName(String userId) async {
    // LEGACY:
    // final Functions functions = Functions(client);
    // final Execution execution = await functions.createExecution(
    //   functionId: "getname",
    //   path: "/user/name/get?id=$userId",
    // );
    // final String response = execution.responseBody;
    // return jsonDecode(response)["name"];
    if (cachedNames.containsKey(userId)) {
      return cachedNames[userId].toString();
    }
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/name/get/$userId'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    return jsonDecode(response.body)["name"];
  }

  Future<void> setBusNumber(String? number) async {
    // LEGACY CODE, should not be run
    // Preferences currentPrefs = await account!.getPrefs();
    // await OneSignal.User.addTagWithKey("bus", number);

    // if (currentPrefs.data["bus_number"] == number) {
    //   return;
    // }
    // currentPrefs.data["bus_number"] = number;
    // await account!.updatePrefs(prefs: currentPrefs.data);
  }

  Future<void> migrateBuses() async {
    // LEGACY: since it's been 6 months, it's safe to assume migration has happened or the user was inactive
    // for long enough that their account was deleted in compliance with GDPR

    // This is a one-time migration to remove the bus_number key from the prefs, and move to the new approach
    // which is to use the extra_buses endpoint and OneSignal's external IDs
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    bool migrated = prefs.getBool("migrated_buses") ?? false;
    debugLog("Has migrated buses: $migrated");
    if (migrated && !kDebugMode) {
      return;
    }

    try {
      // Primary bus was stored in Appwrite preferences
      Preferences currentPrefs = await account!.getPrefs();

      // Remove the bus tag from OneSignal
      await OneSignal.User.removeTag("bus");

      // Check if bus_number exists and is not null before adding it as an extra bus
      String? busNumber = currentPrefs.data["bus_number"];
      debugLog("Migrating bus number: $busNumber");
      if (busNumber != null && busNumber.isNotEmpty) {
        await addExtraBus(busNumber);
        debugLog("Added bus number as extra bus");
      }

      // Remove the bus number from the prefs if it exists
      currentPrefs.data.remove("bus_number");
      debugLog("Removed bus number from prefs");

      // Update the prefs
      await account!.updatePrefs(prefs: currentPrefs.data);
      debugLog("Updated prefs");

      // Set the migration flag
      await prefs.setBool("migrated_buses", true);
      await Aptabase.instance.trackEvent(
        "migrated-buses",
      );
    } catch (e) {
      debugLog("Error migrating buses: $e");
      await Aptabase.instance.trackEvent("migrate-buses-error", {
        "error": e.toString(),
      });
    }
  }

  Future<String?> getBusNumber() async {
    Preferences currentPrefs = await account!.getPrefs();
    return currentPrefs.data["bus_number"];
  }

  Future<String> getBusBay(String busNumber) async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/bus'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);

    for (var bus in body) {
      if (bus["bus_id"] == busNumber) {
        if (bus["bus_bay"].toString() == "0") {
          return "RSP_NYA"; // Reponse: not yet arrived
        }
        return bus["bus_bay"];
      }
    }
    return "RSP_UNK"; // Response: unknown (no idea where the bus is!)
  }

  Future<Map<String, String?>> getBusBays() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/bus'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    Map<String, String?> bays = {};
    for (var bus in body) {
      bays[bus["bus_id"]] = bus["bus_bay"];
    }
    return bays;
  }

  Future<String?> getBusFor(String userId) async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/bus/for?user_id=$userId'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    return body;
  }

  Future<bool> shouldSendNotification() async {
    Preferences currentPrefs = await account!.getPrefs();
    return currentPrefs.data["send_notifications"];
  }

  Future<void> onboardComplete() async {
    Preferences currentPrefs = await account!.getPrefs();
    currentPrefs.data["onboarding_complete"] = true;
    await account!.updatePrefs(prefs: currentPrefs.data);
    await Aptabase.instance.trackEvent(
      "onboarding-complete",
    );
  }

  Future<void> closeAccount() async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/account/close'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );

    final body = jsonDecode(response.body);

    if (body["error"] != null) {
      throw body["error"];
    }
    if (response.statusCode != 200) {
      throw "Error closing account";
    }
    await Aptabase.instance.trackEvent(
      "close-account",
    );
  }

  Future<String> resetPasswordWithoutAuth(
      String studentId, String code, String newPassword) async {
    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.passwordResetMicroserviceUrl}/api/reset_password?user_id=$studentId&code=$code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'new_password': newPassword}),
    );
    await Aptabase.instance.trackEvent(
      "reset-password",
    );
    return jsonDecode(response.body)["message"];
  }

  Future<bool> userExists(String userId) async {
    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/exists/$userId'),
    );
    return jsonDecode(response.body)["exists"];
  }

  Future<List<String>> getAllBuses() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/get'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    final body = jsonDecode(response.body);
    List<String> buses = [];
    for (var bus in body) {
      buses.add(bus["bus"]);
    }
    return buses;
  }

  Future<void> addExtraBus(String busId) async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/add'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bus_number': busId}),
    );
    if (response.statusCode != 201) {
      throw "Error adding extra bus";
    }
  }

  Future<void> removeExtraBus(String busId) async {
    final String jwtToken = await getJwt();
    final response = await http.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/extra_buses/remove'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'bus_number': busId}),
    );
    if (response.statusCode != 201) {
      throw "Error removing extra bus";
    }
  }

  Future<String?> getRunshawPayBalance() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/balance'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      return null;
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["balance"];
    }
  }

  Future<List<Transaction>> getRunshawPayTransactions() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/transactions'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw RunshawPayException(jsonDecode(response.body)["detail"]);
    } else {
      List<Transaction> toReturn = [];
      final List allTransactions = jsonDecode(utf8.decode(response.bodyBytes));

      for (final transaction in allTransactions) {
        toReturn.add(
          Transaction(
            transaction["date"],
            transaction["details"],
            transaction["action"],
            transaction["amount"],
            transaction["balance"],
          ),
        );
      }

      return toReturn;
    }
  }

  Future<String> getRunshawPayTopupUrl() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/deeplink'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw RunshawPayException(jsonDecode(response.body)["detail"]);
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["deeplink"];
    }
  }

  Future<bool> isAdmin() async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/admin/is_admin'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      return false;
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes))["is_admin"];
    }
  }

  Future<Map> getUserInfoTechnician(String userID) async {
    final String jwtToken = await getJwt();
    final response = await http.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/admin/user/$userID'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode != 200) {
      throw "Error fetching user info";
    } else {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
  }

  User? get user => _currentUser;
  Account? get account => _account;
}
