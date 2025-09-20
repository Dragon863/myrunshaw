import 'package:aptabase_flutter/aptabase_flutter.dart';
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
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  runApp(
    ChangeNotifierProvider(
      create: ((context) => BaseAPI()),
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
          home: const SplashPage(),
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
