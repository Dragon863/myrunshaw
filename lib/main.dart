import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/about/about.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/popup_add_page.dart';
import 'package:runshaw/pages/password/password_reset.dart';
import 'package:runshaw/pages/privacy/privacy_policy.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/pages/terms/terms_of_use.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  debugLog("Starting app...", level: 0);

  // new in v1.3.24, analytics are now initialised on the splash page so
  // surveys are shown *after* automatic navigation to the home page, not before.

  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: ((context) => BaseAPI())),
        ChangeNotifierProvider.value(value: themeProvider),
      ],
      child: BaseApp(
        globalKey: navigatorKey,
      ),
    ),
  );
}

class BaseApp extends StatelessWidget {
  final GlobalKey<NavigatorState>? globalKey;
  const BaseApp({super.key, this.globalKey});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
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
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  Brightness.light, // makes icons light in Android
              statusBarBrightness: Brightness.dark, // makes icons light in iOS
            ),
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
          scaffoldBackgroundColor: context.read<ThemeProvider>().amoledEnabled
              ? Colors.black
              : const Color(0xFF1E1E1E),
          snackBarTheme: SnackBarThemeData(
            actionTextColor: Colors.red,
            backgroundColor: context.read<ThemeProvider>().amoledEnabled
                ? Colors.black
                : Colors.grey[800],
            contentTextStyle: GoogleFonts.rubik(color: Colors.white),
            elevation: 20,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            behavior: SnackBarBehavior.floating,
            insetPadding: const EdgeInsets.all(10),
          ),
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness:
                  Brightness.light, // makes icons light in Android
              statusBarBrightness: Brightness.dark, // makes icons light in iOS
            ),
          ),
        ),
        initialRoute: '/splash',
        debugShowCheckedModeBanner: false,
        routes: <String, WidgetBuilder>{
          '/splash': (BuildContext context) => const SplashPage(),
          '/friends/add': (BuildContext context) => const PopupFriendAddPage(),
          '/privacy_policy': (BuildContext context) =>
              const PrivacyPolicyPage(),
          '/change_password': (BuildContext context) =>
              const PasswordResetPage(),
          '/terms': (BuildContext context) => const TermsOfUsePage(),
          '/about': (BuildContext context) => const AboutPage(),
          // We can only add routes here that don't need data passing to them
        },
        navigatorKey: globalKey,
        navigatorObservers: [
          PosthogObserver(),
        ],
        themeMode: themeProvider.themeMode,
      );
    });
  }
}
