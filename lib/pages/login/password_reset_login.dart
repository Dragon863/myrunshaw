import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'dart:math';

import 'package:runshaw/utils/theme/appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class PasswordResetLoginPage extends StatefulWidget {
  const PasswordResetLoginPage({super.key});

  @override
  State<PasswordResetLoginPage> createState() => _PasswordResetLoginPageState();
}

class _PasswordResetLoginPageState extends State<PasswordResetLoginPage> {
  String code = 'loading...';
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _passwordController1 = TextEditingController();
  final TextEditingController _passwordController2 = TextEditingController();
  bool authenticated = false;
  String buttonText = 'Next';

  void generateCode() {
    // generate random 8 digit code
    final Random random = Random();
    code = '';
    for (int i = 0; i < 8; i++) {
      code += random.nextInt(10).toString();
    }
  }

  @override
  void initState() {
    generateCode();
    super.initState();
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(
      Uri.parse(url),
    )) {
      throw Exception('Could not launch url');
    }
  }

  bool checkPasswords() {
    if (_passwordController1.text != _passwordController2.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Passwords do not match"),
        ),
      );
      return false;
    }
    if (_passwordController1.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 8 characters long"),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> buttonPressed() async {
    if (authenticated) {
      final api = context.read<BaseAPI>();
      if (!checkPasswords()) {
        return;
      }
      try {
        final String response = await api.resetPasswordWithoutAuth(
          _studentIdController.text,
          code,
          _passwordController1.text,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response),
          ),
        );
        if (response == 'Password updated successfully') {
          Navigator.pop(context);
        } else {
          setState(() {
            authenticated = false;
            buttonText = 'Next';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("An error occurred whilst resetting password: $e"),
          ),
        );
      }
    } else {
      setState(() {
        authenticated = true;
        buttonText = 'Reset Password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(title: "Reset Password"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Please email the following 8 digit code to ',
                    ),
                    TextSpan(
                      text: 'reset@runshaw.dino.icu',
                      style: const TextStyle(color: Colors.red),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          _launchUrl('mailto:reset@runshaw.dino.icu');
                        },
                    ),
                    const TextSpan(
                      text:
                          ' from your college email (this is important!) to verify your identity first:',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: SelectableText(
                  code,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child:
                    Text("Press the 'Next' button when you've sent the email"),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _studentIdController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Student ID',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                enabled: authenticated,
                controller: _passwordController1,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'New Password',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                obscureText: true,
                enabled: authenticated,
                controller: _passwordController2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Confirm Password',
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: ElevatedButton(
                  onPressed: buttonPressed,
                  child: Text(buttonText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
