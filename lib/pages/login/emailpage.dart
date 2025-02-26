import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/main.dart';
import 'package:runshaw/pages/login/password_reset_login.dart';
import 'package:runshaw/pages/main/main_view.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';

class EmailPage extends StatefulWidget {
  const EmailPage({super.key});

  @override
  State<EmailPage> createState() => _EmailPageState();
}

class _EmailPageState extends State<EmailPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    final BaseAPI api = context.read<BaseAPI>();
    api.addListener(() {
      if (api.status == AccountStatus.authenticated) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BaseApp(),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 500,
            ),
            child: AutofillGroup(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Nice to meet you!",
                    style: GoogleFonts.rubik(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  const Text("Let's get you logged in"),
                  Row(
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
                  const SizedBox(height: 20),
                  TextField(
                    autofillHints: const [
                      AutofillHints.email,
                      AutofillHints.username
                    ],
                    decoration: const InputDecoration(
                      labelText: 'College Email / Student ID',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    controller: emailController,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofillHints: const [AutofillHints.password],
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                    obscureText: true,
                    controller: passwordController,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () async {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("You can only sign up with a QR code"),
                        ),
                      );
                    },
                    child: const Text('Sign Up'),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        loading = true;
                      });
                      final BaseAPI api = context.read<BaseAPI>();

                      try {
                        await api.createEmailSession(
                          email: emailController.text,
                          password: passwordController.text,
                        );
                        TextInput.finishAutofillContext();
                        debugLog("Created email session");
                        setState(() {
                          loading = false;
                        });
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MainPage(),
                          ),
                          (r) => false,
                        );
                      } on AppwriteException catch (e) {
                        if (e.message != null) {
                          if (e.message!.contains("a session is active")) {
                            // Sometimes happens when something fails after logging in with appwrite but before redirecting
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please fully close the app and try again",
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.message ?? 'An error occurred'),
                              ),
                            );
                          }
                        }

                        setState(() {
                          loading = false;
                        });
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('An error occurred: ${e.toString()}'),
                          ),
                        );
                        setState(() {
                          loading = false;
                        });
                      }
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Sign In'),
                        loading
                            ? const SizedBox(width: 10)
                            : const SizedBox.shrink(),
                        loading
                            ? const SizedBox(
                                width: 12,
                                height: 12,
                                child:
                                    CircularProgressIndicator(strokeWidth: 3),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
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
