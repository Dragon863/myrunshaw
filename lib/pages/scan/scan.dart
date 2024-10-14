import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/main.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> with WidgetsBindingObserver {
  Barcode? _barcode;
  bool inProgress = false;

  bool validate(String input) {
    RegExp regExp = RegExp(r'^[a-zA-Z]{3}\d{8}-\d{6}$');

    if (regExp.hasMatch(input)) {
      return true;
    } else {
      return false;
    }
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Please scan your Student ID Badge!',
        overflow: TextOverflow.fade,
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
        ),
      );
    }

    if (validate(value.displayValue ?? "")) {
      String studentId = value.displayValue!.split("-")[0];
      return Wrap(
        children: [
          Text(
            studentId,
            overflow: TextOverflow.fade,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      );
    } else {
      return const Wrap(
        children: [
          Text(
            "Invalid Badge Code",
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      );
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) async {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
    }
    final bool valid = validate(_barcode?.displayValue ?? "");

    if (valid) {
      String studentId = _barcode!.displayValue!.split("-")[0];
      await maybeLogin(studentId);
    }
  }

  Future<void> maybeLogin(String studentID) async {
    if (inProgress) {
      return;
    }

    setState(() {
      inProgress = true;
    });

    final TextEditingController controllerPwd = TextEditingController();

    final popup = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Password"),
          content: TextField(
            controller: controllerPwd,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: "Password",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(controllerPwd.text);
              },
              child: const Text("Login"),
            ),
          ],
        );
      },
    );
    setState(() {
      inProgress = false;
    });

    if (popup == null) {
      return;
    }

    print(popup);

    final api = context.read<AuthAPI>();
    try {
      await api.createUser(
        email: "$studentID@student.runshaw.ac.uk",
        password: popup,
      );
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const BaseApp(),
        ),
      );
    } on AppwriteException catch (e) {
      if (e.message!.contains("already")) {
        try {
          await api.createEmailSession(
            email: "$studentID@student.runshaw.ac.uk",
            password: popup,
          );
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const BaseApp(),
            ),
          );
        } on AppwriteException catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.message ?? 'An error occurred'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message ?? 'An error occurred'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(
        title: "Login",
        actions: const [],
      ),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              alignment: Alignment.bottomCenter,
              height: 100,
              color: Colors.black.withOpacity(0.4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(child: Center(child: _buildBarcode(_barcode))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
