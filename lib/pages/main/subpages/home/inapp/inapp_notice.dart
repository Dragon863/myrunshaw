import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

class InAppNotice extends StatelessWidget {
  final Map<String, dynamic> data;

  const InAppNotice({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(6),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 1000,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    "In-App Notification",
                    style: GoogleFonts.rubik(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                Text(
                  data['title'],
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 4,
                  width: 72,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                if (data["imageurl"] != null)
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        data["imageurl"],
                        fit: BoxFit.cover,
                        width: 700,
                        height: 400,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                if (data["link"] != null)
                  TextButton.icon(
                    style: const ButtonStyle(
                        padding: WidgetStatePropertyAll(
                      EdgeInsets.only(
                        left: 2.0,
                        right: 12,
                        top: 12,
                        bottom: 12,
                      ),
                    )),
                    onPressed: () async {
                      await launchUrlString(data["link"]);
                    },
                    icon: const Icon(Icons.link),
                    label: Text(
                      data["linktext"] ?? "Link",
                      style: GoogleFonts.rubik(
                        color: Colors.red,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  data['description'],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () async {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        final String noticeId = data["\$id"];

                        prefs.setBool(noticeId, true); // Set the notice as read
                        await Posthog().capture(
                          eventName: "inapp_notice_read",
                          properties: {
                            "id": noticeId,
                          },
                        );
                        Navigator.pop(context);
                      },
                      child: const Text("OK"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void dispose(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String noticeId = data["\$id"];

    prefs.setBool(noticeId, true); // Set the notice as read
    await Posthog().capture(
      eventName: "inapp_notice_read",
      properties: {
        "id": noticeId,
      },
    );
    Navigator.pop(context);
  }
}
