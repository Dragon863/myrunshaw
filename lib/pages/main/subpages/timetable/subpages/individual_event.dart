import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/main/subpages/map/individual_map.dart';
import 'package:runshaw/pages/main/subpages/map/locations.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';

class IndividualEventPage extends StatefulWidget {
  final String eventName;
  final String? eventDescription;
  final String? eventLocation;
  final DateTime dtStart;
  final DateTime dtEnd;
  final bool isAspire;
  final Color color;

  const IndividualEventPage({
    super.key,
    required this.eventName,
    this.eventDescription,
    this.eventLocation,
    required this.dtStart,
    required this.dtEnd,
    this.isAspire = true,
    required this.color,
  });

  @override
  State<IndividualEventPage> createState() => _IndividualEventPageState();
}

class _IndividualEventPageState extends State<IndividualEventPage> {
  String? building;
  String? image;
  List<Widget> friends = [];

  void loadMapLocation() {
    if (widget.eventLocation == "" || widget.eventLocation == null) {
      return;
    }
    for (final location in locations.entries) {
      for (final Map floor in location.value) {
        for (final room in floor['rooms']) {
          if (room.toLowerCase() == widget.eventLocation!.toLowerCase()) {
            setState(() {
              building = location.key;
              image = floor['img'];
            });

            return;
          }
        }
      }
    }
  }

  void loadFriends() async {
    setState(() {
      friends = [
        const ListTile(
          leading: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(),
          ),
          title: Text("Loading..."),
        )
      ];
    });
    final api = context.read<BaseAPI>();
    final fetchedFriends = await api.getFriends();
    final List<Widget> friendsList = [];
    for (final friend in fetchedFriends) {
      final String userId = friend['userid'];
      final List<Event> events =
          await api.fetchEvents(userId: userId, includeAll: true);
      final String name = await api.getName(userId);
      final String pfpUrl = api.getPfpUrl(userId);
      String current = "";

      current = fetchCurrentEventAt(
        events,
        widget.dtStart.add(const Duration(minutes: 1)),
      );
      if ((current == "No Event" ||
                  current.contains("Aspire")) // No event, or a free
              &&
              events.length > 1 // Timetable is synced
          ) {
        friendsList.add(
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8.0,
            ), // Half the default padding, looks better
            leading: CircleAvatar(
              foregroundImage: CachedNetworkImageProvider(
                pfpUrl,
                errorListener: (error) {},
              ),
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(name),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => IndividualFriendPage(
                    userId: userId,
                    name: name,
                    profilePicUrl: pfpUrl,
                  ),
                ),
              );
            },
          ),
        );
      }
    }
    if (friendsList.isEmpty) {
      setState(() {
        friends = [
          const ListTile(
            title: Text("No friends are free during this period"),
          )
        ];
      });
    } else {
      setState(() {
        friends = friendsList;
      });
    }
  }

  @override
  void initState() {
    loadMapLocation();
    loadFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text("Event Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 700,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(
                    width: double.infinity,
                  ), // ensure the column is full width
                  if (image != null)
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          children: [
                            Image.asset(
                              "assets/img/map/$image.png",
                              fit: BoxFit.cover,
                              width: 700,
                              height: 400,
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                height: 300,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  gradient: LinearGradient(
                                      begin: FractionalOffset.topCenter,
                                      end: FractionalOffset.bottomCenter,
                                      colors: [
                                        Colors.grey.withOpacity(0.0),
                                        Colors.black.withOpacity(0.9),
                                      ],
                                      stops: const [
                                        0.0,
                                        1.5
                                      ]),
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tap to view",
                                      style: GoogleFonts.rubik(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.8),
                                      ),
                                    ),
                                    Text(
                                      "${widget.eventLocation!}, ${building![0].toUpperCase()}${building!.substring(1)}",
                                      style: GoogleFonts.rubik(
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  splashColor: Colors.white.withOpacity(0.3),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            IndividualBuildingMapPage(
                                          fileName: image!,
                                          subtext:
                                              "${widget.eventLocation!}, ${building![0].toUpperCase()}${building!.substring(1)}",
                                        ),
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
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      "From ${widget.dtStart.hour.toString().padLeft(2, '0')}:${widget.dtStart.minute.toString().padLeft(2, '0')} to ${widget.dtEnd.hour.toString().padLeft(2, '0')}:${widget.dtEnd.minute.toString().padLeft(2, '0')}",
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                        color: widget.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      widget.eventName,
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (widget.eventDescription != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 4.0),
                      child: Text(
                        widget.eventDescription!,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 6),
                  Text(
                    "Free during event:",
                    style: GoogleFonts.rubik(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...friends,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
