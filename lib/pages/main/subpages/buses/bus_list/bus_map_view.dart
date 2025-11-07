import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class BusMapViewPage extends StatefulWidget {
  final String bay;
  final String busNumber;
  final Color? color;

  const BusMapViewPage({
    super.key,
    required this.bay,
    required this.busNumber,
    this.color = Colors.red,
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
      appBar: RunshawAppBar(
        title: "${widget.busNumber} Bus",
        backgroundColor: widget.color ?? Colors.red,
      ),
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
                      context.read<ThemeProvider>().isLightMode
                          ? Image.asset(
                              "assets/img/busesmap.png",
                              width: double.infinity,
                              fit: BoxFit.cover,
                            )
                          : Image.asset(
                              "assets/img/busesmap-dark.png",
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
                                color: widget.color,
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
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 0),
                          decoration: BoxDecoration(
                            color: widget.color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.busNumber,
                            style: GoogleFonts.rubik(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      TextSpan(
                        text: " is in bay",
                        style: GoogleFonts.rubik(
                          fontSize: 24,
                          fontWeight: FontWeight.normal,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      TextSpan(
                        text: " ${widget.bay}",
                        style: GoogleFonts.rubik(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
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
