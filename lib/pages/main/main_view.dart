import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'main_helpers.dart';

class MainPage extends StatefulWidget {
  final String? nextRoute;
  const MainPage({super.key, this.nextRoute});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<SliderDrawerState> _sliderDrawerKey =
      GlobalKey<SliderDrawerState>();
  String title = "Home";
  int _currentIndex = 0;
  String notification = "";
  bool showNotifs = true;
  bool isDraggable = false;

  @override
  void initState() {
    loadNotifications();
    try {
      isDraggable = Platform.isIOS;
    } catch (e) {
      isDraggable = false;
    }
    super.initState();
    nextRoute();
  }

  void nextRoute() {
    if (widget.nextRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          if (widget.nextRoute == "/bus") {
            _currentIndex = 1;
            title = "Buses";
          } else if (widget.nextRoute == "/friends") {
            _currentIndex = 2;
            title = "Friends";
          } else {
            _currentIndex = 0;
          }
        });
      });
    }
  }

  Future<void> loadNotifications() async {
    // Load notifications from API
    final api = context.read<BaseAPI>();
    final response = await api.getFriendRequests();
    if (response.isNotEmpty) {
      setState(() {
        notification = " (${response.length.toString()})";
      });
    } else {
      setState(() {
        notification = "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.read<ThemeProvider>().isLightMode
          ? Colors.red
          : (Theme.of(context).colorScheme.surface),
      child: SafeArea(
        child: Scaffold(
          body: SliderDrawer(
            key: _sliderDrawerKey,
            sliderOpenSize: 200,
            isDraggable: isDraggable,
            slider: SliderView(
                currentIndex: _currentIndex,
                notification: notification,
                showNotifs: showNotifs,
                onItemClick: (title, index) async {
                  _sliderDrawerKey.currentState!.closeSlider();
                  setState(() {
                    this.title = title;
                    _currentIndex = index;
                  });
                  await loadNotifications();
                }),
            appBar: SliderAppBar(
              config: SliderAppBarConfig(
                title: Text(
                  title,
                  style: GoogleFonts.rubik(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                backgroundColor: context.read<ThemeProvider>().isLightMode
                  ? Colors.red
                  : (context.read<ThemeProvider>().amoledEnabled ? const Color(0xFF1E1E1E) : Theme.of(context).colorScheme.surface),
                padding: const EdgeInsets.only(top: 4),
                drawerIconColor: Colors.white,
              ),
            ),
            child: getPages(showNotifs)[_currentIndex],
          ),
        ),
      ),
    );
  }
}
