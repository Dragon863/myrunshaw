import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  String myBus = 'bus tracker';
  List<String> toDisplay = ["is", "loading..."];
  bool loading = true;
  bool showPin = false;
  double xPercentage = 0.0;
  double yPercentage = 0.0;

  Future<void> loadData() async {
    setState(() {
      loading = true;
    });
    final api = context.read<BaseAPI>();
    final busNumber = await api.getBusNumber();

    if (busNumber != null) {
      final bay = await api.getBusBay(busNumber);
      if (bay == "RSP_NYA" || bay == "RSP_UNK") {
        setState(() {
          toDisplay = ["has", "not yet arrived"];
          showPin = false;
        });
      } else {
        calculatePosition(bay);
        setState(() {
          toDisplay = ["is at stand", bay];
          showPin = true;
        });
      }
    }

    setState(() {
      if (busNumber == null) {
        myBus = 'settings menu';
        toDisplay = ["allows you to set your", "bus number"];
      } else {
        myBus = busNumber;
      }
    });

    setState(() {
      loading = false;
    });
  }

  void calculatePosition(String bayNumber) {
    switch (bayNumber) {
      case "T1":
        xPercentage = 0.84;
        yPercentage = 0.55;
        return;
      case "T2":
        xPercentage = 0.84;
        yPercentage = 0.37;
        return;
    }
    final bayChar = bayNumber[0];
    final bayNum = int.parse(bayNumber.substring(1));
    xPercentage = 0.75 - (bayNum - 1) * 0.095;
    switch (bayChar) {
      case "A":
        yPercentage = 0.40;
        return;
      case "B":
        yPercentage = 0.48;
        return;
      case "C":
        yPercentage = 0.54;
        return;
    }
  }

  @override
  void initState() {
    loadData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 1000,
                ),
                child: Stack(
                  children: [
                    Image.asset(
                      "assets/img/busesmap.png",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Visibility(
                      visible: showPin,
                      child: Positioned.fill(
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
                    ),
                  ],
                ),
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
                    text: myBus,
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  TextSpan(text: " ${toDisplay[0]}"),
                  TextSpan(
                    text: ' ${toDisplay[1]}',
                    style: GoogleFonts.rubik(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.refresh),
        onPressed: () async {
          await loadData();
        },
      ),
    );
  }
}
