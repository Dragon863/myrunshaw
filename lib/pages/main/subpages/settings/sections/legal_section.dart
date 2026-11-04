import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';

class SettingsLegalSection extends StatelessWidget {
  const SettingsLegalSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: const Icon(Icons.gavel),
      title: const Text(
        "Legal",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          onTap: () => context.push("/privacy_policy"),
          title: const Text("Privacy Policy"),
          trailing: const Icon(Icons.privacy_tip_outlined),
        ),
        ListTile(
          onTap: () => context.push("/terms"),
          title: const Text("Terms of Use"),
          trailing: const Icon(Icons.gavel),
        ),
        ListTile(
          onTap: () => context.push("/about"),
          title: const Text("About"),
          trailing: const Icon(Icons.info_outline),
        ),
      ],
    );
  }
}
