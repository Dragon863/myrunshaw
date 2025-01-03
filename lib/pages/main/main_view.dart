import 'package:flutter/material.dart';
import 'package:flutter_slider_drawer/flutter_slider_drawer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'main_helpers.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

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

  @override
  void initState() {
    loadNotifications();
    super.initState();
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
      color: Colors.red,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SliderDrawer(
            key: _sliderDrawerKey,
            sliderOpenSize: 200,
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
              appBarHeight: 50,
              appBarColor: Colors.red, //const Color.fromARGB(255, 230, 51, 18),
              appBarPadding: const EdgeInsets.only(top: 4),
              drawerIconColor: Colors.white,
              title: Text(
                title,
                style: GoogleFonts.rubik(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            child: getPages(showNotifs)[_currentIndex],
          ),
        ),
      ),
    );
  }
}
