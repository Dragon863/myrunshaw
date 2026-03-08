import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/technician/technician.dart';
import 'package:runshaw/pages/main/subpages/buses/buses.dart';
import 'package:runshaw/pages/main/subpages/friends/list/friends.dart';
import 'package:runshaw/pages/main/subpages/home/home.dart';
import 'package:runshaw/pages/main/subpages/map/map.dart';
import 'package:runshaw/pages/main/subpages/pay/pay.dart';
import 'package:runshaw/pages/main/subpages/settings/settings.dart';
import 'package:runshaw/pages/main/subpages/timetable/timetable.dart';
import 'package:runshaw/utils/api.dart';

List<Widget> getPages(bool showNotifs) {
  return [
    const Center(child: HomePage()),
    const Center(child: BusesPage()),
    const FriendsPage(),
    const TimetablePage(),
    const RunshawPayPage(),
    const MapPage(),
    const Center(child: SettingsPage()),
    const Center(child: TechnicianPage()),
  ];
}

Future<void> logOut(BuildContext context) async {
  final api = context.read<BaseAPI>();
  await api.signOut();
  Navigator.of(context).pushNamedAndRemoveUntil('/splash', (route) => false);
}
