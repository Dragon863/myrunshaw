import 'dart:io';

import 'package:appwrite/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/login/stage1.dart';
import 'package:runshaw/pages/main/main_view.dart';
import 'package:runshaw/pages/nonetwork/no_network.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';

class SplashPage extends StatefulWidget {
  final String? nextRoute;
  const SplashPage({super.key, this.nextRoute});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String loadingStageText = "";
  @override
  void initState() {
    super.initState();
    _navigateToHome();
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
    Preferences? currentPrefs = await api.account?.getPrefs();
    if (currentPrefs == null) {
      return false;
    }
    return currentPrefs.data["onboarding_complete"] == true;
  }

  _navigateToHome() async {
    if (!await hasNetwork("appwrite.danieldb.uk")) {
      return Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const NoNetworkPage(),
        ),
      );
    }

    final api = context.read<BaseAPI>();
    await api.init();
    await api.loadUser();
    final status = api.status;

    if (status == AccountStatus.authenticated) {
      try {
        setState(() {
          loadingStageText = "Loading names...";
        });
        await api.cacheNames();
        setState(() {
          loadingStageText = "Loading timetables...";
        });
        await api.cacheTimetables();
        setState(() {
          loadingStageText = "Loading profile picture versions...";
        });
        await api.cachePfpVersions();
      } catch (e) {
        print("Error caching timetables: $e");
      }
      if (!await isOnBoarded()) {
        return Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const OnBoardingPage(),
          ),
          (r) => false,
        );
      }

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => MainPage(nextRoute: widget.nextRoute),
        ),
        (r) => false,
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

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      // Just in case the map page is opened which on android can cause the app to stay landscape
    ]);
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircleAvatar(
              radius: 120,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 120,
                backgroundImage: AssetImage('assets/img/logo.png'),
              ),
            ),
            const SizedBox(height: 45),
            const CircularProgressIndicator(),
            const SizedBox(height: 30),
            const Text(
              'Welcome to My Runshaw!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              loadingStageText,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
