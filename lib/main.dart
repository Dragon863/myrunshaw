import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/popup_add_page.dart';
import 'package:runshaw/pages/splash/splash.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // await Firebase.initializeApp(
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
  } catch (e) {
    // This is fine in dev as I'm on linux, and the app seems to go black if this fails for some reason
  }

  // Get onesignal ready...
  OneSignal.initialize(Config.oneSignalAppId);
  OneSignal.Notifications.requestPermission(true);
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);

  runApp(
    ChangeNotifierProvider(
      create: ((context) => BaseAPI()),
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
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
        ),
        fontFamily: 'Rubik',
        textTheme: GoogleFonts.rubikTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: SplashPage(),
      debugShowCheckedModeBanner: false,
      routes: <String, WidgetBuilder>{
        '/splash': (BuildContext context) => SplashPage(),
        '/friends/add': (BuildContext context) => const PopupFriendAddPage(),
        // We can only add routes here that don't need data passing to them
      },
    );
  }
}
