import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/login/widgets/buttons.dart';
import 'package:runshaw/pages/login/email/email.dart';
import 'package:runshaw/pages/login/widgets/divider.dart';
import 'package:runshaw/pages/scan/scan.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/featureflags/flagwidget.dart';

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
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 400, minWidth: 200),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: 24.0,
                        left: MediaQuery.of(context).size.width * 0.2,
                        right: MediaQuery.of(context).size.width * 0.2,
                      ),
                      child: Image.asset(
                        'assets/img/student_id.png',
                      ),
                    ),
                  ),
                  const Text(
                    "Scan Student ID",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: "Rubik",
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: const Text(
                      "Please use the camera to scan the QR code on your ID badge.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: "Rubik",
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    text: "Next",
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ScanPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  WordDivider(text: "or"),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    text: "Use Email",
                    icon: Icon(Icons.email_outlined, size: 20),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const EmailPage(),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 10),
                  FeatureFlagWidget(
                    flagName: 'entra-login',
                    child: SecondaryButton(
                      icon: Image.asset(
                        'assets/img/microsoft_logo.png',
                        height: 22,
                      ),
                      text: "Sign in with Microsoft",
                      onPressed: () async {
                        final BaseAPI api = context.read<BaseAPI>();
                        try {
                          await api.createOAuth2Session(
                            provider: OAuthProvider.microsoft,
                          );
                          await Posthog().capture(
                            eventName: 'oauth_login',
                          );
                          await Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SplashPage(),
                            ),
                            (r) => false,
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Error: $e")),
                          );
                          await Posthog().captureException(
                            error: e,
                            stackTrace: StackTrace.current,
                          );
                        }
                      },
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
