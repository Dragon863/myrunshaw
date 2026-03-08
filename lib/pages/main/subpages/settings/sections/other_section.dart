import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsOtherSection extends StatefulWidget {
  final String appVersion;

  const SettingsOtherSection({super.key, required this.appVersion});

  @override
  State<SettingsOtherSection> createState() => _SettingsOtherSectionState();
}

class _SettingsOtherSectionState extends State<SettingsOtherSection> {
  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        "Other",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          title: const Text(
            "Analytics Opt-Out",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: FutureBuilder<bool>(
            future: Posthog().isOptOut(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final bool enabled = snapshot.data ?? true;
              return Switch(
                value: enabled,
                onChanged: (value) async {
                  final prefs = await SharedPreferences.getInstance();
                  if (value) {
                    await Posthog().disable();
                    await prefs.setBool("analytics_opt_out", true);
                    debugLog("Disabled analytics");
                  } else {
                    await Posthog().enable();
                    await prefs.setBool("analytics_opt_out", false);
                    debugLog("Enabled analytics");
                  }
                  if (mounted) setState(() {});
                },
              );
            },
          ),
        ),
        ListTile(
          title: const Text(
            "Reset Profile Picture Cache",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: const Icon(Icons.delete_outline),
          onTap: () {
            DefaultCacheManager().emptyCache();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile pictures reset!")),
            );
          },
        ),
        ListTile(
          title: const Text(
            "Report Bug",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: const Icon(Icons.bug_report_outlined),
          onTap: () async {
            final Uri emailUri = Uri(
              scheme: 'mailto',
              path: 'hi@danieldb.uk',
              query:
                  "subject=My Runshaw Bug Report&body=App version: ${widget.appVersion}\nBefore sending, please check you are on the latest version of the app from the App Store or Google Play Store. Describe the bug you encountered here:",
            );
            await launchUrl(emailUri);
          },
        ),
        ListTile(
          title: const Text(
            "Official Student Portal",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: const Icon(Icons.school_outlined),
          onTap: () async {
            Uri url = Uri.parse('https://studentportal.runshaw.ac.uk');
            if (!kIsWeb) {
              if (Platform.isAndroid) {
                url = Uri.parse(
                    'https://play.google.com/store/apps/details?id=uk.ac.runshaw.studentportal.app9173&hl=en_GB');
              } else if (Platform.isIOS) {
                url = Uri.parse(
                    'https://apps.apple.com/gb/app/runshaw-student-portal/id6446140462');
              }
            }
            if (await canLaunchUrl(url)) {
              await launchUrl(url);
            } else {
              throw 'Could not launch $url';
            }
          },
        ),
      ],
    );
  }
}
