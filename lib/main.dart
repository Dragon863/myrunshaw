import 'package:flutter/material.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  String? nextRoute;

  // Get onesignal ready...
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

  OneSignal.Notifications.addForegroundWillDisplayListener(
      (OSNotificationWillDisplayEvent event) {
    event.preventDefault();
    event.notification.display();
  });

  OneSignal.Notifications.requestPermission(true);

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
    return MaterialApp(
      title: 'My Runshaw',
      theme: ThemeData(
        primarySwatch: Colors.red,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        fontFamily: 'Rubik',
        textTheme: GoogleFonts.rubikTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: SplashPage(
        nextRoute: nextRoute,
      ),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/splash': (BuildContext context) => const SplashPage(),
        '/friends/add': (BuildContext context) => const PopupFriendAddPage(),
        '/privacy_policy': (BuildContext context) => const PrivacyPolicyPage(),
        '/change_password': (BuildContext context) => const PasswordResetPage(),
        '/terms': (BuildContext context) => const TermsOfUsePage(),
        '/about': (BuildContext context) => const AboutPage(),
        // We can only add routes here that don't need data passing to them
      },
      navigatorKey: globalKey,
    );
  }
}
