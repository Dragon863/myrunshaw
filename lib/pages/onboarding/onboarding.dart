import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/pages/five.dart';
import 'package:runshaw/pages/onboarding/pages/four.dart';
import 'package:runshaw/pages/onboarding/pages/one.dart';
import 'package:runshaw/pages/onboarding/pages/three.dart';
import 'package:runshaw/pages/onboarding/pages/two.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

abstract class OnboardingStage {
  Future<bool> onLeaveStage();
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  Widget fabIcon = const Icon(Icons.keyboard_arrow_right, color: Colors.white);
  int _currentPage = 0;

  final PageController _pageController = PageController();

  final List<Widget> contents = [
    const OnBoardingStageOne(),
    const OnBoardingStageTwo(),
    const OnBoardingStageThree(),
    const OnBoardingStageFour(),
    const OnBoardingStageFive(),
  ];

  Future<bool> handlePageTransition() async {
    if (contents[_currentPage] is OnboardingStage) {
      final onboardingStage = contents[_currentPage] as OnboardingStage;
      setState(() {
        fabIcon = SizedBox(
            width: 28,
            height: 28,
            child: LoadingIndicator(activeIndicatorColor: Colors.white));
      });
      final bool canContinue = await onboardingStage.onLeaveStage();
      if (!canContinue) {
        setState(() {
          fabIcon = Icon(
              _currentPage == contents.length - 1
                  ? Icons.check
                  : Icons.keyboard_arrow_right,
              color: Colors.white);
        });
        return false;
      }
      setState(() {
        fabIcon = const Icon(Icons.keyboard_arrow_right, color: Colors.white);
      });
    }
    if (_currentPage == contents.length - 2) {
      setState(() {
        fabIcon = const Icon(Icons.check, color: Colors.white);
      });
    }
    return true;
  }

  Future<void> goToNextPage() async {
    final bool canContinue = await handlePageTransition();
    if (_currentPage < contents.length - 1 && canContinue) {
      setState(() {
        _currentPage++;
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    } else if (_currentPage == contents.length - 1 && canContinue) {
      final api = context.read<BaseAPI>();
      await api.onboardComplete();
      Navigator.pushReplacementNamed(context, '/splash');
    }
    if (!canContinue) {
      if (_currentPage == contents.length - 2) {
        // timetable stage
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Warning!",
                style: GoogleFonts.rubik(fontWeight: FontWeight.bold)),
            content: const Text(
                "You haven't provided your timetable. \nSharing your timetable is a key feature of this app and enables RunshawPay support - if possible, please consider adding it! \nAre you sure you want to skip this step?"),
            actions: [
              TextButton(
                onPressed: () async {
                  final api = context.read<BaseAPI>();
                  await api.onboardComplete();
                  await Posthog().capture(
                    eventName: 'onboarding-timetable-skip',
                  );
                  Navigator.pushReplacementNamed(context, '/splash');
                },
                child: const Text("Yes"),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("No"),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please complete the required fields"),
          ),
        );
      }
    }
  }

  Future<void> goToPreviousPage() async {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
        fabIcon = const Icon(Icons.keyboard_arrow_right, color: Colors.white);
      });
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    }
  }

  @override
  void initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 1000,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // actual content
                Expanded(
                  flex: 8,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: contents.length,
                    itemBuilder: (context, index) {
                      return contents[index];
                    },
                  ),
                ),
                // progress indicator dots
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: List.generate(contents.length, (index) {
                        final isActive = _currentPage == index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 3.0),
                          width: isActive ? 30 : 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.red : Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "back",
            onPressed: goToPreviousPage,
            mini: true,
            elevation: 0,
            child: const Icon(Icons.keyboard_arrow_left, color: Colors.black),
          ),
          const SizedBox(width: 8),
          FloatingActionButton(
            heroTag: "forward",
            backgroundColor: Colors.red,
            onPressed: goToNextPage,
            child: fabIcon,
          ),
        ],
      ),
    );
  }
}
