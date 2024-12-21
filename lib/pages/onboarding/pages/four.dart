import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';

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
        Text(
            "You can sync your calendar with Runshaw's timetable to share it with your friends! To set up:",
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        const Text("1. Log in to your official student portal"),
        const Text("2. In the menu, click on 'Timetable' then 'My Calendar'"),
        const Text(
            '3. Copy the link at the bottom of the page using the button next to it'),
        const Text('4. Paste the link below and click "Sync"'),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Calendar URL',
          ),
          controller: _controller,
          onSubmitted: (value) => syncCalendar(),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: syncCalendar,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.all(Colors.red),
          ),
          child: const Text("Sync"),
        ),
      ];
    });

    final api = context.read<BaseAPI>();
    final timetable = await api.fetchEvents();
    if (timetable.length > 1) {
      setState(() {
        _controller.text = "internal:complete";
        contents = [
          const SizedBox(height: 12),
          Text(
            "You've already completed this step!",
            style: GoogleFonts.rubik(),
          ),
        ];
      });
    }
  }

  @override
  void initState() {
    initStep();
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
            Text(
              "Sync Timetable",
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...contents,
          ],
        ),
      ),
    );
  }
}
