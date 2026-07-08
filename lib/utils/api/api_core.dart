import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/http/http_client_factory.dart'
    if (dart.library.js_interop) 'package:runshaw/utils/http/http_client_factory_web.dart'
    as http_factory;
import 'package:runshaw/utils/logging.dart';

import 'package:runshaw/utils/models/current_user.dart';

enum AccountStatus { uninitialized, unauthenticated, authenticated }

abstract class ApiCore extends ChangeNotifier {
  CurrentUser? currentUser;
  AccountStatus status = AccountStatus.uninitialized;
  String? jwt;

  final http.Client httpClient = http_factory.httpClient();

  // These caches will be largely populated by the /api/sync endpoint in the future.
  // Kept here so the rest of your app doesn't break during the transition.
  Map cachedTimetables = {};
  Future<void>? timetableCacheInFlight;
  Map cachedPfpVersions = {};
  Map cachedNames = {};
  List? cachedFriends;
  Future<void>? caching;

  String? get email => currentUser?.email;
  String? get userid => currentUser?.id;
  CurrentUser? get user => currentUser;

  /// automatically attach the JWT Bearer token and JSON headers to every request
  Future<Map<String, String>> _getHeaders() async {
    if (jwt == null) {
      final prefs = await SharedPreferences.getInstance();
      jwt = prefs.getString('jwt_token');
    }
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (jwt != null) 'Authorization': 'Bearer $jwt',
    };
  }

  /// Base GET Request
  Future<http.Response> apiGet(String endpoint) async {
    final headers = await _getHeaders();
    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.apiUrl}$endpoint'),
      headers: headers,
    );
    _handleUnauthorized(response);
    return response;
  }

  /// Base POST Request
  Future<http.Response> apiPost(String endpoint,
      {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.apiUrl}$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _handleUnauthorized(response);
    return response;
  }

  /// Base PUT Request
  Future<http.Response> apiPut(String endpoint,
      {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    final response = await httpClient.put(
      Uri.parse('${MyRunshawConfig.apiUrl}$endpoint'),
      headers: headers,
      body: body != null ? jsonEncode(body) : null,
    );
    _handleUnauthorized(response);
    return response;
  }

  /// Base DELETE Request
  Future<http.Response> apiDelete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await httpClient.delete(
      Uri.parse('${MyRunshawConfig.apiUrl}$endpoint'),
      headers: headers,
    );
    _handleUnauthorized(response);
    return response;
  }

  /// Special Multipart Request for /api/users/me/profile-pic
  Future<http.StreamedResponse> apiMultipart(
      String endpoint, String filePath) async {
    final headers = await _getHeaders();
    var request = http.MultipartRequest(
        'POST', Uri.parse('${MyRunshawConfig.apiUrl}$endpoint'));

    // MultipartRequest doesn't allow setting Content-Type. skip it.
    headers.forEach((key, value) {
      if (key.toLowerCase() != 'content-type') {
        request.headers[key] = value;
      }
    });

    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await httpClient.send(request);
    if (response.statusCode == 401) {
      _forceLogout();
    }
    return response;
  }

  void _handleUnauthorized(http.Response response) {
    if (response.statusCode == 401) {
      debugLog("401 Unauthorized detected. Forcing logout.");
      _forceLogout();
    }
  }

  Future<void> _forceLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    jwt = null;
    currentUser = null;
    status = AccountStatus.unauthenticated;
    notifyListeners();
  }

  /// helper to parse standard error formats from the backend
  String humanResponse(String body) {
    try {
      final jsonBody = jsonDecode(body);
      if (jsonBody["error"] != null) {
        return jsonBody["error"];
      } else if (jsonBody["detail"] != null) {
        return jsonBody["detail"];
      }
    } catch (e) {
      // not JSON, or empty response
    }
    return "An error occurred";
  }
}
