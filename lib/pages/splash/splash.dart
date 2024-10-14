import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/home/home.dart';
import 'package:runshaw/pages/login/stage1.dart';
import 'package:runshaw/utils/api.dart';

class SplashPage extends StatefulWidget {
  @override
  _SplashPageState createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  _navigateToHome() async {
    final api = context.read<AuthAPI>();
    await api.init();
    await api.loadUser();
    final status = api.status;

    if (status == AccountStatus.authenticated) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomePage(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const StageOneLogin(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FlutterLogo(size: 150),
            SizedBox(height: 30),
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
