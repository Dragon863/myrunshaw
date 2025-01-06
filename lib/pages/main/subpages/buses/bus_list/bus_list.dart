import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_map_view.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class BusListPage extends StatefulWidget {
  const BusListPage({super.key});

  @override
  State<BusListPage> createState() => _BusListPageState();
}

class _BusListPageState extends State<BusListPage> {
  Map<String, String?> allBuses = {};
  Map<String, String?> filteredBuses = {};
  String searchQuery = "";

  Future<void> loadData() async {
    final api = context.read<BaseAPI>();
    Map<String, String?> completeBusMap = await api.getBusBays();

    setState(() {
      allBuses = completeBusMap;
      filteredBuses = completeBusMap;
    });
  }

  void filterBuses(String query) {
    setState(() {
      searchQuery = query;
      filteredBuses = allBuses.map((key, value) {
        if (key.toLowerCase().contains(query.toLowerCase())) {
          return MapEntry(key, value);
        } else {
          return const MapEntry("", "");
        }
      });
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
      appBar: const RunshawAppBar(
        title: "All Buses",
        automaticallyImplyLeading: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 750,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SearchBar(
                  onChanged: filterBuses,
                  hintText: "Search for a bus",
                  leading: const Icon(Icons.search),
                  elevation: WidgetStateProperty.all(1.0),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: loadData,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredBuses.length,
                    itemBuilder: (context, index) {
                      final bus = filteredBuses.keys.elementAt(index);
                      final bay = filteredBuses[bus];
                      if (bus == "" || bay == "") {
                        return const SizedBox.shrink();
                      }

                      return ListTile(
                        title: Text(bus,
                            style:
                                GoogleFonts.rubik(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          bay.toString() == "0"
                              ? "Not yet arrived"
                              : bay.toString(),
                        ),
                        trailing: const Icon(Icons.keyboard_arrow_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BusMapViewPage(
                                bay: bay.toString(),
                                busNumber: bus,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
