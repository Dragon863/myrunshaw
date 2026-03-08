import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SettingsThemeSection extends StatelessWidget {
  const SettingsThemeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    return ExpansionTile(
      title: const Text(
        "Theme",
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        ListTile(
          title: const Text(
            "Light Mode",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
          ),
          trailing: Switch(
            value: theme.isLightMode,
            onChanged: (value) {
              context.read<ThemeProvider>().setThemeMode(
                    value ? ThemeMode.light : ThemeMode.dark,
                  );
            },
          ),
        ),
        if (theme.isDarkMode)
          ListTile(
            title: const Text(
              "Ultra-dark mode",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
            ),
            subtitle: const Text(
              "For AMOLED screens",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
            trailing: Switch(
              value: theme.amoledEnabled,
              onChanged: (value) =>
                  context.read<ThemeProvider>().toggleAmoled(value),
            ),
          ),
      ],
    );
  }
}
