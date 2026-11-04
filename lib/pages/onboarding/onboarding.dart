import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/pages/eduroam.dart';
import 'package:runshaw/pages/onboarding/pages/runshawpay.dart';
import 'package:runshaw/pages/onboarding/pages/timetablesync.dart';
import 'package:runshaw/pages/onboarding/pages/welcome.dart';
import 'package:runshaw/pages/onboarding/pages/bus.dart';
import 'package:runshaw/pages/onboarding/pages/name.dart';
import 'package:runshaw/utils/api.dart';

abstract class OnboardingStage {
  Future<bool> onLeaveStage();
}

abstract class FeatureFlaggedOnboardingStage {
  /// PostHog flag that controls whether this stage is included in onboarding.
  String get featureFlagId;

  /// Whether the flag must be enabled for this stage to be included.
  /// Set to false for flags whose enabled state means the feature is disabled.
  bool get featureFlagEnabledValue => true;
}

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  int _currentPage = 0;
  bool _isTransitioning = false;

  final PageController _pageController = PageController();

  static const List<Widget> _allContents = [
    OnBoardingWelcomeStage(),
    OnBoardingNameStage(),
    OnBoardingBusStage(),
    OnBoardingTimetableSyncStage(),
    OnBoardingEduroamStage(),
    OnBoardingRunshawPayStage(),
  ];

  List<Widget> _contents = [];
  bool _loadingStages = true;

  @override
  void initState() {
    super.initState();
    _loadEnabledStages();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _loadEnabledStages() async {
    final enabledStages = <Widget>[];
    for (final stage in _allContents) {
      final flaggedStage = stage is FeatureFlaggedOnboardingStage
          ? stage as FeatureFlaggedOnboardingStage
          : null;
      if (flaggedStage == null) {
        enabledStages.add(stage);
        continue;
      }

      PostHogFeatureFlagResult? result;
      try {
        result =
            await Posthog().getFeatureFlagResult(flaggedStage.featureFlagId);
      } catch (_) {
        // An unavailable flag evaluates as disabled, matching a null result.
      }
      final isEnabled = result?.enabled ?? false;
      if (isEnabled == flaggedStage.featureFlagEnabledValue) {
        enabledStages.add(stage);
      }
    }

    if (!mounted) return;
    setState(() {
      _contents = enabledStages;
      _loadingStages = false;
    });
  }

  Future<bool> _canLeaveCurrentPage() async {
    final currentPage = _contents[_currentPage];
    if (currentPage is OnboardingStage) {
      return (currentPage as OnboardingStage).onLeaveStage();
    }
    return true;
  }

  Future<void> _goToNextPage() async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      final canContinue = await _canLeaveCurrentPage();
      if (!mounted) return;

      if (_currentPage < _contents.length - 1 && canContinue) {
        setState(() {
          _currentPage++;
        });
        await _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      } else if (_currentPage == _contents.length - 1 && canContinue) {
        final api = context.read<BaseAPI>();
        await api.onboardComplete();
        if (mounted) context.go('/splash');
      }
      if (!mounted) return;
      if (!canContinue) {
        if (_currentPage == _contents.length - 2) {
          // timetable stage
          showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text("Warning!",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: const Text(
                  "You haven't provided your timetable. \nSharing your timetable is a key feature of this app and enables RunshawPay support - if possible, please consider adding it! \nAre you sure you want to skip this step?"),
              actions: [
                TextButton(
                  onPressed: () => _skipTimetableAndContinue(context),
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
    } finally {
      _isTransitioning = false;
    }
  }

  Future<void> _skipTimetableAndContinue(BuildContext dialogContext) async {
    if (_isTransitioning) return;
    _isTransitioning = true;

    try {
      Navigator.pop(dialogContext);
      if (!mounted) return;

      setState(() {
        _currentPage++;
      });
      await _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
      await Posthog().capture(eventName: 'onboarding-timetable-skip');
    } finally {
      _isTransitioning = false;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingStages) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: GestureDetector(
        child: SafeArea(
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
                      itemCount: _contents.length,
                      itemBuilder: (context, index) {
                        return _contents[index];
                      },
                    ),
                  ),
                  // progress indicator dots and buttons
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: List.generate(_contents.length, (index) {
                              final isActive = _currentPage == index;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 3.0),
                                width: isActive ? 30 : 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.red
                                      : Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              );
                            }),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            onPressed: () {
                              if (_currentPage > 0) {
                                setState(() {
                                  _currentPage--;
                                });
                                _pageController.animateToPage(
                                  _currentPage,
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeIn,
                                );
                              }
                            },
                            icon: const Icon(Icons.keyboard_arrow_left),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: FilledButton.icon(
                            onPressed: _goToNextPage,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 16),
                            ),
                            label: Text(
                              _currentPage == _contents.length - 1
                                  ? "Done"
                                  : "Next",
                              style: TextStyle(
                                  color: ColorScheme.of(context).surface,
                                  fontWeight: FontWeight.w600),
                            ),
                            icon: Icon(
                              _currentPage == _contents.length - 1
                                  ? Icons.check
                                  : Icons.arrow_forward,
                              color: ColorScheme.of(context).surface,
                              fontWeight: FontWeight.w600,
                            ),
                            iconAlignment: IconAlignment.end,
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
