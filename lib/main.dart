import 'dart:io';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/about/about.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/popup_add_page.dart';
import 'package:runshaw/pages/password/password_reset.dart';
import 'package:runshaw/pages/privacy/privacy_policy.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/pages/terms/terms_of_use.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String? nextRoute;

  debugLog("Starting app...", level: 0);
  // Initialise Aptabase
  await Aptabase.init(
    MyRunshawConfig.aptabaseProjectId,
    const InitOptions(
      host: MyRunshawConfig.aptabaseHost,
      printDebugMessages: kDebugMode, // Only print debug messages in debug mode
    ),
  );
  debugLog("Aptabase initialised", level: 0);

  // Get onesignal ready...
  if (!kIsWeb) {
    // can't use Platform.* on web
    if (!Platform.isLinux) {
      OneSignal.initialize(MyRunshawConfig.oneSignalAppId);
      OneSignal.Notifications.addClickListener(
        (OSNotificationClickEvent event) async {
          if (event.notification.body!.contains("has arrived in bay")) {
            nextRoute = "/bus";
            while (navigatorKey.currentState == null) {
              await Future.delayed(const Duration(milliseconds: 100));
              // bad practice and not ideal, but it's fine because we're waiting for the app to load and nothing else works
            }

            navigatorKey.currentState!.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const SplashPage(
                  nextRoute: "/bus",
                ),
              ),
              (route) => false,
            );
            //}
          } else if (event.notification.body
              .toString()
              .contains("friend request")) {
            nextRoute = "/friends";
            while (navigatorKey.currentState == null) {
              await Future.delayed(const Duration(milliseconds: 100));
              // again this is bad practice. See above comment
            }
            navigatorKey.currentState?.pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const SplashPage(
                  nextRoute: "/friends",
                ),
              ),
              (route) => false,
            );
          }
        },
      );
    }

    OneSignal.Notifications.addForegroundWillDisplayListener(
        (OSNotificationWillDisplayEvent event) {
      event.preventDefault();
      event.notification.display();
    });

    OneSignal.Notifications.requestPermission(true);
  }

  runApp(
    ChangeNotifierProvider(
      create: ((context) => BaseAPI()),
      child: BaseApp(
        nextRoute: nextRoute,
        globalKey: navigatorKey,
      ),
    ),
  );
}

class BaseApp extends StatelessWidget {
  final String? nextRoute;
  final GlobalKey<NavigatorState>? globalKey;
  const BaseApp({super.key, this.nextRoute, this.globalKey});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: Brightness.light,
      ),
      // Prevents that weird different coloured status bar on android
    );
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
        themeProvider.initTheme();
        return MaterialApp(
          title: 'My Runshaw',
          theme: ThemeData(
            primarySwatch: Colors.red,
            colorScheme: lightColourScheme,
            fontFamily: 'Rubik',
            primaryTextTheme: GoogleFonts.rubikTextTheme(
              Theme.of(context).textTheme,
            ),
            scaffoldBackgroundColor: Colors.white,
            snackBarTheme: SnackBarThemeData(
              actionTextColor: Colors.red,
              backgroundColor: Colors.grey[800],
              contentTextStyle: GoogleFonts.rubik(color: Colors.white),
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              behavior: SnackBarBehavior.floating,
              insetPadding: const EdgeInsets.all(10),
            ),
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.red,
            brightness: Brightness.dark,
            colorScheme: darkColourScheme,
            fontFamily: 'Rubik',
            primaryTextTheme: GoogleFonts.rubikTextTheme(
              Theme.of(context).textTheme,
            ),
            scaffoldBackgroundColor: const Color(0xFF1E1E1E),
            snackBarTheme: SnackBarThemeData(
              actionTextColor: Colors.red,
              backgroundColor: Colors.grey[800],
              contentTextStyle: GoogleFonts.rubik(color: Colors.white),
              elevation: 20,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              behavior: SnackBarBehavior.floating,
              insetPadding: const EdgeInsets.all(10),
            ),
          ),
          home: SplashPage(
            nextRoute: nextRoute,
          ),
          debugShowCheckedModeBanner: false,
          routes: <String, WidgetBuilder>{
            '/splash': (BuildContext context) => const SplashPage(),
            '/friends/add': (BuildContext context) =>
                const PopupFriendAddPage(),
            '/privacy_policy': (BuildContext context) =>
                const PrivacyPolicyPage(),
            '/change_password': (BuildContext context) =>
                const PasswordResetPage(),
            '/terms': (BuildContext context) => const TermsOfUsePage(),
            '/about': (BuildContext context) => const AboutPage(),
            // We can only add routes here that don't need data passing to them
          },
          navigatorKey: globalKey,
          themeMode: themeProvider.themeMode,
        );
      }),
    );
  }
}
