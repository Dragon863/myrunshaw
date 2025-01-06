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
  String myBus = 'bus tracker';
  List<String> toDisplay = ["is", "loading..."];
  bool loading = true;
  bool showPin = false;
  double xPercentage = 0.0;
  double yPercentage = 0.0;
  Map<String, String?> allBuses = {};

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
        xPercentage = calculatePosition(bay)[0];
        yPercentage = calculatePosition(bay)[1];

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

    Map<String, String?> completeBusMap = await api.getBusBays();

    setState(() {
      allBuses = completeBusMap;
      loading = false;
    });
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
                      Visibility(
                        visible: showPin,
                        child: Positioned.fill(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Padding(
                                padding: EdgeInsets.only(
                                    top: constraints.biggest.height *
                                        yPercentage,
                                    bottom: constraints.biggest.height *
                                        (1 - yPercentage),
                                    left: xPercentage > 0
                                        ? constraints.biggest.width *
                                            xPercentage
                                        : 0,
                                    right: xPercentage < 0
                                        ? constraints.biggest.width *
                                            -xPercentage
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
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      splashColor: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BusListPage(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus),
                            const SizedBox(width: 12),
                            Text(
                              "View all buses",
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
                ),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      splashColor: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        // Show drawer
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
                                        """Please note that College bus services may have CCTV surveillance systems fitted. These may record images as well as audio. The College can request access to these recordings in order to ensure the safety of students and in order to meet any crime detection and prevention obligations placed upon us by relevant law enforcement agencies. For more information please review the relevant signage affixed to your college bus and the bus operators privacy notices. """),
                                  ],
                                ));
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            const Icon(Icons.videocam),
                            const SizedBox(width: 12),
                            Text(
                              "CCTV Policy",
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
                ),
              ],
            ),
          ),
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
