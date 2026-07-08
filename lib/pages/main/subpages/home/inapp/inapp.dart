import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:runshaw/pages/main/subpages/home/inapp/inapp_notice.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io' show Platform;

void checkInAppAlerts(BuildContext context) async {
  final api = context.read<BaseAPI>();
  final List<Map<String, dynamic>> notices = await api.getInAppNotices();

  for (final Map<String, dynamic> notice in notices) {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String id = notice["noticeId"];

    debugLog("Checking notice $id");

    if (prefs.getBool(id) == null || prefs.getBool(id) == false) {
      final bool isIos = notice["ios"];
      final bool isAndroid = notice["android"];

      if (isAndroid == false && Platform.isAndroid) {
        debugLog("Skipping notice $id as it is not for Android");
        continue;
      } else if (isIos == false && Platform.isIOS) {
        debugLog("Skipping notice $id as it is not for iOS");
        continue;
      }

      if (notice["expires"] != null) {
        final DateTime date = DateTime.parse(notice["expires"]);
        final DateTime now = DateTime.now();
        if (now.isAfter(date)) {
          debugLog("Skipping notice $id as it has expired");
          // Notice has expired
          continue;
        }
      }

      if (notice["maxversion"] != null) {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final Version currentVersion = Version.parse(packageInfo.version);

        final Version maxVersion = Version.parse(notice["maxversion"]);
        if (currentVersion > maxVersion) {
          debugLog("Skipping notice $id as the user's version is too high");
          // User's version is too high
          continue;
        }
      }

      if (notice["minversion"] != null) {
        final PackageInfo packageInfo = await PackageInfo.fromPlatform();
        final Version currentVersion = Version.parse(packageInfo.version);

        final Version minVersion = Version.parse(notice["minversion"]);
        if (currentVersion < minVersion) {
          debugLog("Skipping notice $id as the user's version is too low");
          // User's version is too low
          continue;
        }
      }

      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) {
          return InAppNotice(data: notice);
        },
      );
    } else {
      // User has already seen this notice
      continue;
    }
  }
}
