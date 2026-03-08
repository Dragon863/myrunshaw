import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/main_helpers.dart';
import 'package:runshaw/pages/main/slider/slider_widgets.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool isDeveloper = false;

  @override
  void initState() {
    super.initState();
    loadDeveloperState();
  }

  Future<void> loadDeveloperState() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      isDeveloper = prefs.getBool('isDeveloper') ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: Colors.grey.withValues(alpha: .3)),
        ),
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Theme(
          data: Theme.of(context).copyWith(
              iconTheme: IconThemeData(
            color: context.read<ThemeProvider>().isLightMode
                ? Colors.black
                : Colors.white,
          )),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  physics: const ScrollPhysics(),
                  children: <Widget>[
                    GestureDetector(
                      onTap: () async {
                        if (counter < 10) {
                          counter++;
                        } else {
                          // check with appwrite first
                          final BaseAPI api = context.read<BaseAPI>();
                          final isAdmin = await api.isAdmin();
                          if (isAdmin) {
                            final SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            prefs.setBool('isDeveloper', true);
                            loadDeveloperState();
                            setState(() {});

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Developer mode enabled!"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("You are not an admin."),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        }
                      },
                      child: CircleAvatar(
                        radius: 72,
                        backgroundColor:
                            Theme.of(context).scaffoldBackgroundColor,
                        child: const CircleAvatar(
                          radius: 70,
                          backgroundImage: AssetImage(
                            'assets/img/logo-muted.png',
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...[
                      Menu(
                        Icons.home_outlined,
                        Icons.home,
                        'Home',
                      ),
                      Menu(
                        Icons.directions_bus_outlined,
                        Icons.directions_bus,
                        'Buses',
                      ),
                      Menu(
                        Icons.people_alt_outlined,
                        Icons.people_alt,
                        'Friends${widget.notification}',
                      ),
                      Menu(
                        Icons.calendar_month_outlined,
                        Icons.calendar_month,
                        'Timetable',
                      ),
                      Menu(
                        Icons.payments_outlined,
                        Icons.payments,
                        'Pay',
                        isBeta: false, // no more beta!
                      ),
                      Menu(
                        Icons.map_outlined,
                        Icons.map,
                        'Map',
                      ),
                      Menu(
                        Icons.settings_outlined,
                        Icons.settings,
                        'Settings',
                      ),
                      if (isDeveloper)
                        Menu(
                          Icons.engineering_outlined,
                          Icons.engineering,
                          'Technician',
                        )
                    ].asMap().entries.map(
                          (entry) => SliderMenuItem(
                            title: entry.value.title,
                            inactiveIcon: entry.value.inactiveIcon,
                            activeIcon: entry.value.activeIcon,
                            onTap: widget.onItemClick,
                            index: entry.key,
                            currentIndex: widget.currentIndex,
                            isBeta: entry.value.isBeta,
                          ),
                        ),
                  ],
                ),
              ),
              ListTile(
                onTap: () async {
                  await logOut(context);
                },
                title: const Text(
                  'Log Out',
                  style: TextStyle(color: Colors.red),
                ),
                leading: const Icon(Icons.logout, color: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
