import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:runshaw/pages/main/subpages/settings/add_buses.dart';

class SettingsBusesSection extends StatelessWidget {
  final bool showNotifs;
  final void Function(bool) onShowNotifsChanged;

  const SettingsBusesSection({
    super.key,
    required this.showNotifs,
    required this.onShowNotifsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        "Buses",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          title: const Text(
            "Bus Notifications",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: Switch(
            value: showNotifs,
            onChanged: (value) {
              onShowNotifsChanged(value);
              OneSignal.User.addTagWithKey("bus_optout", !value);
            },
          ),
        ),
        ListTile(
          title: const Text(
            "Add Your Buses",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          subtitle: const Text("For notifications and tracking"),
          trailing: const Icon(Icons.keyboard_arrow_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ExtraBusPage(),
            ),
          ),
        ),
      ],
    );
  }
}
