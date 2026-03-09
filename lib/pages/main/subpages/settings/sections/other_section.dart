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
  Future<bool> getAnalyticsState() async {
    // Returns true if analytics is enabled, false if it is disabled. Checks shared preferences first, then falls back to Posthog's isOptOut method if no preference is set. This is because the user may have changed their analytics preference in a previous version of the app that didn't store the preference in shared preferences, so we need to check Posthog's opt-out status to determine their current preference.
    final prefs = await SharedPreferences.getInstance();
    final bool? optOut = prefs.getBool("analytics_opt_out");
    if (optOut == null) {
      final bool isOptedOut = await Posthog().isOptOut();
      debugLog(
        "User has ${isOptedOut ? "opted out of" : "opted in to"} analytics (determined by Posthog)",
        level: 1,
      );
      return !isOptedOut;
    }
    debugLog(
      "User has ${optOut ? "opted out of" : "opted in to"} analytics (determined by shared preferences)",
      level: 1,
    );
    return !optOut;
  }

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
            future: getAnalyticsState(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final bool enabled = snapshot.data ?? true;
              return Switch(
                value: !enabled,
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
