import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  late ThemeMode _themeMode = ThemeMode.system;
  late ColorScheme _darkScheme = darkColourScheme;
  late ColorScheme _lightScheme = lightColourScheme;
  final ColorScheme _amoledScheme = amoledColourScheme;
  late bool amoledEnabled = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);
  bool get isLightMode =>
      _themeMode == ThemeMode.light ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.light);
  
  Future<void> initTheme() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? theme = prefs.getString('theme');
    final bool? isAmoled = prefs.getBool("isAmoled");
    
    if (isAmoled == true) {
      amoledEnabled = true;
    } else {
      amoledEnabled = false;
    }

    if (theme == null) {
      _themeMode = ThemeMode.light;
    } else if (theme == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (theme == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode value) async {
    _themeMode = value;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (value == ThemeMode.system) {
      prefs.remove('theme');
    } else {
      prefs.setString('theme', value.toString().split('.').last);
    }

    notifyListeners();
  }

  Future<void> saveAmoled(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("isAmoled", value);
  }

  ColorScheme get amoledScheme => _amoledScheme;
  void toggleAmoled(bool enabled) {
    amoledEnabled = enabled;
    saveAmoled(enabled);
    notifyListeners();
  }

  ColorScheme get darkScheme => _darkScheme;
  void setDarkScheme(ColorScheme value) {
    if (amoledEnabled) {
      _darkScheme = amoledColourScheme;
      notifyListeners();
    } else {
      _darkScheme = value;
      notifyListeners();
    }
  }

  ColorScheme get lightScheme => _lightScheme;
  void setLightScheme(ColorScheme value) {
    _lightScheme = value;
    notifyListeners();
  }
}
