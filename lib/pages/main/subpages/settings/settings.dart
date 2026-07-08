import 'dart:io';
import 'dart:typed_data';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/settings/popup_crop.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/account_section.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/buses_section.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/legal_section.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/other_section.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/profile_section.dart';
import 'package:runshaw/pages/main/subpages/settings/sections/theme_section.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showNotifs = true;
  bool nameLoaded = false;
  String name = "Loading...";
  String email = "Loading...";
  String appVersion = "Loading...";
  String? profilePicUrl;

  @override
  void initState() {
    super.initState();
    fetchPrefs();
    loadVersion();
  }

  Future<void> fetchPrefs() async {
    final BaseAPI api = context.read<BaseAPI>();
    await api.refreshUser(); // Get latest user object from the C# backend

    if (api.currentUser == null) return;
    if (!mounted) return;

    setState(() {
      profilePicUrl = api.getPfpUrl(api.currentUser!.id);
      name =
          api.currentUser!.name.isEmpty ? "Anonymous" : api.currentUser!.name;
      nameLoaded = true;
      email = api.currentUser!.email;
    });

    final tags = await OneSignal.User.getTags();
    if (!mounted) return;
    final bool optOut = tags["bus_optout"] == "true";
    if (optOut) {
      setState(() => showNotifs = false);
    }
  }

  Future<void> loadVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => appVersion = "v${packageInfo.version}");
  }

  Future<void> photoAction() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text("Camera"),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              title: const Text("Gallery"),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
    );

    if (file == null) return;

    final Uint8List bytes = await file.readAsBytes();
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PopupCropPage(imageBytes: bytes),
      ),
    );

    if (result.runtimeType == CropSuccess) {
      bool uploading = true;
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (BuildContext context) => Dialog(
          insetPadding: const EdgeInsets.all(6),
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Container(
              constraints: const BoxConstraints(minWidth: 150, maxWidth: 1000),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Just a sec!',
                        style: GoogleFonts.rubik(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      height: 4,
                      width: 72,
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    const SizedBox(height: 8),
                    Text('Uploading your profile picture...',
                        style: GoogleFonts.rubik(
                            fontSize: 16, fontWeight: FontWeight.normal)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ).then((_) => uploading = false);

      // Timeout of 15 seconds
      Future.delayed(const Duration(seconds: 15), () {
        if (mounted && uploading) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  "Sorry, that upload is taking longer than expected - please try again later."),
            ),
          );
          Navigator.of(context, rootNavigator: true).pop();
        }
      });

      final Uint8List croppedBytes = (result as CropSuccess).croppedImage;

      // Save bytes to a temporary local file so we can upload it
      final tempFile = File('${Directory.systemTemp.path}/profile_upload.png');
      await tempFile.writeAsBytes(croppedBytes);

      final api = context.read<BaseAPI>();

      // Hit the C# multipart endpoint!
      final StreamedResponse uploadResponse = await api.apiMultipart(
        '/api/users/me/profile-pic',
        tempFile.path,
      );

      if (uploadResponse.statusCode == 200) {
        // Manually trigger a version increment locally so our cache busts instantly
        api.cachedPfpVersions[api.currentUser!.id] =
            (api.cachedPfpVersions[api.currentUser!.id] ?? 0) + 1;

        setState(() {
          profilePicUrl = api.getPfpUrl(api.currentUser!.id);
        });

        await Posthog().capture(eventName: 'pfp_updated');
      } else {
        final responseBody = await Response.fromStream(uploadResponse);
        debugLog(responseBody.body, level: 1);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseBody.body)),
          );
        }
      }

      if (mounted && uploading) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    } else if (result.runtimeType == CropFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error cropping image")),
      );
    }
  }

  Future<void> deleteAction() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Profile Picture"),
        content:
            const Text("Are you sure you want to delete your profile picture?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (result == true) {
      final api = context.read<BaseAPI>();

      await api.apiDelete('/api/users/me/profile-pic');

      setState(() => profilePicUrl = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 700),
            child: Column(
              children: [
                SettingsProfileSection(
                  name: name,
                  nameLoaded: nameLoaded,
                  email: email,
                  profilePicUrl: profilePicUrl,
                  onPhotoTap: photoAction,
                  onDeleteTap: deleteAction,
                  onNameChange: (newName) async {
                    final api = context.read<BaseAPI>();
                    final response = await api.apiPost(
                      '/api/users/me/name',
                      body: {'new_name': newName},
                    );

                    if (response.statusCode == 200) {
                      await fetchPrefs();
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(api.humanResponse(response.body))),
                        );
                      }
                    }
                  },
                ),
                const SettingsThemeSection(),
                SettingsBusesSection(
                  showNotifs: showNotifs,
                  onShowNotifsChanged: (value) =>
                      setState(() => showNotifs = value),
                ),
                const SettingsLegalSection(),
                const SettingsAccountSection(),
                SettingsOtherSection(appVersion: appVersion),
                const SizedBox(height: 8),
                Center(
                  child: Text("App $appVersion, © Daniel Benge"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
