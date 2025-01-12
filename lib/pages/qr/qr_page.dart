import 'package:flutter/material.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class QrCodePage extends StatelessWidget {
  final String qrUrl;

  const QrCodePage({super.key, required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(
        title: "QR Code",
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              "This is the same as the QR code on your Student ID",
              textAlign: TextAlign.center,
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
            const SizedBox(
              height: 20,
            ),
            const Text(
              "(due to scanner limitations, this may not work in study zones)",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
