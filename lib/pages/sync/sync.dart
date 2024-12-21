import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class SyncPage extends StatefulWidget {
  const SyncPage({super.key});

  @override
  State<SyncPage> createState() => _SyncPageState();
}

class _SyncPageState extends State<SyncPage> {
  final TextEditingController _controller = TextEditingController();

  void syncCalendar() {
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
        Navigator.of(context).pop();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const RunshawAppBar(title: "Calendar Sync"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Sync your calendar with Runshaw's timetable to share it with your friends. To set up:",
                style: GoogleFonts.rubik(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 4),
            // step by step list
            const Text("1. Log in to your student portal"),
            const Text(
                "2. In the menu, click on 'Timetable' then 'My Calendar'"),
            const Text(
                '3. Copy the link at the bottom using the button next to it'),
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
          ],
        ),
      ),
    );
  }
}
