import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/login/widgets/buttons.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/utils/api.dart';

class WelcomeLoginPage extends StatefulWidget {
  const WelcomeLoginPage({super.key});

  @override
  State<WelcomeLoginPage> createState() => _WelcomeLoginPageState();
}

class _WelcomeLoginPageState extends State<WelcomeLoginPage> {
  int _logoTapCount = 0;

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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Spacer so the main content stays centred
                  const SizedBox.shrink(),

                  // Your existing centred content
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () {
                          // For App Store Review, a secret token is provided to bypass MS login. The secret is validated by the backend.
                          setState(() {
                            _logoTapCount++;
                          });
                          if (_logoTapCount == 5) {
                            _showBypassDialog();
                          }
                        },
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                              maxWidth: 500, minWidth: 350),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final screenWidth =
                                  MediaQuery.of(context).size.width;
                              final isDesktop = screenWidth >= 700;
                              final imageWidth = isDesktop
                                  ? (constraints.maxWidth * 0.6)
                                      .clamp(220.0, 320.0)
                                  : constraints.maxWidth * 0.6;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 24.0),
                                child: SizedBox(
                                  width: imageWidth,
                                  child: Image.asset(
                                    'assets/img/welcome-header.png',
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const Text(
                        "Welcome!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFamily: "Rubik",
                        ),
                      ),
                      const SizedBox(height: 5),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: const Text(
                          "Please use your college-issued Microsoft account to continue",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontFamily: "Rubik",
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      SecondaryButton(
                        icon: Image.asset(
                          'assets/img/microsoft_logo.png',
                          height: 22,
                        ),
                        text: "Sign in with Microsoft",
                        onPressed: () async {
                          final BaseAPI api = context.read<BaseAPI>();
                          try {
                            await api.loginWithMicrosoft();

                            await Posthog().capture(
                              eventName: 'oauth_login',
                            );
                            if (context.mounted) {
                              await Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SplashPage(),
                                ),
                                (r) => false,
                              );
                            }
                          } catch (e) {
                            if (e.toString().contains("cancelled")) {
                              return;
                            }
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error: $e")),
                              );
                            }
                            await Posthog().captureException(
                              error: e,
                              stackTrace: StackTrace.current,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                  SafeArea(
                    top: false, // let content go behind status bar
                    bottom: true, // only pad away from the gesture bar
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await Navigator.pushNamed(
                                  context, '/privacy_policy');
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Privacy Policy",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            "•",
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () async {
                              await Navigator.pushNamed(context, '/terms');
                            },
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Text(
                                "Terms of Use",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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

  void _showBypassDialog() async {
    final controller = TextEditingController();
    final BaseAPI api = context.read<BaseAPI>();

    bool success = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Reviewer Passcode"),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: "Passcode"),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context, false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await api.loginWithBypassSecret(controller.text);

                if (context.mounted) {
                  Navigator.pop(context, true); // pop dialog (not page)
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: $e")),
                  );
                }
                Navigator.pop(context, false);
              }
            },
            child: const Text("Submit"),
          )
        ],
      ),
    );
    _logoTapCount = 0;
    if (success && context.mounted) {
      await Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const SplashPage(),
        ),
        (r) => false,
      );
    }
  }
}
