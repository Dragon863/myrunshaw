import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:appwrite/appwrite.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart';
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

  static Future<void> initialize() async {
    if (kIsWeb || !Platform.isIOS) {
      return;
    }

    await HomeWidget.setAppGroupId(_widgetAppGroupId);

    _widgetClickSub ??= HomeWidget.widgetClicked.listen((Uri? uri) async {
      if (_shouldRefreshFromUri(uri)) {
        await updateBalanceForWidget(trigger: 'widget_tap');
      }
    });

    final Uri? launchedFromWidget =
        await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (_shouldRefreshFromUri(launchedFromWidget)) {
      await updateBalanceForWidget(trigger: 'widget_tap_launch');
    } else {
      // sync on app startup, so the widget has initial data
      updateBalanceForWidget(trigger: 'app_startup');
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
    if (kIsWeb || !Platform.isIOS) return;
    
    await HomeWidget.saveWidgetData<String>(_balanceKey, balance ?? 'Unknown');
    await HomeWidget.saveWidgetData<String>(_statusKey, status);
    await HomeWidget.saveWidgetData<int>(
      _updatedAtKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await HomeWidget.updateWidget(iOSName: _widgetName);
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

  await RunshawPayWidgetSync.updateBalanceForWidget(trigger: taskId);
  BackgroundFetch.finish(taskId);
}
