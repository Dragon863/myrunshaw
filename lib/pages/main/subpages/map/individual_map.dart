import 'package:flutter/material.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class IndividualBuildingMapPage extends StatefulWidget {
  final String fileName;
  final String subtext;

  const IndividualBuildingMapPage({
    super.key,
    required this.fileName,
    required this.subtext,
  });

  @override
  State<IndividualBuildingMapPage> createState() =>
      _IndividualBuildingMapPageState();
}

class _IndividualBuildingMapPageState extends State<IndividualBuildingMapPage> {
  @override
  Widget build(BuildContext context) {
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
}
