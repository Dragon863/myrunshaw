import 'dart:io';

import 'package:appwrite/models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/login/stage1.dart';
import 'package:runshaw/pages/main/main_view.dart';
import 'package:runshaw/pages/nonetwork/no_network.dart';
import 'package:runshaw/pages/onboarding/onboarding.dart';
import 'package:runshaw/utils/api.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('appwrite.danieldb.uk');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
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
    if (!await hasNetwork()) {
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
          builder: (context) => const MainPage(),
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
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            CircleAvatar(
              radius: 120,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 120,
                backgroundImage: AssetImage('assets/img/logo.png'),
              ),
            ),
            SizedBox(height: 45),
            CircularProgressIndicator(),
            SizedBox(height: 30),
            Text(
              'Welcome to My Runshaw!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
