import 'package:flutter/material.dart';
import 'package:runshaw/pages/main/subpages/buses/buses.dart';
import 'package:runshaw/pages/main/subpages/friends/list/friends.dart';
import 'package:runshaw/pages/main/subpages/home/home.dart';
import 'package:runshaw/pages/main/subpages/map/map.dart';
import 'package:runshaw/pages/main/subpages/settings/settings.dart';
import 'package:runshaw/pages/main/subpages/timetable/timetable.dart';
// import 'package:grace/src/pages/main/subpages/notifications/notifications.dart';
import 'main_controller.dart';

List<Widget> getPages(bool showNotifs) {
  return [
    const Center(child: HomePage()),
    const Center(child: BusesPage()),
    const FriendsPage(),
    const TimetablePage(),
    const MapPage(),
    const Center(child: SettingsPage()),
  ];
}

class SliderView extends StatefulWidget {
  final Function(String, int)? onItemClick;
  final int currentIndex;
  final String notification;
  final bool showNotifs;

  const SliderView({
    super.key,
    this.onItemClick,
    required this.currentIndex,
    required this.notification,
    required this.showNotifs,
  });

  @override
  State<SliderView> createState() => _SliderViewState();
}

class _SliderViewState extends State<SliderView> {
  int counter = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.withOpacity(0.3)),
        ),
        color: Colors.white,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const ScrollPhysics(),
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      if (counter < 20) {
                        counter++;
                      } else {
                        counter = 0;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Stop pressing me!'),
                          ),
                        );
                      }
                    },
                    child: const CircleAvatar(
                      radius: 72,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 70,
                        backgroundImage:
                            AssetImage('assets/img/logo-muted.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ...[
                    Menu(
                        const Icon(
                          Icons.home_outlined,
                          color: Colors.black,
                        ),
                        'Home'),
                    Menu(
                        const Icon(
                          Icons.directions_bus_outlined,
                          color: Colors.black,
                        ),
                        'Buses'),
                    Menu(
                        const Icon(
                          Icons.people_alt_outlined,
                          color: Colors.black,
                        ),
                        'Friends${widget.notification}'),
                    Menu(
                        const Icon(
                          Icons.calendar_month_outlined,
                          color: Colors.black,
                        ),
                        'Timetable'),
                    Menu(
                        const Icon(
                          Icons.map_outlined,
                          color: Colors.black,
                        ),
                        'Map'),
                    Menu(
                        const Icon(
                          Icons.settings_outlined,
                          color: Colors.black,
                        ),
                        'Settings'),
                  ].asMap().entries.map((entry) => _SliderMenuItem(
                        title: entry.value.title,
                        iconData: entry.value.iconData,
                        onTap: widget.onItemClick,
                        index: entry.key,
                        currentIndex: widget.currentIndex,
                      )),
                ],
              ),
            ),
            ListTile(
              onTap: () async {
                await logOut(context);
              },
              title: const Text('Log Out', style: TextStyle(color: Colors.red)),
              leading: const Icon(Icons.logout, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderMenuItem extends StatelessWidget {
  final String title;
  final Widget iconData;
  final Function(String, int)? onTap;
  final int index;
  final int currentIndex;

  const _SliderMenuItem(
      {required this.title,
      required this.iconData,
      required this.onTap,
      required this.index,
      required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: index == currentIndex
            ? const Color.fromARGB(255, 255, 209, 209)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.black)),
        leading: iconData,
        onTap: () => onTap?.call(title, index),
      ),
    );
  }
}

class Menu {
  final Widget iconData;
  final String title;

  Menu(this.iconData, this.title);
}
