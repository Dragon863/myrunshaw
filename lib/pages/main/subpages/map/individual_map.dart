import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class IndividualBuildingMapPage extends StatefulWidget {
  final String fileName;
  final String subtext;
  final bool referredByMainMap;

  const IndividualBuildingMapPage({
    super.key,
    required this.fileName,
    required this.subtext,
    this.referredByMainMap = false,
  });

  @override
  State<IndividualBuildingMapPage> createState() =>
      _IndividualBuildingMapPageState();
}

class _IndividualBuildingMapPageState extends State<IndividualBuildingMapPage> {
  @override
  Widget build(BuildContext context) {
    // Sometimes this page is called from outside of the main map page. In this case rotation will not be set.
    // This is a workaround to fix the issue where the map is not displayed in landscape mode in this case
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    return Scaffold(
      appBar: RunshawAppBar(
        title: widget.subtext[0].toUpperCase() + widget.subtext.substring(1),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: InteractiveViewer(
            child: Image.asset('assets/img/map/${widget.fileName}.png'),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (widget.referredByMainMap == false) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }

    super.dispose();
    // reset the orientation to portrait when the page is closed
  }
}
