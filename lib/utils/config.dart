import 'package:flutter/material.dart';
import 'package:runshaw/utils/logging.dart';

class MyRunshawConfig {
  static String _getEnv() =>
      const String.fromEnvironment('env', defaultValue: 'prod');

  static bool get _isDev => _getEnv() == 'dev';
  static bool get _isLocalDev => _getEnv() == 'localdev';

  static const String posthogApiKey =
      "phc_FDCLEAW9y4wNcOZzze88JJPz9fPHt7PKBjTyrlZQALO";

  static const String oneSignalAppId = "001b2238-9af7-49f1-bd60-6dfe630b7175";

  static String get apiUrl {
    if (_isLocalDev) {
      return 'http://localhost:5267';
    }

    return (_isDev)
        ? 'https://myrunshaw-core-dev.danieldb.uk'
        : 'https://myrunshaw-core.danieldb.uk';
  }

  static void logApiUrlsOnStartup() {
    debugLog('Config environment: ${_getEnv()}', level: 1);
    debugLog('API Base URL: $apiUrl', level: 1);
  }

  static const String emailExtension = "@student.runshaw.ac.uk";

  static const tutorialVideoUrl = "https://s3.danieldb.uk/cdn/intro.mp4";

  static List<Color> get busBayColors => [
        Colors.red,
        Colors.orange,
        Colors.blue,
        Colors.purple,
        Colors.pink,
        Colors.teal,
        Colors.amber,
        Colors.cyan,
        Colors.lime,
      ];

  static const String entraTenantId = "4dcd8020-d84c-482f-bdf6-71d3ca953b8c";
  static const String entraClientId = "a259dcce-b2fb-4644-a4e5-d88b70554b86";
  static const String oauthCallbackScheme =
      "appwrite-callback-66fdb56000209ea9ac18";
}
