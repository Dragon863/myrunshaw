import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/pages/onboarding/pages/video_tutorial.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:url_launcher/url_launcher.dart';

class OnBoardingStageFour extends StatefulWidget implements OnboardingStage {
  const OnBoardingStageFour({super.key});

  @override
  State<OnBoardingStageFour> createState() => _OnBoardingStageFourState();

  static final GlobalKey<_OnBoardingStageFourState> _stateKey = GlobalKey();

  @override
  Key? get key => _stateKey;

  @override
  Future<bool> onLeaveStage() async {
    final state = _stateKey.currentState;
    if (state != null) {
      final url = state._controller.text;
      RegExp regex = RegExp(
          r'https://webservices\.runshaw\.ac\.uk/timetable\.ashx\?id=.*');

      if (url == "internal:complete") {
        return true;
      }

      if (regex.hasMatch(url)) {
        try {
          await syncFromUrl(url, state.context);
          ScaffoldMessenger.of(state.context).showSnackBar(
            const SnackBar(
              content: Text("Sync complete!"),
            ),
          );
          return true;
        } catch (e) {
          ScaffoldMessenger.of(state.context).showSnackBar(
            SnackBar(
              content: Text("An error occurred whilst syncing: $e"),
            ),
          );
        }
      } else {
        return false;
      }
    }
    return false;
  }
}

class _OnBoardingStageFourState extends State<OnBoardingStageFour> {
  final TextEditingController _controller = TextEditingController();
  List<Widget> contents = [];
  bool timetablesReleased = true;

  Future<void> checkTimetablesReleases() async {
    // runshaw doesn't release the timetables right away, so I store a feature flag in Posthog
    // to check if they have. If not, the user can always add it later in settings.
    final PostHogFeatureFlagResult? result =
        await Posthog().getFeatureFlagResult("timetables_released");
    // default to true; a bug in Posthog shouldn't prevent onboarding from working
    final bool timetablesReleased = result?.enabled ?? true;
    setState(() {
      this.timetablesReleased = timetablesReleased;
    });
    debugLog("Timetables released: $timetablesReleased");
    if (timetablesReleased) {
      initStep();
    } else {
      setState(() {
        _controller.text = "internal:complete";
        contents = [
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Please complete later in the timetable page",
              style: GoogleFonts.rubik(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ];
      });
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Timetables not released yet"),
            content: const Text(
                "The college hasn't released the timetables yet, so you can't sync your timetable right now. Please complete this step later in the timetable page."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> syncCalendar() async {
    RegExp regex =
        RegExp(r'https://webservices\.runshaw\.ac\.uk/timetable\.ashx\?id=.*');

    if (regex.hasMatch(_controller.text)) {
      try {
        syncFromUrl(_controller.text, context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Sync complete!"),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred whilst syncing: $e"),
          ),
        );
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Invalid URL"),
            content: const Text(
                "That URL doesn't look right. Please re-read the steps and try again."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> initStep() async {
    setState(() {
      contents = [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      const TextSpan(text: '1. Log into the '),
                      TextSpan(
                        text: 'Student Portal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            final uri = Uri.parse(
                              'https://studentportal.runshaw.ac.uk/',
                            );
                            await launchUrl(uri);
                          },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      TextSpan(text: '2. Choose '),
                      TextSpan(
                        text: '“Timetable” > “My Calendar”',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      TextSpan(text: '3. '),
                      TextSpan(
                        text: 'Copy the link at the bottom',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                          text: ' of the page using the button next to it'),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 15, color: Colors.black),
                    children: [
                      TextSpan(text: '4. '),
                      TextSpan(
                        text: 'Paste the link',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(text: ' here and press "Sync"'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Timetable URL',
          ),
          controller: _controller,
          onSubmitted: (value) => syncCalendar(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilledButton(
              onPressed: syncCalendar,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all(Colors.red),
              ),
              child: const Text("Sync"),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const VideoTutorial(),
                  ),
                );
              },
              child: const Text("Video Tutorial"),
            )
          ],
        ),
      ];
    });

    final api = context.read<BaseAPI>();
    final bool completed = api.currentUser?.hasTimetableLinked ?? false;
    if (completed && !kDebugMode) {
      setState(() {
        _controller.text = "internal:complete";
        contents = [
          const SizedBox(height: 12),
          Center(
            child: Text(
              "You've already completed this step!",
              style: GoogleFonts.rubik(
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ];
      });
    }
  }

  @override
  void initState() {
    checkTimetablesReleases();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 250,
                ),
                child:
                    Image.asset('assets/img/onboarding/timetable-graphic.png'),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                "Sync Timetable",
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sync your Runshaw timetable to share it with friends and use RunshawPay",
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            ...contents,
          ],
        ),
      ),
    );
  }
}
