import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class RunshawAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  RunshawAppBar({
    required this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // When the app bar is created, we want to set the status bar to be transparent and the icons to be white (looks nice!)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.red,
      statusBarIconBrightness: Brightness.light,
    ));
    return AppBar(
      centerTitle: true,
      backgroundColor: Colors.red,
      automaticallyImplyLeading: automaticallyImplyLeading,
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
