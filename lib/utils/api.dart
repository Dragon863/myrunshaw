import 'dart:convert';

import 'package:appwrite/models.dart';
import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';

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
    _client
        .setEndpoint('https://appwrite.danieldb.uk/v1')
        .setProject('66fdb56000209ea9ac18');
    _account = Account(_client);
  }

  loadUser() async {
    try {
      final User user = await _account.get();
      _currentUser = user;
      _account = Account(_client);
      _status = AccountStatus.authenticated;
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

    print(email);
    RegExp regExp = RegExp(r'-\d{6}');
    if (regExp.hasMatch(email)) {
      print("Matched");
      final String code =
          regExp.firstMatch(email)!.group(0)!.replaceAll("-", "");
      print(code);
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
    _status = AccountStatus.authenticated;
  }

  Future<void> signOut() async {
    try {
      await _account.deleteSessions();
      _status = AccountStatus.unauthenticated;
    } catch (e) {
      print("Error signing out: $e");
    } finally {
      notifyListeners();
    }
  }

  Future<void> syncTimetable(timetable) async {
    final Databases databases = Databases(_client);

    final DocumentList currentState = await databases.listDocuments(
      databaseId: 'timetable',
      collectionId: '671fe051003b06c2a5f7',
    );

    for (final Document document in currentState.documents) {
      if (document.$id == user!.$id) {
        await databases.updateDocument(
          databaseId: 'timetable',
          collectionId: '671fe051003b06c2a5f7',
          documentId: user!.$id,
          data: {
            "data": timetable.toString(),
          },
        );
        print("Updated timetable");
        return;
      }
    }

    await databases.createDocument(
      databaseId: 'timetable',
      collectionId: '671fe051003b06c2a5f7',
      documentId: user!.$id,
      data: {"data": timetable.toString()},
      permissions: ['read("any")'],
    );
    print("Synced timetable");
  }

  Future<List<Event>> fetchEvents({String? userId}) async {
    userId ??= user!.$id;

    List<Event> timetable = [];
    bool hasSynced = false;
    Document? myDocument;

    final Databases databases = Databases(_client);
    final DocumentList documents = await databases.listDocuments(
      databaseId: 'timetable',
      collectionId: '671fe051003b06c2a5f7',
    );

    for (final document in documents.documents) {
      if (document.$id == userId) {
        hasSynced = true;
        myDocument = document;
        break;
      }
    }

    if (!hasSynced) {
      return [];
    }

    final events = jsonDecode(myDocument!.data["data"]);

    for (final event in events["data"]) {
      final String start = event["dtstart"]["dt"];
      final String end = event["dtend"]["dt"];

      final DateTime startDateTime = DateTime.parse(start);
      final DateTime endDateTime = DateTime.parse(end);

      if (startDateTime.isBefore(DateTime.now()) &&
          endDateTime.isBefore(DateTime.now())) {
        // Skip past events that have already happened!
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
    final Databases databases = Databases(client);
    //try {
    await databases.createDocument(
        databaseId: "friend_reqs",
        collectionId: "outgoing",
        documentId: "${user!.$id}-to-$userId",
        data: {
          "sent": DateTime.now().toIso8601String(),
        },
        permissions: [
          Permission.read(Role.any()),
          Permission.write(Role.user(userId)),
          Permission.update(Role.user(userId)),
          Permission.delete(Role.user(userId)),
        ]);
    return "Friend request sent!";
    /* } catch (e) {
      return "You've already sent a friend request to this user!";
    }*/
  }

  Future<bool> respondToFriendRequest(String userId, bool accept) async {
    final Databases databases = Databases(client);
    try {
      await databases.createDocument(
          databaseId: "friend_reqs",
          collectionId: "accepted",
          documentId: "${user!.$id}-to-$userId",
          data: {
            "value": accept,
          },
          permissions: [
            Permission.read(Role.any()),
            Permission.write(Role.user(userId)),
            Permission.update(Role.user(userId)),
            Permission.delete(Role.user(userId)),
          ]);
      return true;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<List<String>> getFriends() async {
    final Databases databases = Databases(client);
    final DocumentList documents = await databases.listDocuments(
      databaseId: "friend_reqs",
      collectionId: "accepted",
    );

    List<String> friends = [];

    for (final document in documents.documents) {
      if (document.$id.startsWith(user!.$id)) {
        final String friendId = document.$id.split("-").last;
        final bool accepted = document.data["value"];
        if (accepted) {
          friends.add(friendId);
        }
      }
    }

    return friends;
  }

  Future<List> getFriendRequests() async {
    final Databases databases = Databases(client);
    final DocumentList documents = await databases.listDocuments(
      databaseId: "friend_reqs",
      collectionId: "outgoing",
    );

    List<String> requests = [];

    for (final document in documents.documents) {
      if (document.$id.startsWith(user!.$id)) {
        final String friendId = document.$id.split("-").last;
        requests.add(friendId);
      }
    }

    return requests;
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

  User? get user => _currentUser;
  Account? get account => _account;
}
