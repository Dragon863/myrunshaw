import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:http/http.dart' as http;
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';

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
  late Map cachedTimetables;
  late Map cachedPfpVersions;
  late Map cachedNames;

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
      OneSignal.login(_currentUser.$id);
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
      _jwt = await _account.createJWT().then((jwt) => jwt.jwt);
      debugLog("JWT is null, creating new one");
      debugLog("New JWT: $_jwt");
      return _jwt!;
    }
    // Split the JWT into its three parts - header, payload, signature
    final String splitToken = _jwt!.split(".")[1]; // Payload

    final maybeValidJwt = getJsonFromJWT(splitToken);

    if (jsonDecode(maybeValidJwt)["exp"] <
        DateTime.now().millisecondsSinceEpoch / 1000) {
      // Appwrite uses seconds, not milliseconds, since epoch

      // JWT is expired
      debugLog("JWT is expired, creating new one");
      debugLog(
          "Original expired at ${jsonDecode(maybeValidJwt)["exp"]}, now is ${DateTime.now().millisecondsSinceEpoch / 1000}");
      String _jwt = await _account.createJWT().then((Jwt jwt) => jwt.jwt);
      debugLog("New JWT: $_jwt");
      return _jwt;
    } else {
      // JWT is still valid
      return _jwt!;
    }
  }

  Future<User?> createUser(
      {required String email, required String password}) async {
    String userId = "";
    userId = email
        .replaceAll("@student.runshaw.ac.uk", "")
        .toLowerCase()
        .split("-")
        .first;

    loadUser();
    final user = await _account.create(
      userId: userId,
      email: "$userId@student.runshaw.ac.uk",
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

  Future<void> cachePfpVersions() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }

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

    print(jsonDecode(response.body));
    cachedNames = jsonDecode(response.body);
  }

  Future<void> createEmailSession(
      {required String email, required String password}) async {
    if (email.contains("-")) {
      email = email.split("-").first.replaceAll("@student.runshaw.ac.uk", "");
    } else {
      email = email.replaceAll("@student.runshaw.ac.uk", "");
    }
    await _account.createEmailPasswordSession(
      email: "$email@student.runshaw.ac.uk",
      password: password,
    );
    _currentUser = await Account(_client).get();
    OneSignal.login(_currentUser.$id);
    _status = AccountStatus.authenticated;
    await cachePfpVersions();
    await cacheTimetables();
    await cacheNames();
  }

  String getPfpUrl(String userId) {
    if (cachedPfpVersions.containsKey(userId)) {
      return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId/view?project=${MyRunshawConfig.projectId}&version=${cachedPfpVersions[userId]}";
    }
    return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId/view?project=${MyRunshawConfig.projectId}&version=0";
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
    return;
  }

  Future<void> refreshUser() async {
    _currentUser = await account!.get();
  }

  Future<List<Event>> fetchEvents({
    String? userId,
    bool includeAll = false,
  }) async {
    userId ??= user!.$id;

    List<Event> timetable = [];
    String query = "";
    if (userId != user!.$id) {
      query = "?user_id=$userId";
    }

    Map events;

    if (!cachedTimetables.containsKey(userId)) {
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
    return response.statusCode == 200;
  }

  Future<List> getFriends() async {
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
    Preferences currentPrefs = await account!.getPrefs();
    await OneSignal.User.addTagWithKey("bus", number);

    if (currentPrefs.data["bus_number"] == number) {
      return;
    }
    currentPrefs.data["bus_number"] = number;
    await account!.updatePrefs(prefs: currentPrefs.data);
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
    return jsonDecode(response.body)["message"];
  }

  Future<bool> userExists(String userId) async {
    final response = await http.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/exists/$userId'),
    );
    return jsonDecode(response.body)["exists"];
  }

  Future<List<String>> getExtraBuses() async {
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

  User? get user => _currentUser;
  Account? get account => _account;
}
