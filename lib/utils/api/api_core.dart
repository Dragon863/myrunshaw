import 'dart:convert';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:runshaw/utils/http/http_client_factory.dart'
    if (dart.library.js_interop) 'package:runshaw/utils/http/http_client_factory_web.dart'
    as http_factory;

import 'package:runshaw/utils/logging.dart';

enum AccountStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

abstract class ApiCore extends ChangeNotifier {
  late User currentUser;
  AccountStatus status = AccountStatus.uninitialized;

  final Client client = Client();
  final http.Client httpClient = http_factory.httpClient();

  String? jwt;
  late Account account;

  Map cachedTimetables = {};
  Map cachedPfpVersions = {};
  Map cachedNames = {};
  List? cachedFriends;
  Future<void>? caching;

  String? get email => currentUser.email;
  String? get userid => currentUser.$id;
  User? get user => currentUser;

  String _getJsonFromJWT(String splitToken) {
    String normalizedSource = base64Url.normalize(splitToken);
    return utf8.decode(base64Url.decode(normalizedSource));
  }

  Future<String> getJwt() async {
    // As of v1.2.5, this is the preferred way to get a JWT for API requests as it prevents unnecessary API calls
    // to get a new JWT if the current one is still valid.
    if (jwt == null) {
      // Normal on first API call after cold start
      jwt = await account.createJWT().then((Jwt j) => j.jwt);
      debugLog("JWT is null, creating new one");
      debugLog("New JWT: $jwt");
      return jwt!;
    }
    // Split the JWT into its three parts - header, payload, signature
    final String splitToken = jwt!.split(".")[1]; // Payload

    final maybeValidJwt = _getJsonFromJWT(splitToken);

    if ((jsonDecode(maybeValidJwt)["exp"] * 1000) <
        DateTime.now().millisecondsSinceEpoch) {
      // Appwrite uses seconds, not milliseconds, since epoch

      // JWT is expired
      debugLog("JWT is expired, creating new one");
      debugLog(
          "Original expired at ${jsonDecode(maybeValidJwt)["exp"] * 1000}, now is ${DateTime.now().millisecondsSinceEpoch}");
      jwt = await account.createJWT().then((Jwt j) => j.jwt);
      debugLog("New JWT: $jwt");
      return jwt!;
    } else {
      // JWT is still valid
      debugLog("JWT is still valid");
      return jwt!;
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
}
