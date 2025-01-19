import 'dart:typed_data';

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/material.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class PopupCropPage extends StatefulWidget {
  final Uint8List imageBytes;

  const PopupCropPage({super.key, required this.imageBytes});

  @override
  State<PopupCropPage> createState() => _PopupCropPageState();
}

class _PopupCropPageState extends State<PopupCropPage> {
  final _controller = CropController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(
        title: "Crop Image",
        automaticallyImplyLeading: false,
      ),
      body: Stack(
        children: [
          Crop(
            controller: _controller,
            image: widget.imageBytes,
            onCropped: (image) {
              Navigator.of(context).pop(image);
            },
            withCircleUi: true,
            interactive: true,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ElevatedButton(
                onPressed: () {
                  _controller.crop();
                },
                child: const Text("Save"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
