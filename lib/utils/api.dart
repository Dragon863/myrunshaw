import 'package:flutter/widgets.dart';
import 'package:appwrite/appwrite.dart';

enum AccountStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  late User _currentUser;
  AccountStatus _status = AccountStatus.uninitialized;

  Client _client = Client();
  late Account _account;

  User get currentUser => _currentUser;
  AccountStatus get status => _status;
  String? get email => _currentUser.email;
  String? get userid => _currentUser.$id;

  AuthAPI() {
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
      final session = await _account.get();
      _currentUser = User(
        $id: session.$id,
        email: session.email,
      );
      _status = AccountStatus.authenticated;
    } catch (e) {
      _status = AccountStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<User?> createUser(
      {required String email, required String password}) async {
    final user = await _account.create(
      userId: ID.unique(),
      email: email,
      password: password,
    );
    _currentUser = User(
      $id: user.$id,
      email: user.email,
    );
    _status = AccountStatus.authenticated;
    notifyListeners();
    return _currentUser;
  }

  Future<void> createEmailSession(
      {required String email, required String password}) async {
    final session = await _account.createEmailPasswordSession(
      email: email,
      password: password,
    );
    _currentUser = User(
      $id: session.userId,
      email: email,
    );
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
}

class User {
  final String $id;
  final String email;

  User({required this.$id, required this.email});
}
