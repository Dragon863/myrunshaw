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
      _status = AccountStatus.authenticated;
    } catch (e) {
      _status = AccountStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<User?> createUser(
      {required String email, required String password}) async {
    final userId = email.replaceAll("@student.runshaw.ac.uk", "").toLowerCase();
    final user = await _account.create(
      userId: userId,
      email: email,
      password: password,
    );
    _currentUser = user;
    _status = AccountStatus.authenticated;
    notifyListeners();
    return _currentUser;
  }

  Future<void> createEmailSession(
      {required String email, required String password}) async {
    //final Session session =
    await _account.createEmailPasswordSession(
      email: email,
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

  Future<List<Event>> fetchEvents() async {
    List<Event> timetable = [];
    bool hasSynced = false;
    Document? myDocument;

    final Databases databases = Databases(_client);
    final DocumentList documents = await databases.listDocuments(
      databaseId: 'timetable',
      collectionId: '671fe051003b06c2a5f7',
    );

    for (final document in documents.documents) {
      if (document.$id == user!.$id) {
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

  User? get user => _currentUser;
  Account? get account => _account;
}
