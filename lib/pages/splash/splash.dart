import 'dart:io';

import 'package:aptabase_flutter/aptabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/error/server_issues.dart';
import 'package:runshaw/pages/login/stage1.dart';
import 'package:runshaw/pages/main/main_view.dart';
import 'package:runshaw/pages/nonetwork/no_network.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class SplashPage extends StatefulWidget {
  final String? nextRoute;
  const SplashPage({super.key, this.nextRoute});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String loadingStageText = "";

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      // Just in case the map page is opened which on android can cause the app to stay landscape
    ]);
    _setupOneSignal();
    _navigateToHome();
  }

  @override
  void didChangeDependencies() {
    precacheImage(const AssetImage('assets/img/splash-dark.png'), context);
    precacheImage(const AssetImage('assets/img/logo-muted.png'), context);
    super.didChangeDependencies();
  }

  Future<void> _setupOneSignal() async {
    if (kIsWeb || Platform.isLinux) return;

    OneSignal.initialize(MyRunshawConfig.oneSignalAppId);
    OneSignal.Notifications.addClickListener((OSNotificationClickEvent event) {
      String? route;
      if (event.notification.body?.contains("has arrived in bay") ?? false) {
        route = "/bus";
      } else if (event.notification.body
              ?.toString()
              .contains("friend request") ??
          false) {
        route = "/friends";
      }

      if (route != null && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => SplashPage(
              nextRoute: route,
            ),
          ),
          (route) => false,
        );
      }
    });

    OneSignal.Notifications.addForegroundWillDisplayListener(
        (OSNotificationWillDisplayEvent event) {
      event.preventDefault();
      event.notification.display();
    });

    await OneSignal.Notifications.requestPermission(true);
  }

  Future<bool> serverReachable() async {
    if (kIsWeb) return true; // Assume web can always reach the server
    setState(() {
      loadingStageText = "Checking server status...";
    });
    try {
      final result = await http.get(
        Uri.parse("${MyRunshawConfig.endpoint}/health/version"),
        headers: {
          "User-Agent": "Runshaw App",
          "Accept": "application/json",
        },
      );
      if (result.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugLog("Error checking server status: $e");
    }
    return false;
  }

  Future<bool> hasNetwork(String knownUrl) async {
    setState(() {
      loadingStageText = "Checking internet access...";
    });
    if (kIsWeb) {
      return _hasNetworkWeb(knownUrl);
    } else {
      return _hasNetworkMobile(knownUrl);
    }
  }

  Future<bool> _hasNetworkWeb(String knownUrl) async {
    return true; // How would we access the site without internet??
    // try {
    //   final result = await http.get(Uri.parse("https://" + knownUrl));
    //   if (result.statusCode == 200) return true;
    // } on SocketException catch (_) {}
    // return false;
  }

  Future<bool> _hasNetworkMobile(String knownUrl) async {
    try {
      final result = await InternetAddress.lookup(knownUrl);
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {}
    return false;
  }

  Future<bool> isOnBoarded() async {
    final api = context.read<BaseAPI>();
    final currentPrefs = await api.account?.getPrefs();
    return currentPrefs?.data["onboarding_complete"] == true;
  }

  _navigateToHome() async {
    if (!await serverReachable() && !kIsWeb) {
      if (!await hasNetwork("google.com")) {
        // If we can't resolve google.com, then we have no internet
        return Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const NoNetworkPage(),
          ),
        );
      }
      // If we can resolve google, then we have internet but no server - oh no!
      return Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const NoServersPage(),
        ),
      );
    }
    debugLog("API init");
    final api = context.read<BaseAPI>();
    await api.init();
    await api.loadUser();
    final status = api.status;

    if (status == AccountStatus.authenticated) {
      debugLog("User is authenticated");

      // Don't wait for caching to finish, do it in the background
      api.caching = _cacheData(api);

      if (!await isOnBoarded()) {
        return Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OnBoardingPage(),
          ),
          (r) => false,
        );
      }

      setState(() {
        loadingStageText = "Let's go!";
      });
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MainPage(
            nextRoute: widget.nextRoute,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
        (route) => false,
      );
      await Aptabase.instance.trackEvent(
        "app_open",
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => const StageOneLogin(),
        ),
        (r) => false,
      );
    }
  }

  Future<void> _cacheData(BaseAPI api) async {
    try {
      debugLog("Caching friends");
      await api.cacheFriends();
      debugLog("Caching names");
      await Future.wait(
        [
          api.cacheNames(),
          api.cachePfpVersions(),
          api.cacheTimetables(),
        ],
      );
      debugLog("Caching names done");
      debugLog("Caching pfp versions done");
      debugLog("Caching timetables done");
    } catch (e) {
      debugLog("Error caching data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.read<ThemeProvider>().isDarkMode
          ? const Color.fromARGB(255, 30, 30, 30)
          : Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            context.read<ThemeProvider>().isDarkMode
                ? const CircleAvatar(
                    radius: 120,
                    backgroundImage: AssetImage('assets/img/splash-dark.png'),
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.transparent,
                  )
                : const CircleAvatar(
                    radius: 120,
                    backgroundImage: AssetImage('assets/img/logo-muted.png'),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.red,
                  ),
            const Spacer(),
            Text(
              loadingStageText,
              style: GoogleFonts.rubik(
                color: Colors.white,
              ),
            ),
            if (kDebugMode)
              Text(
                "Debug mode!",
                style: GoogleFonts.rubik(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }
}
