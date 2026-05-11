/* Popup page that appears when the Wi-Fi speed survey is initiated */
import 'package:flutter/material.dart';
import 'package:runshaw/pages/wifisurvey/pages/one.dart';
import 'package:runshaw/pages/wifisurvey/pages/three.dart';
import 'package:runshaw/pages/wifisurvey/pages/two.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class WifiSurveyPage extends StatefulWidget {
  const WifiSurveyPage({super.key});

  @override
  State<WifiSurveyPage> createState() => _WifiSurveyPageState();
}

class _WifiSurveyPageState extends State<WifiSurveyPage> {
  int _currentPage = 0;

  final PageController _pageController = PageController();
  bool _permissionsGranted = false;
  bool _didCompleteTest = false;

  @override
  void initState() {
    super.initState();
    // Check current permission state so FAB can reflect it immediately
    Permission.location.status.then((status) {
      if (mounted) {
        setState(() => _permissionsGranted = status.isGranted);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(title: "Wi-Fi Speed Survey"),
      body: SafeArea(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 1000,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 8,
                child: PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 3,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return const WifiSurveyStageOne();
                      case 1:
                        return WifiSurveyStageTwo(
                          onPermissionGranted: (granted) {
                            setState(() => _permissionsGranted = granted);
                          },
                        );
                      case 2:
                        return WifiSurveyStageThree(
                          onComplete: (result) {
                            setState(() {
                              _didCompleteTest = true;
                            });
                          },
                        );
                      default:
                        return const SizedBox.shrink();
                    }
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: List.generate(3, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: isActive ? 24 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive ? Colors.red : Colors.grey,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final int lastIndex = 2;
          if (_currentPage < lastIndex) {
            // Block advancing from permissions page until granted
            if (_currentPage == 1 && !_permissionsGranted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please grant permissions to continue.'),
                ),
              );
              return;
            }
            setState(() => _currentPage++);
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } else {
            if (_currentPage == 2 && !_didCompleteTest) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Please complete the test before finishing.')),
              );
              return;
            }
            Navigator.pop(context, _didCompleteTest);
          }
        },
        child: const Icon(Icons.keyboard_arrow_right),
      ),
    );
  }
}
