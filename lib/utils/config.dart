import 'package:runshaw/utils/logging.dart';

class MyRunshawConfig {
  static String _getEnv() =>
      const String.fromEnvironment('env', defaultValue: 'prod');

  static bool get _isDev => _getEnv() == 'dev';
  static bool get _isLocalDev => _getEnv() == 'localdev';

  static String get endpoint {
    final host = (_isLocalDev || _isDev)
        ? 'dev-appwrite.danieldb.uk'
        : 'appwrite.danieldb.uk';
    return 'https://$host/v1';
  }

  static String get endpointHostname {
    return (_isLocalDev || _isDev)
        ? 'dev-appwrite.danieldb.uk'
        : 'appwrite.danieldb.uk';
  }

  static const String projectId = "66fdb56000209ea9ac18";
  static const String profileBucketId = "profiles";

  static const String inAppDbId = "inapp";
  static const String noticesCollectionId = "notices";

  static const String featureFlagsDbId = "feature-flags";
  static const String featureFlagsCollectionId = "feature-flags";

  // static const String aptabaseProjectId = "A-SH-5552019394";
  // static const String aptabaseHost = "https://analytics.danieldb.uk";
  static const String posthogApiKey =
      "phc_FDCLEAW9y4wNcOZzze88JJPz9fPHt7PKBjTyrlZQALO";

  static const String oneSignalAppId =
      "001b2238-9af7-49f1-bd60-6dfe630b7175"; //"72211047-33fc-4036-96d8-100c4a7bf85a";

  static String get friendsMicroserviceUrl {
    if (_isLocalDev) {
      return 'http://localhost:5006';
    }

    return (_isLocalDev || _isDev)
        ? 'https://dev-runshaw-api.danieldb.uk'
        : 'https://runshaw-api.danieldb.uk';
  }

  static void logApiUrlsOnStartup() {
    debugLog('Config environment: ${_getEnv()}', level: 1);
    debugLog('Appwrite endpoint: $endpoint', level: 1);
    debugLog('Appwrite hostname: $endpointHostname', level: 1);
    debugLog('Friends microservice URL: $friendsMicroserviceUrl', level: 1);
  }

  static const String emailExtension = "@student.runshaw.ac.uk";

  static const busNumbers = [
    '102',
    '103',
    '115',
    '117',
    '119',
    '125',
    '566',
    '712',
    '715',
    '718',
    '720',
    '760',
    '761',
    '762',
    '763',
    '764',
    '765',
    '778',
    '800',
    '801',
    '803',
    '807',
    '809',
    '819',
    '820',
    '821',
    '822',
    '823',
    '824',
    '825',
    '826',
    '827',
    '953',
    '954',
    '956',
    '957',
    '958',
    '959',
    '959B',
    '961',
    '962',
    '963',
    '964',
    '965',
    '966',
    '975',
    '982',
    '983',
    '998'
  ];

  static const tutorialVideoUrl =
      "https://appwrite.danieldb.uk/v1/storage/buckets/cdn/files/intro/view?project=66fdb56000209ea9ac18";

  static const previewImageResolution =
      128; // px, used for profile picture previews
}
