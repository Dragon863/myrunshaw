import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class BusMapViewPage extends StatefulWidget {
  final String bay;
  final String busNumber;

  const BusMapViewPage({
    super.key,
    required this.bay,
    required this.busNumber,
  });

  @override
  State<BusMapViewPage> createState() => _BusMapViewPageState();
}

class _BusMapViewPageState extends State<BusMapViewPage> {
  double xPercentage = 0.0;
  double yPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    final List<double> position = calculatePosition(widget.bay);
    xPercentage = position[0];
    yPercentage = position[1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(title: "${widget.busNumber} Bus"),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 1000,
            ),
            child: Column(
              children: [
                Center(
                  child: Stack(
                    children: [
                      Image.asset(
                        "assets/img/busesmap.png",
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Positioned.fill(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return Padding(
                              padding: EdgeInsets.only(
                                  top: constraints.biggest.height * yPercentage,
                                  bottom: constraints.biggest.height *
                                      (1 - yPercentage),
                                  left: xPercentage > 0
                                      ? constraints.biggest.width * xPercentage
                                      : 0,
                                  right: xPercentage < 0
                                      ? constraints.biggest.width * -xPercentage
                                      : 0),
                              child: Icon(
                                Icons.location_pin,
                                size: constraints.biggest.height * 0.15,
                                color: Colors.red,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    text: 'The ',
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.normal,
                      color: Colors.black,
                    ),
                    children: <TextSpan>[
                      TextSpan(
                        text: widget.busNumber,
                        style: GoogleFonts.rubik(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const TextSpan(text: " is in bay"),
                      TextSpan(
                        text: " ${widget.bay}",
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
