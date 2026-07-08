import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gaimon/gaimon.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:runshaw/pages/scan/controller.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class PopupBadgeScan extends StatefulWidget {
  final String prompt;
  final String title;
  final bool enableManualInput;
  final bool includeSuffix;

  const PopupBadgeScan({
    super.key,
    required this.prompt,
    required this.title,
    required this.enableManualInput,
    this.includeSuffix = false,
  });

  @override
  State<PopupBadgeScan> createState() => _PopupBadgeScanState();
}

class _PopupBadgeScanState extends State<PopupBadgeScan>
    with WidgetsBindingObserver {
  Barcode? _barcode;
  bool inProgress = false;

  Widget _buildBarcode(Barcode? value) {
    if (value == null) {
      return Text(
        widget.prompt,
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
      String studentId;

      if (widget.includeSuffix) {
        studentId = _barcode!.displayValue!;
      } else {
        studentId = _barcode!.displayValue!.split("-")[0];
      }

      if (!Platform.isLinux) {
        if (await Gaimon.canSupportsHaptic) {
          Gaimon.medium();
        }
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
      appBar: RunshawAppBar(
        title: widget.title,
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
      floatingActionButton: widget.enableManualInput
          ? FloatingActionButton(
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
                        Navigator.of(context).pop(textController.text.trim());
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
                      if (!Platform.isLinux) {
                        if (await Gaimon.canSupportsHaptic) {
                          Gaimon.medium();
                        }
                      }
                      await returnValue(value);
                    }
                  }
                });
              },
              child: const Icon(Icons.keyboard),
            )
          : null,
    );
  }
}
