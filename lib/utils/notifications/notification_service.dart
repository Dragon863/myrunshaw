import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';

/// The app destination encoded in an FCM data payload.
///
/// New sends should use `destination` (`bus`, `friends`, or `pay`) and, for a
/// bus, `busId` and optional `bay`. The legacy keys are accepted to make the
/// server rollout independent from the app rollout
class NotificationDestination {
  final String section;
  final String? busId;
  final String? bay;

  const NotificationDestination._(this.section, {this.busId, this.bay});

  factory NotificationDestination.fromData(Map<String, dynamic> data) {
    final destination =
        (data['destination'] ?? data['route'] ?? data['type'] ?? '')
            .toString()
            .toLowerCase();
    final busId =
        (data['busId'] ?? data['bus_id'] ?? data['busNumber'])?.toString();
    if (destination == 'bus' ||
        destination == '/bus' ||
        destination == 'bus_arrival' ||
        busId != null) {
      return NotificationDestination._('bus',
          busId: busId, bay: data['bay']?.toString());
    }
    if (destination == 'friends' ||
        destination == '/friends' ||
        destination == 'friend_request') {
      return const NotificationDestination._('friends');
    }
    if (destination == 'pay' ||
        destination == '/pay' ||
        destination == 'payment') {
      return const NotificationDestination._('pay');
    }
    return const NotificationDestination._('home');
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payloads are rendered by the OS while the app is backgrounded.
  // Keep this handler for data-only messages and future background processing.
  debugLog('FCM background message: ${message.messageId}', level: 1);
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _started = false;

  Future<NotificationDestination?> start({
    required void Function(NotificationDestination destination) onOpened,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return null;

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    if (!_started) {
      _started = true;

      final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
          FlutterLocalNotificationsPlugin();

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        onOpened(NotificationDestination.fromData(message.data));
      });

      FirebaseMessaging.onMessage.listen((message) async {
        RemoteNotification? notification = message.notification;
        AndroidNotification? android = message.notification?.android;

        final targetChannelId = android?.channelId ?? "general_channel";
        final targetChannel = MyRunshawConfig.notificationChannels.firstWhere(
          (channel) => channel.id == targetChannelId,
          orElse: () => MyRunshawConfig.notificationChannels.firstWhere(
            (channel) => channel.id == "general_channel",
            orElse: () => const AndroidNotificationChannel(
              'general_channel',
              'General Notifications',
              description: 'General notifications for the app',
              importance: Importance.defaultImportance,
            ),
          ),
        );

        // If `onMessage` is triggered with a notification, construct our own
        // local notification to show to users using the created channel.
        if (notification != null && android != null) {
          final icon = android.smallIcon ?? 'app_logo';
          try {
            await flutterLocalNotificationsPlugin.show(
              id: notification.hashCode,
              title: notification.title,
              body: notification.body,
              notificationDetails: NotificationDetails(
                android: AndroidNotificationDetails(
                  targetChannel.id,
                  targetChannel.name,
                  channelDescription: targetChannel.description,
                  icon: icon,
                  color: const Color.fromARGB(255, 230, 48, 9), // #E63009
                ),
              ),
            );
          } catch (e) {
            debugLog('Failed to show notification with icon "$icon": $e',
                level: 1);
            if (icon != 'app_logo') {
              try {
                await flutterLocalNotificationsPlugin.show(
                  id: notification.hashCode,
                  title: notification.title,
                  body: notification.body,
                  notificationDetails: NotificationDetails(
                    android: AndroidNotificationDetails(
                      targetChannel.id,
                      targetChannel.name,
                      channelDescription: targetChannel.description,
                      icon: 'app_logo',
                      color: const Color.fromARGB(255, 230, 48, 9), // #E63009
                    ),
                  ),
                );
              } catch (retryError) {
                debugLog(
                    'Failed to show notification with fallback icon: $retryError',
                    level: 1);
              }
            }
          }
        }
      });
    }

    final initialMessage = await messaging.getInitialMessage();
    return initialMessage == null
        ? null
        : NotificationDestination.fromData(initialMessage.data);
  }

  Future<void> createNotificationChannels() async {
    if (kIsWeb || !Platform.isAndroid) return;

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    for (final androidChannel in MyRunshawConfig.notificationChannels) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }
}
