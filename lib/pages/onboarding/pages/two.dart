import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';

class OnBoardingStageTwo extends StatefulWidget implements OnboardingStage {
  const OnBoardingStageTwo({super.key});

  @override
  State<OnBoardingStageTwo> createState() => _OnBoardingStageTwoState();

  static final GlobalKey<_OnBoardingStageTwoState> _stateKey = GlobalKey();

  @override
  Key? get key => _stateKey;

  @override
  Future<bool> onLeaveStage() async {
    final state = _stateKey.currentState;
    if (state != null) {
      final name = state.controller.text;
      if (name != "") {
        await state.saveName(name);
        return true;
      } else {
        return false;
      }
    }
    return true;
  }
}

class _OnBoardingStageTwoState extends State<OnBoardingStageTwo> {
  final TextEditingController controller = TextEditingController();

  Future<void> fetchPrefs() async {
    final BaseAPI api = context.read<BaseAPI>();
    final latestUserModel = api.currentUser;
    final String displayName = latestUserModel?.name ?? '';

    setState(() {
      if (displayName.isNotEmpty) {
        controller.text = displayName;
      }
    });
  }

  Future<void> saveName(String name) async {
    final api = context.read<BaseAPI>();
    bool fail = false;
    // if (api.account == null) {
    //   fail = true;
    // }

    try {
      final response = await api.apiPost(
        '/api/users/me/name',
        body: {'new_name': name},
      );
      if (response.statusCode != 200) {
        debugLog("Error saving name: ${response.body}", level: 3);
        fail = true;
      }
      fail = false;
    } catch (e) {
      debugLog("Error saving name: $e", level: 3);
      fail = true;
    }
    if (fail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't save name, please try again later"),
        ),
      );
    }
  }

  @override
  void initState() {
    fetchPrefs();
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
              child:
                  Image.asset('assets/img/onboarding/displayname-graphic.png'),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Display Name",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "We'll use this to identify you to your friends. Using your first and last name is a good option",
            style: GoogleFonts.rubik(
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            autofillHints: const [AutofillHints.name],
            controller: controller,
            decoration: InputDecoration(
              hintText: "Display Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
