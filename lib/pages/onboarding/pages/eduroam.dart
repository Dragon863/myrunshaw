import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/wifi/wifi_profile_service.dart';

class OnBoardingEduroamStage extends StatefulWidget
    implements OnboardingStage, FeatureFlaggedOnboardingStage {
  const OnBoardingEduroamStage({super.key});

  @override
  State<OnBoardingEduroamStage> createState() => _OnBoardingEduroamStageState();

  static final GlobalKey<_OnBoardingEduroamStageState> _stateKey = GlobalKey();

  @override
  String get featureFlagId => 'eduroam_disabled';

  @override
  bool get featureFlagEnabledValue => false;

  @override
  Future<bool> onLeaveStage() async {
    return true; // static stage
  }

  @override
  Key? get key => _stateKey;
}

class _OnBoardingEduroamStageState extends State<OnBoardingEduroamStage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 250,
              ),
              child: Image.asset('assets/img/onboarding/eduroam-graphic.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "College Wi-Fi",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Set up eduroam on your phone below to use the free Wi-Fi while you're in college",
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 15),
                      children: [
                        TextSpan(text: 'You’ll be prompted to enter your '),
                        TextSpan(
                          text: 'Microsoft account password. ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: 'This is not stored by the app.'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            onPressed: () async {
              final BaseAPI api = context.read<BaseAPI>();
              final String? email = await api.currentUser?.email;
              if (email == null) {
                // should be impossible, but just in case
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Couldn't get your email address"),
                  ),
                );
                return;
              }
              final pw = await promptForNetworkPassword(context, email);
              if (pw != null && pw.isNotEmpty) {
                try {
                  await WifiProfileService()
                      .configure(username: email, password: pw);
                } on WifiProfileException catch (e) {
                  if (!e.cancelled) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          "Failed to configure Wi-Fi profile: ${e.message}",
                        ),
                      ),
                    );
                  }
                }
              }
            },
            label: const Text("Add Wi-Fi"),
            icon: const Icon(Icons.phonelink_setup),
          ),
        ],
      ),
    );
  }
}
