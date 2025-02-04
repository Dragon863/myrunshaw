import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_map/flutter_image_map.dart';
import 'package:runshaw/pages/main/subpages/map/individual_map.dart';
import 'package:runshaw/pages/main/subpages/map/locations.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final TextEditingController _searchController = TextEditingController();

  void submit() {
    final String value = _searchController.text;
    if (value.isEmpty) {
      return;
    }
    for (final location in locations.entries) {
      for (final Map floor in location.value) {
        for (final room in floor['rooms']) {
          if (room.toLowerCase() == value.toLowerCase()) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => IndividualBuildingMapPage(
                  fileName: floor['img'],
                  subtext: location.key,
                ),
              ),
            );
            return;
          }
        }
      }
    }
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Room not found"),
          content:
              const Text("Sorry, the room you searched for couldn't be found"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    final htmlDataRegions = ImageMapRegion.fromHtml(
      '''
<!-- Image Map Generated by http://www.image-map.net/ -->
<img src="campus.png" usemap="#image-map">

<map name="image-map">
    <area title="Hawkshead"               href="hawkshead" coords="83,324,53,274,96,233,177,197,215,309,129,326" shape="poly">
    <area title="Eskdale"                 href="eskdale" coords="341,306,397,288,346,89,252,111,270,176,297,176,332,278" shape="poly">
    <area title="Dalehead Student Zone"   href="dalehead-sz" coords="410,210,522,101" shape="rect">
    <area title="Dalehead"                href="dalehead" coords="530,198,527,145,626,124,635,173" shape="poly">
    <area title="Tyndale"                 href="tyndale" coords="386,402,493,400,486,480,392,480,389,445" shape="poly">
    <area title="Ferndale"                href="ferndale" coords="565,464,564,440,602,440,599,416,494,414,494,465" shape="poly">
    <area title="Silverdale"              href="silverdale" coords="473,371,525,404,602,408,589,275,514,283,509,315,473,324" shape="poly">
    <area title="Mardale"                 href="mardale" coords="604,462,601,417,613,417,603,323,645,264,793,260,783,453" shape="poly">
    <area title="Grizedale"               href="grizedale" coords="967,346,963,302,968,275,857,274,861,319,887,339" shape="poly">
    <area title="Rydal"                   href="rydal" coords="972,275,968,310,971,341,1031,341,1055,311,1051,274" shape="poly">
    <area title="Buttermere"              href="buttermere" coords="1019,452,1074,447,1075,405,1097,404,1096,382,1070,357,1013,362,1019,377,990,376,988,400,1019,401" shape="poly">
    <area title="Patterdale"              href="patterdale" coords="942,452,1014,450,1013,405,986,402,985,386,941,392,946,414,924,410,925,432,943,436" shape="poly">
    <area title="Langdale &amp; Coniston" href="l-and-c" coords="836,445,830,362,933,354,939,408,923,406,921,445" shape="poly">
    <area title="Octagon"                 href="octagon" coords="787,452,792,360,827,360,832,452" shape="poly">
</map>
''',
      Colors.transparent,
    );
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(0.0),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 1000,
              ),
              child: Column(
                children: <Widget>[
                  ImageMap(
                    image: Image.asset('assets/img/campus.png'),
                    onTap: (region) {
                      final List roomObjList = locations[region.link!];
                      if (roomObjList.length == 1) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => IndividualBuildingMapPage(
                              fileName: roomObjList[0]['img'],
                              subtext: roomObjList[0]['title'],
                            ),
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text(region.title!),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  for (final roomObj in roomObjList)
                                    ListTile(
                                      title: Text(roomObj['title']),
                                      onTap: () {
                                        Navigator.pop(context);
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                IndividualBuildingMapPage(
                                              fileName: roomObj['img'],
                                              subtext: roomObj['title'],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                            );
                          },
                        );
                      }
                    },
                    regions: [
                      ...htmlDataRegions,
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Tap on a building to view its floorplan, or search for a room below",
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SearchBar(
                      controller: _searchController,
                      hintText: "Search a Room Number",
                      trailing: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: submit,
                        ),
                      ],
                      onSubmitted: (value) async {
                        submit();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }
}
