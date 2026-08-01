import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_core.dart';

/// a notification-capable installation belonging to the current account.
class NotificationDevice {
  final String id;
  final String name;
  final String platform;
  final bool notificationsEnabled;
  final bool busNotificationsEnabled;
  final bool isCurrentDevice;

  const NotificationDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.notificationsEnabled,
    required this.busNotificationsEnabled,
    required this.isCurrentDevice,
  });

  factory NotificationDevice.fromJson(Map<String, dynamic> json) {
    return NotificationDevice(
      id: json['deviceId']?.toString() ?? json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown device',
      platform: json['platform']?.toString() ?? 'unknown',
      notificationsEnabled: json['notificationsEnabled'] != false,
      busNotificationsEnabled: json['busNotificationsEnabled'] != false,
      isCurrentDevice: json['isCurrentDevice'] == true,
    );
  }
}

class CurrentDeviceNotificationPreference {
  final bool notificationsEnabled;
  final bool busNotificationsEnabled;

  const CurrentDeviceNotificationPreference({
    required this.notificationsEnabled,
    required this.busNotificationsEnabled,
  });

  factory CurrentDeviceNotificationPreference.fromJson(
      Map<String, dynamic> json) {
    return CurrentDeviceNotificationPreference(
      notificationsEnabled: json['notificationsEnabled'] != false,
      busNotificationsEnabled: json['busNotificationsEnabled'] != false,
    );
  }
}

mixin ApiNotifications on ApiCore {
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Registers this installation and replaces its token when FCM rotates it.
  Future<void> registerCurrentDeviceForNotifications() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS) || jwt == null) {
      return;
    }

    final token = await FirebaseMessaging.instance.getToken();
    debugLog("FCM token: $token", level: 1);
    if (token == null || token.isEmpty) return;

    final deviceId = await _deviceId();
    final response =
        await apiPut('/api/notifications/devices/$deviceId', body: {
      'token': token,
      ...await _deviceDetails(),
    });
    if (response.statusCode != 200 &&
        response.statusCode != 201 &&
        response.statusCode != 204) {
      throw humanResponse(response.body);
    }

    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen(
      (newToken) async {
        if (jwt == null) return;
        try {
          final refreshedDeviceId = await _deviceId();
          await apiPut('/api/notifications/devices/$refreshedDeviceId', body: {
            'token': newToken,
            ...await _deviceDetails(),
          });
        } catch (_) {
          // The next launch registers the latest token again.
        }
      },
    );
  }

  Future<CurrentDeviceNotificationPreference>
      getCurrentDeviceNotificationPreference() async {
    final deviceId = await _deviceId();
    final response =
        await apiGet('/api/notifications/devices/$deviceId/preferences');
    if (response.statusCode == 404) {
      return const CurrentDeviceNotificationPreference(
        notificationsEnabled: true,
        busNotificationsEnabled: true,
      );
    }
    if (response.statusCode != 200) throw humanResponse(response.body);
    return CurrentDeviceNotificationPreference.fromJson(
      Map<String, dynamic>.from(jsonDecode(response.body) as Map),
    );
  }

  Future<void> setCurrentDeviceBusNotifications(bool enabled) async {
    final deviceId = await _deviceId();
    final response =
        await apiPut('/api/notifications/devices/$deviceId/preferences', body: {
      'busNotificationsEnabled': enabled,
    });
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw humanResponse(response.body);
    }
  }

  Future<String> _deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'notification_device_id';
    final existing = prefs.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final id = List.generate(24, (_) => random.nextInt(256))
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();
    await prefs.setString(key, id);
    return id;
  }

  Future<Map<String, dynamic>> _deviceDetails() async {
    final package = await PackageInfo.fromPlatform();
    final info = DeviceInfoPlugin();
    String name = 'Unknown device';
    String platform = defaultTargetPlatform.name;

    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      name = '${android.manufacturer} ${android.model}'.trim();
      platform = 'android';
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      name = ios.name;
      platform = 'ios';
    }

    return {
      'name': name,
      'platform': platform,
      'appVersion': '${package.version}+${package.buildNumber}',
    };
  }
}
