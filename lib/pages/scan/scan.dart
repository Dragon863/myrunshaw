import 'dart:async';

import 'package:appwrite/appwrite.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/main.dart';
import 'package:runshaw/pages/login/password_reset_login.dart';
import 'package:runshaw/pages/scan/controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  Barcode? _barcode;
  bool inProgress = false;

  void navigateToSplash() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const BaseApp(),
      ),
      (r) => false,
    );
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Please scan your Student ID Badge!',
        overflow: TextOverflow.fade,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      );
    }

    if (validate(value.displayValue ?? "")) {
      String studentId = value.displayValue!;
      return Wrap(
        children: [
          Text(
            studentId,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      );
    } else {
      return const Wrap(
        children: [
          Text(
            "Invalid Badge Code",
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      );
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
    final bool valid = validate(_barcode?.displayValue ?? "");

    if (valid) {
      String studentId = _barcode!.displayValue!;
      await maybeLogin(studentId);
    }
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
    )) {
      throw Exception('Could not launch url');
    }
  }

  Future<void> maybeLogin(String studentID) async {
    if (inProgress) {
      return;
    }

    setState(() {
      inProgress = true;
    });

    final api = context.read<BaseAPI>();
    bool exists;

    try {
      exists = await api.userExists(studentID.split("-")[0]);
    } catch (e) {
      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Error"),
            content: Text(
                "Error: could not reach My Runshaw servers. Try again later.: $e"),
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
      return;
    }

    final TextEditingController controllerPwd = TextEditingController();
    final TextEditingController controllerPwdConfirm = TextEditingController();

    String password;

    await showModalBottomSheet(
      context: context,
      builder: (context) {
        return BottomSheet(
          onClosing: () {},
          builder: (context) {
            bool showFieldOneText = false;
            bool showFieldTwoText = false;
            bool agreesToPolicies = false;

            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        exists ? "Log In" : "Sign Up",
                        style: GoogleFonts.rubik(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: controllerPwd,
                        obscureText: !showFieldOneText,
                        autocorrect: false,
                        autofocus: false,
                        decoration: InputDecoration(
                          labelText: "Password",
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                showFieldOneText = !showFieldOneText;
                              });
                            },
                            icon: Icon(
                              showFieldOneText
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                          ),
                        ),
                      ),
                      Visibility(
                        visible: !exists,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            TextField(
                              controller: controllerPwdConfirm,
                              obscureText: !showFieldTwoText,
                              autocorrect: false,
                              decoration: InputDecoration(
                                labelText: "Confirm Password",
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showFieldTwoText = !showFieldTwoText;
                                    });
                                  },
                                  icon: Icon(
                                    showFieldTwoText
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: !exists,
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Checkbox(
                                  value: agreesToPolicies,
                                  onChanged: (bool? value) {
                                    if (value != null) {
                                      setState(() {
                                        agreesToPolicies = !agreesToPolicies;
                                      });
                                    }
                                  },
                                ),
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      const TextSpan(
                                        text: 'I agree to the ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: 'Terms of Use',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            decoration:
                                                TextDecoration.underline),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.of(context).pushNamed(
                                              "/terms",
                                            );
                                          },
                                      ),
                                      const TextSpan(
                                        text: ' and ',
                                        style: TextStyle(color: Colors.black),
                                      ),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: const TextStyle(
                                            color: Colors.red,
                                            decoration:
                                                TextDecoration.underline),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            Navigator.of(context).pushNamed(
                                              "/privacy_policy",
                                            );
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: exists,
                        child: const SizedBox(height: 6),
                      ),
                      Visibility(
                        visible: exists,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("(or "),
                            InkWell(
                              child: const Text(
                                'reset password here',
                                style: TextStyle(color: Colors.red),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PasswordResetLoginPage(),
                                  ),
                                );
                              },
                            ),
                            const Text(")"),
                          ],
                        ),
                      ),
                      Visibility(
                        visible: exists,
                        child: const SizedBox(height: 6),
                      ),
                      Visibility(
                        visible: agreesToPolicies || exists,
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: FloatingActionButton(
                            onPressed: () async {
                              if (!exists) {
                                // New user; create account
                                if (controllerPwd.text ==
                                    controllerPwdConfirm.text) {
                                  if (controllerPwd.text.length >= 8) {
                                    password = controllerPwd.text;
                                    try {
                                      await api.createUser(
                                        email:
                                            "$studentID@student.runshaw.ac.uk",
                                        password: password,
                                      );
                                      navigateToSplash();
                                    } on AppwriteException catch (e) {
                                      await showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text("Error"),
                                          content: Text(e.message ??
                                              "Sorry, we ran into an unknown issue"),
                                          actions: [
                                            TextButton(
                                                onPressed: () {
                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Okay"))
                                          ],
                                        ),
                                      );
                                    }
                                  } else {
                                    await showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text("Error"),
                                        content: const Text(
                                            "Passwords must be at least 8 characters! This ensures the security of your account"),
                                        actions: [
                                          TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                              },
                                              child: const Text("Okay"))
                                        ],
                                      ),
                                    );
                                  }
                                } else {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Error"),
                                      content: const Text(
                                          "Passwords do not match! Try again, ensuring you typed the same in both boxes"),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Okay"))
                                      ],
                                    ),
                                  );
                                }
                              } else {
                                // User exists; login
                                password = controllerPwd.text;
                                try {
                                  await api.createEmailSession(
                                    email: "$studentID@student.runshaw.ac.uk",
                                    password: password,
                                  );
                                  navigateToSplash();
                                } on AppwriteException catch (e) {
                                  await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Error"),
                                      content: Text(e.message ??
                                          "Sorry, we ran into an unknown issue"),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text("Okay"))
                                      ],
                                    ),
                                  );
                                }
                              }
                            },
                            child: const Icon(Icons.keyboard_arrow_right),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
    setState(() {
      inProgress = false;
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(
        title: "Login",
        actions: [],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _buildBarcode(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
