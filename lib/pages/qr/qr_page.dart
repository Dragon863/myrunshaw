import 'package:flutter/material.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class QrCodePage extends StatelessWidget {
  final String qrUrl;

  const QrCodePage({super.key, required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(
        title: "QR Code",
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "Scan this code to check in to the study zone",
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Image(
              image: Image.network(qrUrl).image,
            ),
          ],
        ),
      ),
    );
  }
}
