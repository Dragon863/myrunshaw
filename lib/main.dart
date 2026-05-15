import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:runshaw/utils/widgets/runshaw_pay_widget_sync.dart';
import 'package:runshaw/utils/routing/route_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  BackgroundFetch.registerHeadlessTask(runshawPayWidgetHeadlessTask);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  debugLog("Starting app...", level: 0);
  MyRunshawConfig.logApiUrlsOnStartup();

  // new in v1.3.24, analytics are now initialised on the splash page so
  // surveys are shown *after* automatic navigation to the home page, not before.

  final themeProvider = ThemeProvider();
  await themeProvider.initTheme();
  await RunshawPayWidgetSync.initialize();

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
              : darkColourScheme.surfaceContainerHighest,
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
        onGenerateInitialRoutes: AppRouteHandler.onGenerateInitialRoutes,
        debugShowCheckedModeBanner: false,
        routes: AppRouteHandler.getNamedRoutes(),
        onGenerateRoute: AppRouteHandler.onGenerateRoute,
        navigatorKey: globalKey,
        navigatorObservers: [
          PosthogObserver(),
        ],
        themeMode: themeProvider.themeMode,
      );
    });
  }
}
