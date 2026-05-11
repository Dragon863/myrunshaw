import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/wifisurvey/wifisurvey.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/surveys/check_eligible.dart';
import 'package:runshaw/utils/surveys/wifi_speed.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WifiSurveyCampaign {
  static const String _consentPrefKey = 'wifi_survey_consent';
  static bool _isRunning = false;

  static Future<void> maybeStart(BuildContext context) async {
    // Enable surveys on Android and iOS (skip web and other platforms).
    if (kIsWeb ||
        !(defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    if (_isRunning) {
      return;
    }

    final NavigatorState navigator = Navigator.of(context);
    final BaseAPI api = context.read<BaseAPI>();

    _isRunning = true;
    try {
      final bool isActive = await _isFeatureFlagActive(api);
      if (!isActive) {
        return;
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool? consent = prefs.getBool(_consentPrefKey);

      if (consent == true) {
        unawaited(_runBackgroundSurvey(api));
        return;
      }

      if (consent == false) {
        return;
      }

      if (!_isWithinPromptWindow(DateTime.now())) {
        debugLog('Wi-Fi survey prompt skipped outside the allowed window.');
        return;
      }

      if (!navigator.mounted) {
        return;
      }

      final bool accepted = await _showPrompt(navigator.context);
      await prefs.setBool(_consentPrefKey, accepted);

      if (!accepted || !context.mounted) {
        return;
      }

      final bool completed = await navigator.push<bool>(
            MaterialPageRoute<bool>(
              builder: (context) => const WifiSurveyPage(),
            ),
          ) ??
          false;

      if (completed) {
        unawaited(_runBackgroundSurvey(api));
      }
    } catch (e, stackTrace) {
      debugLog(
        'Wi-Fi survey campaign failed: $e\n$stackTrace',
        level: 3,
      );
    } finally {
      _isRunning = false;
    }
  }

  static Future<bool> _isFeatureFlagActive(BaseAPI api) async {
    // try {
    //   final Client client = api.client;
    //   final TablesDB databases = TablesDB(client);

    //   final appwrite_models.Row row = await databases.getRow(
    //     databaseId: MyRunshawConfig.featureFlagsDbId,
    //     tableId: MyRunshawConfig.featureFlagsCollectionId,
    //     rowId: 'wifi_survey_active',
    //   );

    //   final bool enabled = row.data['state'] == true;
    //   debugLog(
    //     'Wi-Fi survey feature flag is ${enabled ? 'enabled' : 'disabled'}.',
    //     level: 1,
    //   );
    //   return enabled;
    // } catch (e, stackTrace) {
    //   debugLog(
    //     'Failed to load wifi_survey_active flag: $e\n$stackTrace',
    //     level: 3,
    //   );
    //   return false;
    // }
    final bool enabled = await Posthog().isFeatureEnabled('wifi_survey_active');
    debugLog(
      'Wi-Fi survey feature flag is ${enabled ? 'enabled' : 'disabled'}.',
      level: 1,
    );
    return enabled;
  }

  static bool _isWithinPromptWindow(DateTime now) {
    final DateTime windowStart = DateTime(now.year, now.month, now.day, 9);
    final DateTime windowEnd = DateTime(now.year, now.month, now.day, 15, 20);
    if (kDebugMode) {
      debugLog(
        'Bypassing prompt window check in debug mode. Current time: $now, Window: $windowStart - $windowEnd',
      );
    }
    return (!now.isBefore(windowStart) && !now.isAfter(windowEnd)) ||
        kDebugMode;
  }

  static Future<bool> _showPrompt(BuildContext context) async {
    final bool? accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eduroam Survey'),
          content: const Text(
            'Please help improve Wi-Fi at Runshaw by participating in a quick survey! This will take less than a minute.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No thanks'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Participate'),
            ),
          ],
        );
      },
    );

    return accepted == true;
  }

  static Future<void> _runBackgroundSurvey(BaseAPI api) async {
    if (!await checkWifiSurveyEligibility()) {
      return;
    }

    final WifiSpeedSurvey survey = WifiSpeedSurvey();
    final WifiSpeedSurveyResult? result = await survey.runSpeedTest();
    if (result == null) {
      return;
    }

    final bool uploaded = await survey.uploadResult(
      result,
      submitter: api.submitWifiSurveyResults,
    );

    if (uploaded) {
      debugLog('Wi-Fi background survey completed successfully.');
    } else {
      debugLog(
        'Wi-Fi background survey completed but upload failed.',
        level: 2,
      );
    }
  }
}
