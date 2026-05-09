import 'package:flutter/foundation.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/logging.dart';

Future<bool> checkWifiSurveyEligibility() async {
  final info = NetworkInfo();
  final String? wifiName = await info.getWifiName();
  final String? normalizedWifiName = wifiName?.trim().replaceAll('"', '');
  // weird weird bug causes it to have " in the SSID. don't ask.

  debugLog("Checking Wi-Fi survey eligibility...");
  debugLog("Connected Wi-Fi SSID: $wifiName");

  if (kDebugMode) {
    debugLog("Debug mode: bypassing Wi-Fi checks for testing!");
    return true;
  }

  if (await Posthog().isOptOut()) {
    debugLog("User has opted out of analytics. Ineligible for survey.");
    return false;
  }

  if (normalizedWifiName == null) {
    debugLog("Not connected to Wi-Fi. Ineligible for survey.");
    return false;
  }
  if (normalizedWifiName != 'eduroam') {
    debugLog("Connected to Wi-Fi but not eduroam. Ineligible for survey.");
    return false;
  }

  // Add any additional eligibility checks here if needed

  debugLog("Eligible for Wi-Fi survey.");
  return true;
}
