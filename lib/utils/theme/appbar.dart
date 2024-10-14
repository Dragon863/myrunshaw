import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RunshawAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  RunshawAppBar({required this.title, this.actions, super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.red,
      title: Text(
        title,
        style: GoogleFonts.rubik(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      actions: actions,
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
