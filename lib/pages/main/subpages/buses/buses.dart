import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_list.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  bool loading = true;
  List<Widget> busPins = [];
  List<Widget> richTextWidgets = [];
  Timer? timer;
  bool _isInitialLoad = true;

  Future<void> loadData() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      busPins = [];
      richTextWidgets = [
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
              TextSpan(
                text: 'bus tracker',
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              TextSpan(
                text: ' is loading...',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ];
    });
    int index = 0;

    final api = context.read<BaseAPI>();
    final busNumber = await api.getBusNumber();
    final List<String> allBusesList = await api.getAllBuses();
    if (busNumber != null &&
        !allBusesList.contains(busNumber) &&
        busNumber != "") {
      allBusesList.add(busNumber);
    }

    allBusesList.sort(
      (a, b) => int.parse(a.replaceAll(RegExp(r'[A-Z]'), "")).compareTo(
        int.parse(b.replaceAll(RegExp(r'[A-Z]'), "")),
      ),
    );

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
    List<Widget> newRichTextWidgets = [];

    if (!mounted) return;

    if (allBusesList.isEmpty) {
      if (!mounted) return;
      setState(() {
        richTextWidgets = [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'Use the ',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
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
                TextSpan(
                  text: ' to add a bus!',
                  style: GoogleFonts.rubik(
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ],
            ),
          ),
        ];
        busPins = [];
        loading = false;
      });
      return;
    }

    busBays.forEach((String bus, String? bay) {
      if (!allBusesList.contains(bus)) {
        return;
      }

      if (bay != null && bay != "RSP_NYA" && bay != "RSP_UNK" && bay != "0") {
        final busColor = colors[index % colors.length];
        newRichTextWidgets.add(
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 24.0,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              children: [
                TextSpan(
                  text: 'The ',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    decoration: BoxDecoration(
                      color: busColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bus,
                      style: GoogleFonts.rubik(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: ' is in bay ',
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                TextSpan(
                  text: bay,
                  style: GoogleFonts.rubik(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                TextSpan(
                  text: "!",
                  style: GoogleFonts.rubik(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );

        newRichTextWidgets.add(
          const SizedBox(height: 2),
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
      } else {
        newRichTextWidgets.add(
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              text: 'The ',
              style: GoogleFonts.rubik(
                fontSize: 24,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              children: [
                WidgetSpan(
                  alignment: PlaceholderAlignment.middle,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                    decoration: BoxDecoration(
                      color: colors[index % colors.length],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      bus,
                      style: GoogleFonts.rubik(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                TextSpan(
                  text: " hasn't arrived yet",
                  style: GoogleFonts.rubik(
                    fontSize: 24,
                    fontWeight: FontWeight.normal,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      index++;
      newRichTextWidgets.add(
        const SizedBox(height: 2),
      );
    });

    if (!mounted) return;
    setState(() {
      busPins = pins;
      richTextWidgets = newRichTextWidgets;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 20),
      (Timer t) => loadData(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialLoad) {
      loadData();
      _isInitialLoad = false;
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              "affixed to your college bus and the bus operators privacy notices. ",
                            ),
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
          splashColor: context.read<ThemeProvider>().isLightMode
              ? Colors.grey.shade300
              : null,
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
