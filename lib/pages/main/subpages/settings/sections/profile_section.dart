import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SettingsProfileSection extends StatelessWidget {
  final String name;
  final bool nameLoaded;
  final String email;
  final String? profilePicUrl;
  final Future<void> Function() onPhotoTap;
  final Future<void> Function() onDeleteTap;
  final Future<void> Function(String newName) onNameChange;

  const SettingsProfileSection({
    super.key,
    required this.name,
    required this.nameLoaded,
    required this.email,
    required this.profilePicUrl,
    required this.onPhotoTap,
    required this.onDeleteTap,
    required this.onNameChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 18),
        Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48.0, right: 48.0),
              child: CircleAvatar(
                radius: 100,
                foregroundImage:
                    profilePicUrl != null ? NetworkImage(profilePicUrl!) : null,
                child: Text(
                  getFirstNameCharacter(name),
                  style: GoogleFonts.rubik(
                    fontSize: 60,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 6,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      shape: WidgetStateProperty.all(const CircleBorder()),
                    ),
                    onPressed: onPhotoTap,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: context.read<ThemeProvider>().isLightMode
                          ? Colors.grey.shade800
                          : Colors.white70,
                    ),
                    onPressed: onDeleteTap,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 24 + (10 * 2)),
            Expanded(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.rubik(
                  fontSize: 32,
                  fontWeight: FontWeight.normal,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            IconButton(
              icon: Icon(Icons.mode_edit, color: Colors.grey.shade800),
              onPressed: () async {
                if (!nameLoaded) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please wait a moment..."),
                    ),
                  );
                  return;
                }
                final nameController = TextEditingController(text: name);
                final newName = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Change Name"),
                    content: TextField(
                      controller: nameController,
                      autofocus: true,
                      autocorrect: false,
                      decoration: const InputDecoration(hintText: "New Name"),
                      onSubmitted: (_) =>
                          Navigator.of(context).pop(nameController.text),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).pop(nameController.text),
                        child: const Text("Change"),
                      ),
                    ],
                  ),
                );
                if (newName != null && newName.isNotEmpty) {
                  if (newName.length < 40) {
                    await onNameChange(newName);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Error: Name too long"),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            const SizedBox(width: 10),
          ],
        ),
        Text(
          email.replaceAll(MyRunshawConfig.emailExtension, ""),
          style: GoogleFonts.rubik(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: context.read<ThemeProvider>().isLightMode
                ? Colors.grey.shade800
                : null,
          ),
        ),
        const SizedBox(height: 9),
        const Padding(
          padding: EdgeInsets.only(left: 12.0, right: 12.0),
          child: Divider(),
        ),
        const SizedBox(height: 9),
      ],
    );
  }
}
