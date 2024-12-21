import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';

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
    final models.User? latestUserModel = await api.account?.get();
    final String displayName = latestUserModel!.name;

    setState(() {
      if (displayName.isNotEmpty) {
        controller.text = displayName;
      }
    });
  }

  Future<void> saveName(String name) async {
    final api = context.read<BaseAPI>();
    bool fail = false;
    if (api.account == null) {
      fail = true;
    }

    try {
      await api.account!.updateName(name: name);
      fail = false;
    } catch (e) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Let's Begin!",
            style: GoogleFonts.rubik(
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Full Name",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text("(We'll use this as your display name to show to friends)")
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
