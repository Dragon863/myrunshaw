import 'package:flutter/material.dart';
import 'package:gaimon/gaimon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:runshaw/main.dart';
import 'package:runshaw/pages/scan/controller.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class PopupFriendAddPage extends StatefulWidget {
  const PopupFriendAddPage({super.key});

  @override
  State<PopupFriendAddPage> createState() => _PopupFriendAddPageState();
}

class _PopupFriendAddPageState extends State<PopupFriendAddPage>
    with WidgetsBindingObserver {
  Barcode? _barcode;
  bool inProgress = false;

  void navigateToSplash() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const BaseApp(),
      ),
    );
  }

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return const Text(
        'Scan a Student ID Badge!',
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
      if (await Gaimon.canSupportsHaptic) {
        Gaimon.medium();
      }
      await returnValue(studentId);
    }
  }

  Future<void> returnValue(String studentID) async {
    if (mounted && !inProgress) {
      Navigator.of(context).pop(studentID);
      // Prevents the user from scanning multiple times as widget is closing which breaks stuff as it removes all routes
      inProgress = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(
        title: "Add Friend",
        actions: [],
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final textController = TextEditingController();
          final popup = AlertDialog(
            title: const Text("Enter Student ID"),
            content: TextField(
              controller: textController,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: "Student ID",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(textController.text);
                  // Pop twice to close the scanner and the dialog
                },
                child: const Text("Submit"),
              ),
            ],
          );
          showDialog(context: context, builder: (context) => popup)
              .then((value) async {
            if (value != null) {
              if (validateNonBadge(value)) {
                if (await Gaimon.canSupportsHaptic) {
                  Gaimon.medium();
                }
                await returnValue(value);
              }
            }
          });
        },
        child: const Icon(Icons.keyboard),
      ),
    );
  }
}
