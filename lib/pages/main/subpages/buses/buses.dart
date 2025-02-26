import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_list.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/api.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  bool loading = true;
  List<Widget> busPins = [];
  Map<String, String?> allBuses = {};
  List<Widget> richTextWidgets = [
    RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        text: 'The ',
        style: GoogleFonts.rubik(
          fontSize: 24,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
        children: [
          TextSpan(
            text: 'bus tracker',
            style: GoogleFonts.rubik(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const TextSpan(text: ' is loading...'),
        ],
      ),
    ),
  ];
  Timer? timer;

  Future<void> loadData() async {
    setState(() => loading = true);
    int index = 0;

    final api = context.read<BaseAPI>();
    final busNumber = await api.getBusNumber();
    final List<String> allBuses = await api.getAllBuses();
    if (busNumber != null && !allBuses.contains(busNumber) && busNumber != "") {
      allBuses.add(busNumber);
    }
    final List<Color> colors = [
      Colors.red,
      Colors.blue,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
    ];
    final busBays = await api.getBusBays();

    List<Widget> pins = [];

    if (busNumber == null) {}

    setState(() {
      richTextWidgets = [];
      busPins = [];
    });

    if (allBuses.isEmpty) {
      setState(() {
        richTextWidgets = [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'Use the ',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: 'settings',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const TextSpan(text: ' to add a bus!'),
              ],
            ),
          ),
        ];
        loading = false;
      });
      return;
    }

    busBays.forEach((String bus, String? bay) {
      if (!allBuses.contains(bus)) {
        return;
      }

      if (bay != null && bay != "RSP_NYA" && bay != "RSP_UNK") {
        final busColor = colors[index % colors.length];
        richTextWidgets.add(
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'The ',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: bus,
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: busColor,
                  ),
                ),
                const TextSpan(text: ' is in bay '),
                TextSpan(
                  text: bay,
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );

        final position = calculatePosition(bay);
        final xPercentage = position[0];
        final yPercentage = position[1];

        pins.add(
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Padding(
                  padding: EdgeInsets.only(
                    top: constraints.biggest.height * yPercentage,
                    bottom: constraints.biggest.height * (1 - yPercentage),
                    left: xPercentage > 0
                        ? constraints.biggest.width * xPercentage
                        : 0,
                    right: xPercentage < 0
                        ? constraints.biggest.width * -xPercentage
                        : 0,
                  ),
                  child: Icon(
                    Icons.location_pin,
                    size: constraints.biggest.height * 0.15,
                    color: busColor,
                  ),
                );
              },
            ),
          ),
        );

        index++;
      } else {
        richTextWidgets.add(
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'The ',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: bus,
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colors[index],
                  ),
                ),
                const TextSpan(text: ' hasn\'t arrived yet'),
              ],
            ),
          ),
        );
      }
    });

    setState(() {
      busPins = pins;
      loading = false;
    });
  }

  @override
  void initState() {
    loadData();
    timer = Timer.periodic(
      const Duration(seconds: 10),
      (Timer t) => loadData(),
    );
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                Stack(
                  children: [
                    Image.asset(
                      "assets/img/busesmap.png",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    ...busPins,
                  ],
                ),
                const SizedBox(height: 12),
                ...richTextWidgets,
                const SizedBox(height: 22),
                _buildCard("View all buses", Icons.directions_bus, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const BusListPage()),
                  );
                }),
                _buildCard("CCTV Policy", Icons.videocam, () async {
                  await showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Text(
                              "CCTV Recording",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                                "Please note that College bus services may have CCTV surveillance systems fitted. "
                                "These may record images as well as audio. The College can request access "
                                "to these recordings in order to ensure the safety of students and in order "
                                "to meet any crime detection and prevention obligations placed upon us by relevant "
                                "law enforcement agencies. For more information please review the relevant signage "
                                "affixed to your college bus and the bus operators privacy notices. "),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadData,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildCard(String text, IconData icon, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 1,
        child: InkWell(
          splashColor: Colors.grey.shade300,
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
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
