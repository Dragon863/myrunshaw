import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:http/http.dart' as http;
import 'package:runshaw/utils/config.dart';

enum AccountStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class BaseAPI extends ChangeNotifier {
  late User _currentUser;
  AccountStatus _status = AccountStatus.uninitialized;

  final Client _client = Client();
  late Account _account;

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
    _client.setEndpoint(Config.endpoint).setProject(Config.projectId);
    _account = Account(_client);
  }

  loadUser() async {
    try {
      final User user = await _account.get();
      _currentUser = user;
      _account = Account(_client);
      _status = AccountStatus.authenticated;
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.login(_currentUser.$id);
    } catch (e) {
      _status = AccountStatus.unauthenticated;
    }
    notifyListeners();
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
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSessions();
      _status = AccountStatus.unauthenticated;
    } catch (e) {
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
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.post(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/timetable'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'timetable': timetable}),
    );
    if (response.statusCode == 200) {
      throw "Error syncing timetable";
    }
    return;
  }

  Future<List<Event>> fetchEvents({String? userId}) async {
    userId ??= user!.$id;

    List<Event> timetable = [];
    String query = "";
    if (userId != user!.$id) {
      query = "?user_id=$userId";
    }
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.get(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/timetable$query'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
      },
    );

    if (response.statusCode != 200) {
      return [];
    }

    //final events = jsonDecode(myDocument!.data["data"]);
    final events = jsonDecode(response.body);

    for (final event in events["timetable"]["data"]) {
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
      if (startDateTime.isBefore(startOfToday) &&
          endDateTime.isBefore(startOfToday)) {
        // Skip past events that have already happened!
        // Starting at the beginning of the day prevents aspire weirdness
        continue;
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
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.post(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/friend-requests'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiver_id': userId}),
    );
    return humanResponse(response.body);
  }

  Future<void> blockUser(String userId) async {
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.post(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/block'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
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
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.put(
      Uri.parse(
          '${Config.friendsMicroserviceUrl}/api/friend-requests/${id.toString()}'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': accept ? 'accept' : 'decline',
      }),
    );
    return response.statusCode == 200;
  }

  Future<List> getFriends() async {
    final Jwt jwtToken = await account!.createJWT();
    List<Map> friends = [];

    final response = await http.get(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/friends'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
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
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.get(
      Uri.parse(
          '${Config.friendsMicroserviceUrl}/api/friend-requests?status=pending'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
      },
    );
    return jsonDecode(response.body);
  }

  Future<String> getName(String userId) async {
    final Functions functions = Functions(client);
    final Execution execution = await functions.createExecution(
      functionId: "getname",
      path: "/user/name/get?id=$userId",
    );
    final String response = await execution.responseBody;
    return jsonDecode(response)["name"];
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
    final Jwt jwtToken = await account!.createJWT();
    final response = await http.get(
      Uri.parse('${Config.friendsMicroserviceUrl}/api/bus'),
      headers: {
        'Authorization': 'Bearer ${jwtToken.jwt}',
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

  Future<bool> shouldSendNotification() async {
    Preferences currentPrefs = await account!.getPrefs();
    return currentPrefs.data["send_notifications"];
  }

  Future<void> onboardComplete() async {
    Preferences currentPrefs = await account!.getPrefs();
    currentPrefs.data["onboarding_complete"] = true;
    await account!.updatePrefs(prefs: currentPrefs.data);
  }

  User? get user => _currentUser;
  Account? get account => _account;
}
