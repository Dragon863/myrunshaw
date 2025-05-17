import 'package:flutter/foundation.dart';

void debugLog(String message, {int level = 0}) {
  // level 0: debug, 1: info, 2: warning, 3: error
  if (kDebugMode) {
    // get the current time
    final now = DateTime.now();
    final formattedTime =
        '${now.hour}:${now.minute}:${now.second}:${now.millisecond}';
    switch (level) {
      case 0:
        debugPrint('$formattedTime DEBUG: $message');
        break;
      case 1:
        debugPrint('$formattedTime INFO: $message');
        break;
      case 2:
        debugPrint('$formattedTime WARNING: $message');
        break;
      case 3:
        debugPrint('$formattedTime ERROR: $message');
        break;
      default:
        debugPrint('$formattedTime DEBUG: $message');
    }
  }
}
