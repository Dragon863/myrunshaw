import 'package:flutter/material.dart';
import 'package:runshaw/pages/login/emailpage.dart';
import 'package:runshaw/pages/scan/scan.dart';

class StageOneLogin extends StatelessWidget {
  const StageOneLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            children: [
              const Spacer(),
              Image.asset(
                'assets/img/student_id.png',
                height: 380,
              ),
              const SizedBox(height: 20),
              const Text(
                "Please prepare to scan the QR code on your Student ID Card",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: "Rubik",
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              FloatingActionButton.extended(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ScanPage(),
                    ),
                  );
                },
                label: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Next"),
                    SizedBox(width: 5),
                    Icon(Icons.keyboard_arrow_right)
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => EmailPage(),
                      ),
                    );
                  },
                  child: const Text("Or Use Email")),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
