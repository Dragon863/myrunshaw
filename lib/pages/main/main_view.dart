import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:gaimon/gaimon.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/slider/slider_view.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:runshaw/utils/notifications/notification_service.dart';
import 'main_helpers.dart';

class MainPage extends StatefulWidget {
  final String? nextRoute;
  final NotificationDestination? notificationDestination;
  const MainPage({super.key, this.nextRoute, this.notificationDestination});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final GlobalKey<SliderDrawerState> _sliderDrawerKey =
      GlobalKey<SliderDrawerState>();

  // Replaces _currentIndex and title
  AppDestination _currentDest = AppDestination.home;

  String notification = "";
  bool showNotifs = true;
  bool isDraggable = false;

  @override
  void initState() {
    super.initState();
    loadNotifications();
    _updateDraggable();
    nextRoute();
    _openNotificationDestination();
  }

  void _updateDraggable() {
    // Avoids Platform exception crash on Web
    if (kIsWeb) {
      isDraggable = false;
      return;
    }
    isDraggable = Platform.isIOS && !_currentDest.disableDrag;
  }

  void nextRoute() {
    if (widget.nextRoute != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          switch (widget.nextRoute) {
            case "/bus":
              _currentDest = AppDestination.buses;
            case "/friends":
              _currentDest = AppDestination.friends;
            case "/pay":
              _currentDest = AppDestination.pay;
            default:
              _currentDest = AppDestination.home;
          }
          _updateDraggable();
        });
      });
    }
  }

  void _openNotificationDestination() {
    final destination = widget.notificationDestination;
    if (destination == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        switch (destination.section) {
          case 'bus':
            _currentDest = AppDestination.buses;
          case 'friends':
            _currentDest = AppDestination.friends;
          case 'pay':
            _currentDest = AppDestination.pay;
          default:
            _currentDest = AppDestination.home;
        }
        _updateDraggable();
      });
    });
  }

  Future<void> loadNotifications() async {
    final api = context.read<BaseAPI>();
    final response = await api.getFriendRequests();
    if (!mounted) return;
    setState(() {
      notification = response.isNotEmpty ? " (${response.length})" : "";
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final backgroundColor = themeProvider.isLightMode
        ? Colors.red
        : (themeProvider.amoledEnabled
            ? Colors.black
            : Theme.of(context).colorScheme.surface);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness:
            themeProvider.isLightMode ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              SliderDrawer(
                key: _sliderDrawerKey,
                sliderOpenSize: 200,
                isDraggable: isDraggable,
                slider: SliderView(
                  currentDest: _currentDest,
                  notification: notification,
                  showNotifs: showNotifs,
                  onItemClick: (destination) async {
                    if (!kIsWeb && !Platform.isLinux) {
                      if (await Gaimon.canSupportsHaptic) Gaimon.selection();
                    }
                    _sliderDrawerKey.currentState?.closeSlider();
                    setState(() {
                      _currentDest = destination;
                      _updateDraggable();
                    });
                    await loadNotifications();
                  },
                ),
                appBar: _currentDest.hideAppBar
                    ? const SizedBox.shrink()
                    : SliderAppBar(
                        config: SliderAppBarConfig(
                          title: Text(
                            _currentDest.getTitle(notification),
                            style: GoogleFonts.rubik(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          backgroundColor: backgroundColor,
                          padding: const EdgeInsets.only(top: 4),
                          drawerIconColor: Colors.white,
                        ),
                      ),
                child: _currentDest.page,
              ),
              Visibility(
                visible: _currentDest
                    .hideAppBar, // Menu button handled automatically!
                child: Positioned(
                  top: 16,
                  left: 16,
                  child: FloatingActionButton(
                    heroTag: "menubtn",
                    mini: true,
                    shape: const CircleBorder(),
                    onPressed: () => _sliderDrawerKey.currentState?.toggle(),
                    child: const Icon(Icons.menu),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
