import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/config.dart';

import 'api_core.dart';
import 'api_friends.dart';
import 'api_timetable.dart';
import 'package:runshaw/utils/models/current_user.dart';

mixin ApiAuth on ApiCore, ApiFriends, ApiTimetable {
  final String _tenantId = MyRunshawConfig.entraTenantId;
  final String _clientId = MyRunshawConfig.entraClientId;
  final String _callbackUrlScheme = MyRunshawConfig.oauthCallbackScheme;

  Future<void> loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      jwt = prefs.getString('jwt_token');

      if (jwt == null) {
        status = AccountStatus.unauthenticated;
        notifyListeners();
        return;
      }

      if (_isJwtExpired(jwt!)) {
        bool refreshed = await _silentRefresh();
        if (!refreshed) {
          throw Exception("Session expired and could not be refreshed");
        }
      }

      var response = await apiGet('/api/sync');

      if (response.statusCode == 401) {
        bool refreshed = await _silentRefresh();
        if (!refreshed) throw Exception("Session expired");
        response = await apiGet('/api/sync');
      }

      if (response.statusCode != 200) {
        throw Exception("Invalid token or backend error");
      }

      final data = jsonDecode(response.body);

      currentUser = CurrentUser.fromJson(data['me']);
      status = AccountStatus.authenticated;

      cachedNames = {};
      cachedPfpVersions = {};

      cachedNames[currentUser!.id] = currentUser!.name;
      cachedPfpVersions[currentUser!.id] = currentUser!.profilePicVersion;

      final List friendsList = data['friends'] ?? [];
      cachedFriends = friendsList.map((f) {
        final String fId = f["studentId"] ?? "";
        cachedNames[fId] = f["name"] ?? "";
        cachedPfpVersions[fId] = f["profilePicVersion"] ?? 0;

        return {
          "userid": fId,
          "status": "accepted",
        };
      }).toList();

      cachedTimetables = data['timetables'] ?? {};

      if (!kIsWeb && !Platform.isLinux && currentUser != null) {
        OneSignal.login(currentUser!.id);
        await Posthog().identify(userId: currentUser!.$id, userProperties: {
          "name": currentUser!.name,
          "email": currentUser!.email,
          "student_id": currentUser!.id,
        }, userPropertiesSetOnce: {
          "date_of_first_log_in": DateTime.now().toIso8601String(),
        });
        await Posthog().reloadFeatureFlags();
      }
    } catch (e, stackTrace) {
      debugLog("Error in loadUser: $e");
      debugLog("StackTrace: $stackTrace");
      jwt = null;
      status = AccountStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> loginWithMicrosoft() async {
    // now uses PKCE for security, and requests offline_access for refresh tokens
    try {
      final verifier = _generateCodeVerifier();
      final challenge = _generateCodeChallenge(verifier);

      final authUrl =
          'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/authorize'
          '?client_id=$_clientId'
          '&response_type=code'
          '&scope=openid%20profile%20email%20offline_access'
          '&redirect_uri=$_callbackUrlScheme://callback'
          '&code_challenge_method=S256'
          '&code_challenge=$challenge'
          '&prompt=select_account';

      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: _callbackUrlScheme,
      );

      final queryParams = Uri.parse(resultUrl).queryParameters;
      final code = queryParams['code'];

      if (code == null) {
        throw 'Authentication failed: No authorization code received.';
      }

      // exchange the code for an ID token and refresh token
      final tokenResponse = await httpClient.post(
        Uri.parse(
            'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': '$_callbackUrlScheme://callback',
          'code_verifier': verifier,
        },
      );

      if (tokenResponse.statusCode != 200) {
        throw 'Failed to exchange Microsoft code: ${tokenResponse.body}';
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final idToken = tokenData['id_token'];
      final refreshToken = tokenData['refresh_token'];

      // backend can now issue a custom JWT
      final response = await httpClient.post(
        Uri.parse('${MyRunshawConfig.apiUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'providerToken': idToken}),
      );

      if (response.statusCode != 200) {
        throw 'Failed to exchange Microsoft token for custom JWT: ${response.body}';
      }

      final customJwt = jsonDecode(response.body)['token'];

      // save it securely
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', customJwt);
      if (refreshToken != null) {
        await prefs.setString('ms_refresh_token', refreshToken);
      }

      jwt = customJwt;
      await afterLogin();
    } catch (e) {
      if (e.toString().contains('CANCELED')) throw 'Login cancelled';
      rethrow;
    }
  }

  Future<bool> _silentRefresh() async {
    debugLog('Attempting silent refresh...');
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('ms_refresh_token');

      if (refreshToken == null) return false;

      // request a new ID token from microsoft using the refresh token
      final tokenResponse = await httpClient.post(
        Uri.parse(
            'https://login.microsoftonline.com/$_tenantId/oauth2/v2.0/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'client_id': _clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': 'openid profile email offline_access',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = jsonDecode(tokenResponse.body);
        final newIdToken = tokenData['id_token'];
        final newRefreshToken = tokenData['refresh_token'];

        // exchange with backend for a new custom JWT
        final apiRes = await httpClient.post(
          Uri.parse('${MyRunshawConfig.apiUrl}/api/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'providerToken': newIdToken}),
        );

        if (apiRes.statusCode == 200) {
          // save the refreshed JWT and refresh token
          jwt = jsonDecode(apiRes.body)['token'];
          await prefs.setString('jwt_token', jwt!);
          if (newRefreshToken != null) {
            await prefs.setString('ms_refresh_token', newRefreshToken);
          }
          return true; // success!
        }
      }
    } catch (e) {
      // :(
      debugLog('Silent refresh failed: $e');
    }
    return false;
  }

  bool _isJwtExpired(String token) {
    try {
      final payloadStr = utf8
          .decode(base64Url.decode(base64Url.normalize(token.split(".")[1])));
      final payload = jsonDecode(payloadStr);
      final exp = payload["exp"] * 1000;
      // better to refresh a bit early as a precaution (5 minutes before expiry)
      return DateTime.now().millisecondsSinceEpoch > (exp - 300000);
    } catch (e) {
      return true; // it's probabl ybroken/expired if we can't decode it
    }
  }

  String _generateCodeVerifier() {
    final random = math.Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64UrlEncode(values).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = crypto.sha256.convert(bytes);
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  Future<void> afterLogin() async {
    await loadUser();
    if (status == AccountStatus.authenticated) {
      notifyListeners();
    }
  }

  Future<void> signOut({bool notify = true}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwt_token');
      jwt = null;
      currentUser = null;
      status = AccountStatus.unauthenticated;

      if (!kIsWeb && !Platform.isLinux) {
        OneSignal.logout();
        await Posthog().reset();
      }
    } finally {
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> refreshUser() async {
    await loadUser();
  }

  Future<bool> shouldSendNotification() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool("send_notifications") ?? true;
  }

  Future<void> onboardComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("onboarding_complete", true);
    await Posthog().capture(eventName: 'onboard_complete');
  }

  Future<void> loginWithBypassSecret(String secret) async {
    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.apiUrl}/api/auth/demo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'secret': secret}),
    );

    if (response.statusCode == 200) {
      final customJwt = jsonDecode(response.body)['token'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', customJwt);
      jwt = customJwt;

      await afterLogin();
    } else {
      throw Exception("Bypass login failed: ${response.body}");
    }
  }

  Future<void> closeAccount() async {
    if (jwt == null) throw "Not authenticated";

    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.apiUrl}/api/auth/close_account'),
      headers: {
        'Authorization': 'Bearer $jwt',
      },
    );

    if (response.statusCode != 200) {
      throw "Error closing account: ${response.body}";
    }

    await Posthog().capture(eventName: 'account_closed');
    await signOut();
  }

  Future<String> getCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("code") ?? "000000";
  }

  Future<void> setCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("code", code);
  }

  Future<List<Map<String, dynamic>>> getInAppNotices() async {
    final response = await apiGet('/api/notices');
    if (response.statusCode != 200) {
      throw "Error fetching in-app notices: ${response.body}";
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }
}
