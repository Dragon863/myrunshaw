import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/onboarding/pages/one.dart';
import 'package:runshaw/pages/onboarding/pages/three.dart';
import 'package:runshaw/pages/onboarding/pages/two.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class OnBoardingPage extends StatefulWidget {
  const OnBoardingPage({super.key});

  @override
  State<OnBoardingPage> createState() => _OnBoardingPageState();
}

class _OnBoardingPageState extends State<OnBoardingPage> {
  int _currentPage = 0;

  final PageController _pageController = PageController();

  final List<Widget> contents = [
    const OnBoardingStageOne(),
    const OnBoardingStageTwo(),
    const OnBoardingStageThree(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(title: "Introduction"),
      backgroundColor: Colors.white,
      body: Center(
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
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: contents.length,
                  itemBuilder: (context, index) {
                    return contents[index];
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
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
              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: () async {
          if (_currentPage < contents.length - 1) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeIn,
            );
          } else {
            final api = context.read<BaseAPI>();
            await api.onboardComplete();
            Navigator.pushNamed(context, '/splash');
          }
        },
        child: Icon(
          _currentPage < contents.length - 1
              ? Icons.keyboard_arrow_right
              : Icons.done,
          color: Colors.white,
        ),
      ),
    );
  }
}
