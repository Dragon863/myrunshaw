import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/login/emailpage.dart';
import 'package:runshaw/pages/scan/scan.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class StageOneLogin extends StatelessWidget {
  const StageOneLogin({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0, left: 8.0, right: 8.0),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                minWidth: 150,
                maxWidth: 700,
                minHeight: MediaQuery.of(context).size.height,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/img/student_id.png',
                  ),
                  const Text(
                    "Please prepare to scan the QR code on your Student ID Card",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Rubik",
                    ),
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton.extended(
                    backgroundColor: context.read<ThemeProvider>().isDarkMode
                        ? Colors.red
                        : null,
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
                          builder: (context) => const EmailPage(),
                        ),
                      );
                    },
                    child: Text("Or Use Email",
                        style: TextStyle(
                          color: context.read<ThemeProvider>().isDarkMode
                              ? Colors.white
                              : null,
                        )),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
