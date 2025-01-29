import 'package:flutter/foundation.dart';

void debugLog(String message, {int level = 0}) {
  // level 0: debug, 1: info, 2: warning, 3: error
  if (kDebugMode) {
    switch (level) {
      case 0:
        debugPrint('DEBUG: $message');
        break;
      case 1:
        debugPrint('INFO: $message');
        break;
      case 2:
        debugPrint('WARNING: $message');
        break;
      case 3:
        debugPrint('ERROR: $message');
        break;
      default:
        debugPrint('DEBUG: $message');
    }
  }
}
