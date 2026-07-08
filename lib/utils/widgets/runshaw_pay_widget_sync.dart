import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/retry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/http/http_client_factory.dart'
    if (dart.library.js_interop) 'package:runshaw/utils/http/http_client_factory_web.dart'
    as http_factory;
import 'package:runshaw/utils/logging.dart';

const String _widgetAppGroupId = 'group.uk.danieldb.myrunshaw';
const String _widgetName = 'RunshawPayWidget';
const String _widgetRefreshHost = 'uk.danieldb.myrunshaw';
const String _widgetRefreshPath = '/refresh-balance';
const String _balanceKey = 'runshawpay_balance';
const String _statusKey = 'runshawpay_status';
const String _updatedAtKey = 'runshawpay_updated_at';

// this is a top-level function so the OS can execute it in a background isolate
@pragma('vm:entry-point')
void runshawPayWidgetHeadlessTask(HeadlessEvent task) async {
  final String taskId = task.taskId;
  final bool isTimeout = task.timeout;

  if (isTimeout) {
    BackgroundFetch.finish(taskId);
    return;
  }

  try {
    await RunshawPayWidgetSync.updateBalanceForWidget(trigger: taskId);
  } finally {
    BackgroundFetch.finish(taskId);
  }
}

class RunshawPayWidgetSync {
  static StreamSubscription<Uri?>? _widgetClickSub;
  static const MethodChannel _platform = MethodChannel('runshaw/widget');

  static Future<void> initialize() async {
    if (kIsWeb) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // iOS requires an App Group id for widget communication.
    if (Platform.isIOS) {
      await HomeWidget.setAppGroupId(_widgetAppGroupId);
    }

    _widgetClickSub ??= HomeWidget.widgetClicked.listen((Uri? uri) async {
      if (_shouldRefreshFromUri(uri)) {
        await updateBalanceForWidget(trigger: 'widget_tap');
      }
    });

    if (Platform.isIOS) {
      final Uri? launchedFromWidget =
          await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (_shouldRefreshFromUri(launchedFromWidget)) {
        await updateBalanceForWidget(trigger: 'widget_tap_launch');
      } else {
        // sync on app startup, so the widget has initial data
        updateBalanceForWidget(trigger: 'app_startup');
      }
    } else if (Platform.isAndroid) {
      // Android: check if app was launched from widget tap
      try {
        final Uri? launchedFromWidget =
            await HomeWidget.initiallyLaunchedFromHomeWidget();
        if (_shouldRefreshFromUri(launchedFromWidget)) {
          debugLog('App launched from widget tap (Android)', level: 1);
          await updateBalanceForWidget(trigger: 'widget_tap_launch_android');
        } else {
          updateBalanceForWidget(trigger: 'app_startup');
        }
      } catch (e) {
        debugLog('Error detecting widget launch on Android: $e', level: 2);
        updateBalanceForWidget(trigger: 'app_startup');
      }
    } else {
      updateBalanceForWidget(trigger: 'app_startup');
    }

    // Only enable BackgroundFetch if a widget is actually present.
    if (Platform.isAndroid || Platform.isIOS) {
      try {
        final bool? hasWidget = await _platform.invokeMethod<bool>('hasWidget');
        if (hasWidget == null || hasWidget == false) {
          debugLog('No widget instances present; skipping BackgroundFetch',
              level: 1);
          return;
        }
      } catch (e) {
        debugLog('Could not determine widget presence: $e', level: 2);
        return;
      }
    }

    await BackgroundFetch.configure(
      BackgroundFetchConfig(
        minimumFetchInterval: 15,
        stopOnTerminate: false,
        enableHeadless: true,
        startOnBoot: false,
        requiresBatteryNotLow: false,
        requiredNetworkType: NetworkType.ANY,
      ),
      _onBackgroundFetch,
      _onBackgroundFetchTimeout,
    );

    // Register the headless task for when the app is completely terminated
    BackgroundFetch.registerHeadlessTask(runshawPayWidgetHeadlessTask);

    await BackgroundFetch.start();
  }

  static bool _shouldRefreshFromUri(Uri? uri) {
    if (uri == null) return false;
    return uri.host == _widgetRefreshHost ||
        uri.path.contains(_widgetRefreshHost) ||
        uri.path.contains(_widgetRefreshPath);
  }

  static Future<void> _onBackgroundFetch(String taskId) async {
    try {
      await updateBalanceForWidget(trigger: taskId);
    } finally {
      BackgroundFetch.finish(taskId);
    }
  }

  static void _onBackgroundFetchTimeout(String taskId) {
    debugLog('RunshawPay background fetch timeout ($taskId)', level: 2);
    BackgroundFetch.finish(taskId);
  }

  static Future<bool> updateBalanceForWidget({required String trigger}) async {
    final allowedImmediateTriggers = {
      'app_startup',
      'widget_tap',
      'widget_tap_launch',
    };

    if (!allowedImmediateTriggers.contains(trigger)) {
      try {
        final String? existingBalance =
            await HomeWidget.getWidgetData<String>(_balanceKey);
        final String? existingStatus =
            await HomeWidget.getWidgetData<String>(_statusKey);

        if ((existingBalance == null || existingBalance == 'Unknown') &&
            existingStatus == null) {
          debugLog('No widget data found; skipping background fetch ($trigger)',
              level: 1);
          return false;
        }
      } catch (e) {
        debugLog('Widget presence check failed; skipping fetch: $e', level: 2);
        return false;
      }
    }

    try {
      final String? balance = await _fetchRunshawPayBalance();
      await saveWidgetPayload(
          balance: balance, status: balance == null ? 'error' : 'ok');
      debugLog(
          'RunshawPay widget sync complete ($trigger): ${balance ?? 'Unknown'}',
          level: 1);
      return true;
    } catch (e) {
      await saveWidgetPayload(balance: null, status: 'error');
      debugLog('RunshawPay widget sync failed ($trigger): $e', level: 3);
      return false;
    }
  }

  static Future<String?> _fetchRunshawPayBalance() async {
    // grab the JWT from SharedPreferences instead of Appwrite!
    final prefs = await SharedPreferences.getInstance();
    final jwt = prefs.getString('jwt_token');

    if (jwt == null) {
      debugLog('Cannot fetch balance for widget: No JWT found in storage.',
          level: 2);
      return null;
    }

    // fetch the balance
    final response =
        await RetryClient(http_factory.httpClient(), retries: 2).get(
      Uri.parse('${MyRunshawConfig.apiUrl}/api/payments/balance'),
      headers: {
        'Authorization': 'Bearer $jwt',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      debugLog('Failed to fetch balance. API returned ${response.statusCode}',
          level: 2);
      return null;
    }

    final dynamic payload = jsonDecode(utf8.decode(response.bodyBytes));
    if (payload is! Map<String, dynamic>) {
      return null;
    }

    return payload['balance']?.toString();
  }

  static Future<void> saveWidgetPayload({
    required String? balance,
    required String status,
  }) async {
    if (kIsWeb) return;

    await HomeWidget.saveWidgetData<String>(_balanceKey, balance ?? 'Unknown');
    await HomeWidget.saveWidgetData<String>(_statusKey, status);
    await HomeWidget.saveWidgetData<int>(
      _updatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    if (Platform.isIOS) {
      await HomeWidget.updateWidget(iOSName: _widgetName);
    } else if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
          qualifiedAndroidName: 'com.daniel.runshaw.RunshawPayWidgetReceiver');
    }
  }
}
