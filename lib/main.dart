import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/utils/api.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: ((context) => AuthAPI()),
      child: const BaseApp(),
    ),
  );
}

class BaseApp extends StatelessWidget {
  const BaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Runshaw',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        fontFamily: 'Rubik',
        textTheme: GoogleFonts.rubikTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: SplashPage(),
    );
  }
}
