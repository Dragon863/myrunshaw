import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class OnBoardingStageOne extends StatelessWidget {
  const OnBoardingStageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 360,
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: Image.asset('assets/img/wave.png'),
              ),
            ),
          ),
          Text(
            "Welcome!",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Before we get started, we need to explain that this app is unofficial - it is built and maintained by a student at the college.",
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
          ),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: "The official portal can be found ",
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: GestureDetector(
                    onTap: () async {
                      Uri url =
                          Uri.parse('https://studentportal.runshaw.ac.uk');
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
                    child: Text(
                      "here",
                      style: GoogleFonts.rubik(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Text(
            "Please don't report issues to the service desk, as they will not be able to help you! Instead use the button in settings",
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
          )
        ],
      ),
    );
  }
}
