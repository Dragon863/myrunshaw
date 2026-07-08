import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';

class OnBoardingStageFive extends StatefulWidget implements OnboardingStage {
  const OnBoardingStageFive({super.key});

  @override
  State<OnBoardingStageFive> createState() => _OnBoardingStageFiveState();

  static final GlobalKey<_OnBoardingStageFiveState> _stateKey = GlobalKey();

  @override
  Future<bool> onLeaveStage() async {
    return true; // static stage
  }

  @override
  Key? get key => _stateKey;
}

class _OnBoardingStageFiveState extends State<OnBoardingStageFive> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 250,
              ),
              child:
                  Image.asset('assets/img/onboarding/runshawpay-graphic.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "RunshawPay",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Check your balance, view your transactions, all in one place!",
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 15),
                      children: [
                        TextSpan(text: '• This feature '),
                        TextSpan(
                          text: 'requires ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'syncing your timetable'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 15),
                      children: [
                        TextSpan(
                          text: '• Home screen widgets ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(
                            text:
                                'that show your balance are available on both iOS and Android, and will refresh roughly '),
                        TextSpan(
                          text: 'every 10 minutes',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: ' during college hours'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
