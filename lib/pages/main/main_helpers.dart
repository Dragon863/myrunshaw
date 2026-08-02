import 'package:flutter/material.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/buses.dart';
import 'package:runshaw/pages/main/subpages/friends/list/friends.dart';
import 'package:runshaw/pages/main/subpages/home/home.dart';
import 'package:runshaw/pages/main/subpages/map/map.dart';
import 'package:runshaw/pages/main/subpages/pay/pay.dart';
import 'package:runshaw/pages/main/subpages/settings/settings.dart';
import 'package:runshaw/pages/main/subpages/timetable/timetable.dart';
import 'package:runshaw/utils/api.dart';

enum AppDestination {
  home(
    baseTitle: 'Home',
    inactiveIcon: Icons.home_outlined,
    activeIcon: Icons.home,
  ),
  buses(
    baseTitle: 'Buses',
    inactiveIcon: Icons.directions_bus_outlined,
    activeIcon: Icons.directions_bus,
  ),
  friends(
    baseTitle: 'Friends',
    inactiveIcon: Icons.people_alt_outlined,
    activeIcon: Icons.people_alt,
  ),
  timetable(
    baseTitle: 'Timetable',
    inactiveIcon: Icons.calendar_month_outlined,
    activeIcon: Icons.calendar_month,
  ),
  pay(
    baseTitle: 'Pay',
    inactiveIcon: Icons.payments_outlined,
    activeIcon: Icons.payments,
  ),
  map(
    baseTitle: 'Map',
    inactiveIcon: Icons.map_outlined,
    activeIcon: Icons.map,
    hideAppBar: true,
    disableDrag: true, // Map uses gestures to pan and zoom
  ),
  settings(
    baseTitle: 'Settings',
    inactiveIcon: Icons.settings_outlined,
    activeIcon: Icons.settings,
  );

  final String baseTitle;
  final IconData inactiveIcon;
  final IconData activeIcon;
  final bool hideAppBar;
  final bool disableDrag;
  final bool isBeta;

  const AppDestination({
    required this.baseTitle,
    required this.inactiveIcon,
    required this.activeIcon,
    this.hideAppBar = false,
    this.disableDrag = false,
    this.isBeta = false,
  });

  // Returns the actual page widget
  Widget get page {
    return switch (this) {
      AppDestination.home => const Center(child: HomePage()),
      AppDestination.buses => const Center(child: BusesPage()),
      AppDestination.friends => const FriendsPage(),
      AppDestination.timetable => const TimetablePage(),
      AppDestination.pay => const RunshawPayPage(),
      AppDestination.map => const MapPage(),
      AppDestination.settings => const Center(child: SettingsPage()),
    };
  }

  // Appends notifications dynamically for Friends
  String getTitle(String notificationStr) {
    if (this == AppDestination.friends) {
      return '$baseTitle$notificationStr';
    }
    return baseTitle;
  }
}

Future<void> logOut(BuildContext context) async {
  final api = context.read<BaseAPI>();
  await api.signOut();
  await Posthog().reset();
  Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
}
