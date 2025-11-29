import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';

import 'package:runshaw/utils/theme/appbar.dart';

class PasswordResetLoginPage extends StatefulWidget {
  const PasswordResetLoginPage({super.key});

  @override
  State<PasswordResetLoginPage> createState() => _PasswordResetLoginPageState();
}

class _PasswordResetLoginPageState extends State<PasswordResetLoginPage> {
  final TextEditingController _studentIDController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  bool validateStudentID() {
    final String email = _studentIDController.text;
    final RegExp emailRegex = RegExp(r'^[a-zA-Z]{3}\d{8}$');
    if (!emailRegex.hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid Student ID"),
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> buttonPressed() async {
    final api = context.read<BaseAPI>();
    if (!validateStudentID()) {
      return;
    }
    try {
      await api.account!.createRecovery(
        email: "${_studentIDController.text}${MyRunshawConfig.emailExtension}",
        url: "https://myrunshaw.danieldb.uk/reset",
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "An email has been sent to your college email address with instructions to reset your password."),
        ),
      );
      Navigator.pop(context);
    } on AppwriteException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(e.message ?? "An error occurred whilst resetting password"),
        ),
      );
      return;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst resetting password: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(title: "Reset Password"),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Container(
            constraints: BoxConstraints(
              minWidth: 150,
              maxWidth: 400,
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  const Icon(
                    Icons.lock_reset,
                    size: 150,
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: const [
                        TextSpan(
                          text:
                              'To reset your password, please enter your Student ID below. An email will be sent to your college email address with instructions to reset your password.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _studentIDController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Student ID',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      onPressed: buttonPressed,
                      child: const Text("Reset"),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
