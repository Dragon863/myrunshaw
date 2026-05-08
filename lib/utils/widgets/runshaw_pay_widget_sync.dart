import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';
import 'package:http/retry.dart';
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

class RunshawPayWidgetSync {
  static StreamSubscription<Uri?>? _widgetClickSub;
  static const MethodChannel _platform = MethodChannel('runshaw/widget');

  static Future<void> initialize() async {
    if (kIsWeb) return;

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
    } else {
      // on Android just perform an initial sync on startup so
      // any native widget code can read the saved values.
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
        // Avoid starting BackgroundFetch if we cannot determine presence.
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

    await BackgroundFetch.start();
  }

  static bool _shouldRefreshFromUri(Uri? uri) {
    if (uri == null) {
      return false;
    }
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
    // Background fetch tasks should avoid unnecessary network usage when
    // there's no widget present. Allow explicit triggers from app startup or
    // widget taps to always run so initial syncs still occur.
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

        // If there is no stored widget data, assume no widget needs updating
        // and skip the network fetch to avoid unnecessary requests.
        if ((existingBalance == null || existingBalance == 'Unknown') &&
            existingStatus == null) {
          debugLog('No widget data found; skipping background fetch ($trigger)',
              level: 1);
          return false;
        }
      } catch (e) {
        // If we cannot determine widget presence from HomeWidget, be
        // conservative and skip to avoid unwanted network usage.
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
    final client = Client()
        .setEndpoint(MyRunshawConfig.endpoint)
        .setProject(MyRunshawConfig.projectId);

    final account = Account(client);
    final jwt = await account.createJWT();

    final response =
        await RetryClient(http_factory.httpClient(), retries: 2).get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/payments/balance'),
      headers: {
        'Authorization': 'Bearer ${jwt.jwt}',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
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

    // Trigger a widget update where supported. iOS needs the iOSName; on
    // Android: trigger the native provider update using the qualified class name
    if (Platform.isIOS) {
      await HomeWidget.updateWidget(iOSName: _widgetName);
    } else if (Platform.isAndroid) {
      await HomeWidget.updateWidget(
          qualifiedAndroidName: 'com.daniel.runshaw.RunshawPayWidgetReceiver');
    }
  }
}

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
