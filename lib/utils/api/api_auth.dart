import 'dart:convert';
import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/config.dart';
import 'api_core.dart';
import 'api_friends.dart';
import 'api_timetable.dart';

mixin ApiAuth on ApiCore, ApiFriends, ApiTimetable {
  Future<void> loadUser() async {
    try {
      final User user = await account.get();
      currentUser = user;
      account = Account(client);
      status = AccountStatus.authenticated;
      if (!kIsWeb) {
        if (!Platform.isLinux) {
          OneSignal.login(currentUser.$id);
          await Posthog().identify(userId: currentUser.$id, userProperties: {
            "name": currentUser.name,
            "email": currentUser.email,
            "student_id": currentUser.$id,
          }, userPropertiesSetOnce: {
            "date_of_first_log_in": DateTime.now().toIso8601String(),
          });
          await Posthog().reloadFeatureFlags();
        }
      }
    } catch (e) {
      status = AccountStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<User?> createUser(
      {required String email, required String password}) async {
    String userId = "";
    userId = email
        .replaceAll(MyRunshawConfig.emailExtension, "")
        .toLowerCase()
        .split("-")
        .first;

    final user = await account.create(
      userId: userId,
      email: "$userId${MyRunshawConfig.emailExtension}",
      password: password,
    );
    currentUser = user;
    status = AccountStatus.authenticated;
    await createEmailSession(email: email, password: password);
    notifyListeners();
    await loadUser();

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
    return currentUser;
  }

  Future<String> getCode() async {
    Preferences result = await account.getPrefs();
    return result.data["code"];
  }

  Future<void> setCode(String code) async {
    await account.updatePrefs(prefs: {"code": code});
  }

  Future<void> createEmailSession(
      {required String email, required String password}) async {
    if (email.contains("-")) {
      email =
          email.split("-").first.replaceAll(MyRunshawConfig.emailExtension, "");
    } else {
      email = email.replaceAll(MyRunshawConfig.emailExtension, "");
    }
    await account.createEmailPasswordSession(
      email: "$email${MyRunshawConfig.emailExtension}",
      password: password,
    );
    await afterLogin();
  }

  Future<void> createOAuth2Session({required OAuthProvider provider}) async {
    await account.createOAuth2Session(provider: provider);
    try {
      await afterLogin();
    } on AppwriteException catch (e) {
      if (e.code == 401) {
        throw 'Login cancelled';
      }
      rethrow;
    }
  }

  Future<void> afterLogin() async {
    currentUser = await Account(client).get();
    if (!kIsWeb) {
      if (!Platform.isLinux) {
        OneSignal.login(currentUser.$id);
      }
    }
    status = AccountStatus.authenticated;
    await cacheFriends(); // most other cache functions need friends to be cached first
    caching = Future.wait([
      cachePfpVersions(),
      cacheTimetables(),
      cacheNames(),
    ]);
    await caching;
    notifyListeners();
  }

  Future<void> signOut({bool notify = true}) async {
    try {
      await account.deleteSessions();
      jwt = null;
      status = AccountStatus.unauthenticated;
    } finally {
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> refreshUser() async {
    currentUser = await account.get();
    notifyListeners();
  }

  Future<bool> shouldSendNotification() async {
    Preferences currentPrefs = await account.getPrefs();
    return currentPrefs.data["send_notifications"];
  }

  Future<void> onboardComplete() async {
    Preferences currentPrefs = await account.getPrefs();
    currentPrefs.data["onboarding_complete"] = true;
    await account.updatePrefs(prefs: currentPrefs.data);
    await Posthog().capture(
      eventName: 'onboard_complete',
    );
  }

  Future<void> closeAccount() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
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
    await Posthog().capture(
      eventName: 'account_closed',
    );
  }

  Future<String> resetPasswordWithoutAuth(
      String studentId, String code, String newPassword) async {
    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.passwordResetMicroserviceUrl}/api/reset_password?user_id=$studentId&code=$code'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'new_password': newPassword}),
    );
    await Posthog().capture(
      eventName: 'password_reset_attempt',
    );
    return jsonDecode(response.body)["message"];
  }
}
