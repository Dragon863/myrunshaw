import 'package:flutter/material.dart';

class SettingsLegalSection extends StatelessWidget {
  const SettingsLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        "Legal",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          onTap: () => Navigator.of(context).pushNamed("/privacy_policy"),
          title: const Text("Privacy Policy"),
          trailing: const Icon(Icons.privacy_tip_outlined),
        ),
        ListTile(
          onTap: () => Navigator.of(context).pushNamed("/terms"),
          title: const Text("Terms of Use"),
          trailing: const Icon(Icons.gavel),
        ),
        ListTile(
          onTap: () => Navigator.of(context).pushNamed("/about"),
          title: const Text("About"),
          trailing: const Icon(Icons.info_outline),
        ),
      ],
    );
  }
}
