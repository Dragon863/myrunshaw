import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';

class SettingsAccountSection extends StatelessWidget {
  const SettingsAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text(
        "Manage Account",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          title: const Text("Change Password"),
          onTap: () => Navigator.of(context).pushNamed("/change_password"),
          trailing: const Icon(Icons.password),
        ),
        ListTile(
          title: const Text("Close Account"),
          trailing: const Icon(Icons.no_accounts),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Close Account"),
                content: const Text(
                  "Are you sure you want to close your account? All data will be irreversibly deleted!",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () async {
                      final api = context.read<BaseAPI>();
                      try {
                        await api.closeAccount();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            "/splash",
                            (route) => false,
                          );
                        }
                      } catch (e) {
                        debugLog("Error closing account: $e", level: 3);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error closing account: $e"),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
