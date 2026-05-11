import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WifiSurveyStageOne extends StatelessWidget {
  const WifiSurveyStageOne({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image(
                image: NetworkImage(
                  "https://webservices.runshaw.ac.uk/Images/its.png",
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Intro",
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'This quick survey will automatically measure college Wi-Fi (eduroam) speeds to help IT Services improve your experience across college. \n\n'
              'We\'ll request access to location so we can measure Wi-Fi signal strength and speed, run a quick test for about 20 seconds, and upload'
              ' the results anonymously to Runshaw. \n\nThanks for helping improve Wi-Fi for everyone!',
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
