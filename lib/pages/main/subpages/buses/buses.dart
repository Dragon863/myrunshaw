import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_list.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/individual_bus.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_widgets.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  bool loading = true;
  List<Widget> busPins = [];
  List<Widget> arrivalCardContents = [];
  Timer? timer;
  bool _isInitialLoad = true;
  String arrivalText = "";

  Future<void> loadData({bool showLoading = true}) async {
    if (!mounted) return;

    if (showLoading) {
      setState(() {
        loading = true;
        busPins = [];
        arrivalCardContents = [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: LoadingIndicator(),
          )
        ];
      });
    }

    int index = 0;

    final api = context.read<BaseAPI>();
    final List<String> allBusesList = await api.getAllSubscribedBuses();

    allBusesList.sort(
      (a, b) => int.parse(a.replaceAll(RegExp(r'[A-Z]'), "")).compareTo(
        int.parse(b.replaceAll(RegExp(r'[A-Z]'), "")),
      ),
    );

    final List<Color> colors = MyRunshawConfig.busBayColors;
    Map<String, String?> busBays = {};
    final busArrivals = await api.getBusArrivals();
    for (var bus in busArrivals) {
      busBays[bus["bus_id"]] = bus["bus_bay"]?.toString();
      // turn busBays into a map like { "760": "A1", "762": "B2" }
    }

    List<Widget> pins = [];
    List<Widget> newArrivalCardContents = [];

    if (!mounted) return;

    if (allBusesList.isEmpty) {
      if (!mounted) return;
      setState(() {
        arrivalCardContents = [
          SizedBox(height: 6),
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
      final busColor = colors[index % colors.length];

      if (bay != null && bay != "RSP_NYA" && bay != "RSP_UNK" && bay != "0") {
        newArrivalCardContents.add(
          BusCard(
            bus: BusInfo(
              number: bus,
              bay: bay,
              bayColor: busColor,
              status: BusStatus.arrived,
              arrivedTimeAgo: timeago.format(
                DateTime.parse(
                  busArrivals.firstWhere(
                      (element) => element["bus_id"] == bus)["arrival_time"],
                ),
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IndividualBusPage(
                    busNumber: bus,
                    bay: bay,
                    color: busColor,
                  ),
                ),
              );
            },
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
      } else {
        newArrivalCardContents.add(
          BusCard(
            bus: BusInfo(
              number: bus,
              bay: bay ?? "...",
              bayColor: busColor,
              status: BusStatus.waiting,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => IndividualBusPage(
                    busNumber: bus,
                    bay: bay ?? "...",
                    color: busColor,
                  ),
                ),
              );
            },
          ),
        );
      }
      index++;
    });

    final String totalBuses = busBays.length.toString();
    final String totalArrived =
        busBays.values.where((bay) => bay != "0").length.toString();

    if (!mounted) return;
    setState(() {
      busPins = pins;
      arrivalCardContents = newArrivalCardContents;
      arrivalText = "$totalArrived/$totalBuses arrived";
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
      const Duration(seconds: 10),
      (Timer t) => loadData(showLoading: false),
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
                ...arrivalCardContents,
                const SizedBox(height: 6),
                if (arrivalText != "")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "$arrivalText  •",
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BusListPage(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(
                              top: 8.0, bottom: 8.0, right: 8.0),
                          child: Text(
                            'View All',
                            style: GoogleFonts.rubik(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFD94040),
                              decoration: TextDecoration.underline,
                              decorationColor: const Color(0xFFD94040),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
}
