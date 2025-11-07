import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Color> getColor() async {
  const Color surfaceColor = Color.fromARGB(255, 41, 41, 41);
  final prefs = await SharedPreferences.getInstance();
  final bool? isAmoled = prefs.getBool('isAmoled');

  if (isAmoled == true) {
    return const Color.fromARGB(255, 0, 0, 0);
  } else {
    return surfaceColor;
  }
}

const ColorScheme darkColourScheme = ColorScheme(
  brightness: Brightness.dark,
  surface: Color.fromARGB(255, 41, 41, 41),
  primary: Colors.red,
  secondary: Color(0xFFB39DDB),
  tertiary: Color(0xFF80CBC4),
  surfaceContainerHighest: Color(0xFF1E1E1E),
  primaryContainer: Color.fromARGB(255, 212, 87, 83),
  secondaryContainer: Color(0xFF5E35B1),
  tertiaryContainer: Color(0xFF004D40),
  // on
  onPrimary: Color(0xFF1B1B1B),
  onSecondary: Color(0xFF1B1B1B),
  onTertiary: Color(0xFF1B1B1B),
  onSurface: Color(0xFFE0E0E0),
  onPrimaryContainer: Color(0xFFFFFFFF),
  onSecondaryContainer: Color(0xFFFFFFFF),
  onTertiaryContainer: Color(0xFFFFFFFF),
  error: Colors.red,
  onError: Colors.yellow,
);

const ColorScheme amoledColourScheme = ColorScheme(
  brightness: Brightness.dark,
  surface: Color.fromARGB(255, 0, 0, 0),
  primary: Colors.red,
  secondary: Color(0xFFB39DDB),
  tertiary: Color(0xFF80CBC4),
  surfaceContainerHighest: Color(0xFF000000),
  primaryContainer: Color.fromARGB(255, 212, 87, 83),
  secondaryContainer: Color(0xFF5E35B1),
  tertiaryContainer: Color(0xFF004D40),
  // on
  onPrimary: Color(0xff000000),
  onSecondary: Color(0xff000000),
  onTertiary: Color(0xff000000),
  onSurface: Color(0xFFE0E0E0),
  onPrimaryContainer: Color(0xFFFFFFFF),
  onSecondaryContainer: Color(0xFFFFFFFF),
  onTertiaryContainer: Color(0xFFFFFFFF),
  error: Colors.red,
  onError: Colors.yellow,
);
