import 'dart:io' show Platform;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'eap_config.dart';

class WifiProfileException implements Exception {
  WifiProfileException(this.code, this.message);
  final String
      code; // user_cancelled, invalid_username, unverifiable_network, config_rejected, add_failed, not_in_foreground (iOS), hotspot_<n> (iOS), suggestion_failed_<n> (Android), unknown
  final String? message;
  bool get cancelled => code == 'user_cancelled';
  @override
  String toString() => 'WifiProfileException($code): $message';
}

class WifiProfileService {
  static bool get _supported => Platform.isIOS || Platform.isAndroid;

  Future<MethodChannel> get channel async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final channel = MethodChannel('${packageInfo.packageName}/wifi_profile');

    return channel;
  }

  /// iOS: Apple's "Join Wi-Fi network?" prompt.
  /// Android 12+: system "Add networks" dialog.
  /// pulls profile from CAT first
  Future<void> configure(
      {required String username, required String password}) async {
    if (!_supported) return;
    final config = await fetchEapConfig(); // may throw EapConfigException
    try {
      await (await channel).invokeMethod<void>('configure', {
        'username': username,
        'password': password,
        'config': config,
      });
    } on PlatformException catch (e) {
      throw WifiProfileException(e.code, e.message);
    }
  }

  Future<void> remove() async {
    if (!_supported) return;
    final config = await fetchEapConfig();
    await (await channel).invokeMethod<void>('remove', {'config': config});
  }
}

Future<String?> promptForNetworkPassword(
    BuildContext context, String username) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Connect to college Wi-Fi'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(username),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            obscureText: true,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Network password'),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx), child: const Text('Skip')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('Connect'),
        ),
      ],
    ),
  );
}
