import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

class WifiSurveyStageTwo extends StatelessWidget {
  final ValueChanged<bool>? onPermissionGranted;

  const WifiSurveyStageTwo({super.key, this.onPermissionGranted});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            "Permissions",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To measure Wi-Fi speeds, we need some extra permissions. \n\n'
            'This data is only used to measure Wi-Fi speeds and signal strength, and is NOT used for any other purpose. \n\n'
            'We won\'t access this data until you start the survey, and you can revoke these permissions at any time in your device settings.',
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          // button
          Center(
            child: ElevatedButton(
              onPressed: () async {
                // Request necessary permissions for (i.e. location) on Android)
                if (Theme.of(context).platform == TargetPlatform.android) {
                  PermissionStatus permission =
                      await Permission.location.request();
                  if (permission.isGranted) {
                    onPermissionGranted?.call(true);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Permissions granted!"),
                      ),
                    );
                    return;
                  } else {
                    onPermissionGranted?.call(false);
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Please grant permissions in settings to continue.",
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                "Grant Permissions",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
