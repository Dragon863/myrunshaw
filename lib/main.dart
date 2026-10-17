import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:background_fetch/background_fetch.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';

import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/dark.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:runshaw/utils/widgets/runshaw_pay_widget_sync.dart';
import 'package:runshaw/utils/routing/route_handler.dart';
import 'package:runshaw/utils/notifications/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }
  BackgroundFetch.registerHeadlessTask(runshawPayWidgetHeadlessTask);

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter router;
  final initialNotification = await NotificationService.instance.start(
    onOpened: (destination) {
      router.go('/splash', extra: destination);
    },
  );
  router = createAppRouter(
    navigatorKey: navigatorKey,
    initialNotification: initialNotification,
  );

  debugLog("Starting app...", level: 0);
  MyRunshawConfig.logApiUrlsOnStartup();

  // new in v1.3.24, analytics are now initialised on the splash page

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
        router: router,
      ),
    ),
  );
}

class BaseApp extends StatelessWidget {
  final GoRouter router;
  const BaseApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(builder: (context, themeProvider, child) {
      return MaterialApp.router(
        title: 'My Runshaw',
        theme: ThemeData(
          primarySwatch: Colors.red,
          colorScheme: lightColourScheme,
          fontFamily: 'Rubik',
          primaryTextTheme:
              Theme.of(context).textTheme.apply(fontFamily: 'Rubik'),
          scaffoldBackgroundColor: Colors.white,
          snackBarTheme: SnackBarThemeData(
            actionTextColor: Colors.red,
            backgroundColor: Colors.grey[800],
            contentTextStyle: const TextStyle(color: Colors.white),
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
          primaryTextTheme:
              Theme.of(context).textTheme.apply(fontFamily: 'Rubik'),
          scaffoldBackgroundColor: context.read<ThemeProvider>().amoledEnabled
              ? Colors.black
              : darkColourScheme.surfaceContainerHighest,
          snackBarTheme: SnackBarThemeData(
            actionTextColor: Colors.red,
            backgroundColor: context.read<ThemeProvider>().amoledEnabled
                ? Colors.black
                : Colors.grey[800],
            contentTextStyle: const TextStyle(color: Colors.white),
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
        debugShowCheckedModeBanner: false,
        routerConfig: router,
        themeMode: themeProvider.themeMode,
      );
    });
  }
}
