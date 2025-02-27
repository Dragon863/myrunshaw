import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_map_view.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/main/subpages/home/inapp/inapp.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/list.dart';
import 'package:runshaw/pages/qr/qr_page.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? pfpUrl;
  String name = "Loading...";
  String userId = "";
  String nextLesson = "Loading...";
  String nextDetails = "Loading...";
  List<Widget> freeFriends = [];
  bool loading = false;
  List<Event> events = [];
  List<Widget> busWidgets = [];

  Future<void> loadPfp() async {
    final BaseAPI api = context.read<BaseAPI>();
    await api.refreshUser();
    setState(() {
      if (api.user!.name != "") {
        if (name.length > 15) {
          name = "${api.user!.name.substring(0, 15)}...";
        } else {
          name = api.user!.name;
        }
      } else {
        name = "Name not set";
      }
      userId = api.user!.$id;
      pfpUrl = api.getPfpUrl(userId);
    });
  }

  Future<void> loadEvents() async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents(userId: api.user!.$id);
      setState(() {
        this.events = events;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst fetching events: $e"),
        ),
      );
    }
  }

  @override
  void initState() {
    loadData();
    loadEvents();
    loadPfp();
    super.initState();
    checkInAppAlerts(context);
  }

  Future<String> loadCurrentEventFor(String userId) async {
    final BaseAPI api = context.read<BaseAPI>();
    if (api.cachedPfpVersions.isEmpty) {
      await api.cachePfpVersions();
    }
    try {
      final List<Event> events = await api.fetchEvents(userId: userId);
      final String current = fetchCurrentEvent(events);
      return current;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst syncing: $e"),
        ),
      );
      return "internal:ignore";
    }
  }

  Future<void> loadData() async {
    if (loading) {
      return;
    }
    loading = true;
    freeFriends.clear();
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents(userId: api.user!.$id);
      final now = DateTime.now();
      final Event next = events.firstWhere(
        (event) {
          return event.start.isAfter(now);
        },
        orElse: () => Event(
          summary: 'No Event',
          location: '',
          start: now,
          end: now,
          description: '',
          uid: '',
        ),
      );

      if (next.summary == "No Event") {
        setState(() {
          nextLesson = "No Event";
          nextDetails = "";
        });
      } else {
        setState(() {
          nextLesson = next.summary;
          nextDetails = next.description == null
              ? "No Description"
              : "${next.description!.replaceAll("Teacher: ", "")} in ${next.location}";
        });
      }
      final busNumber = await api.getBusNumber();
      final List<String> extraBuses = await api.getAllBuses();
      if (busNumber != null &&
          !extraBuses.contains(busNumber) &&
          busNumber != "") {
        extraBuses.add(busNumber);
      }

      // This expression gets the buses, replaces the letters with nothing, then sorts them by number.
      // This is so that the buses are in numerical order, and while it is a litte messy, it works well.
      extraBuses.sort(
        (a, b) => int.parse(a.replaceAll(RegExp(r'[A-Z]'), "")).compareTo(
          int.parse(b.replaceAll(RegExp(r'[A-Z]'), "")),
        ),
      );

      setState(() => busWidgets.clear());

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

      int index = 0;
      final busBays = await api.getBusBays();

      for (final bus in busBays.keys) {
        if (!extraBuses.contains(bus)) {
          continue;
        }

        final bay = busBays[bus];
        if ((bay != "RSP_NYA" &&
            bay != null &&
            bay != "0" &&
            (DateTime.now().hour < 17 || kDebugMode))) {
          // Before 5PM, and bus has arrived
          setState(() {
            busWidgets.add(
              Card.filled(
                color: colors[index % colors.length],
                child: ListTile(
                  title: Text(
                    'The $bus is in bay $bay!',
                    style: GoogleFonts.rubik(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  trailing:
                      const Icon(Icons.directions_bus, color: Colors.white),
                  onTap: () async {
                    if (bay == "RSP_NYA" || bay == "0") {
                      // Response-Not-Yet-Arrived
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Bus has not arrived yet (this should be impossible, please report this)",
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusMapViewPage(
                            bay: bay,
                            busNumber: bus,
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            );
          });
          index++;
        }
      }

      final List friends = await api.getFriends();
      for (final friend in friends) {
        final String uid = friend["userid"];
        final friendCurrentLesson = await loadCurrentEventFor(uid);
        final name = await api.getName(uid);
        if (friendCurrentLesson.contains("Aspire") ||
            friendCurrentLesson == "No Event") {
          setState(() {
            freeFriends.add(
              GestureDetector(
                onLongPress: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("$name (tap to view)"),
                    ),
                  );
                },
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => IndividualFriendPage(
                        userId: uid,
                        name: name,
                        profilePicUrl: api.getPfpUrl(
                            uid), // NOT userId as I learned when everybody's picture turned into a cat!
                      ),
                    ),
                  );
                },
                child: Align(
                  widthFactor: 0.8,
                  child: CircleAvatar(
                    radius: 25,
                    foregroundImage: CachedNetworkImageProvider(
                      api.getPfpUrl(uid),
                      errorListener: (error) {},
                    ),
                    child: Text(
                      getFirstNameCharacter(name),
                      style: GoogleFonts.rubik(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      //throw e;
    }
    loading = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 500,
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              left: 6,
              right: 6,
            ),
            child: ListView(
              children: [
                ...busWidgets,
                Row(
                  children: [
                    Expanded(
                      // Profile card
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    foregroundImage: CachedNetworkImageProvider(
                                      pfpUrl ?? "",
                                      errorListener: (error) {},
                                    ),
                                    child: Text(
                                      getFirstNameCharacter(name),
                                      style: GoogleFonts.rubik(
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: GoogleFonts.rubik(
                                      fontSize: 22,
                                    ),
                                  ),
                                  Text(
                                    userId,
                                    style: GoogleFonts.rubik(
                                      fontWeight: FontWeight.w200,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Next lessons
                        AspectRatio(
                          aspectRatio: 2 / 1,
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Next Event:',
                                      style: GoogleFonts.rubik(),
                                    ),
                                    Text(
                                      nextLesson,
                                      style: GoogleFonts.rubik(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Next event details
                        AspectRatio(
                          aspectRatio: 2 / 1,
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 8),
                                    Text(
                                      'Details:',
                                      style: GoogleFonts.rubik(),
                                    ),
                                    Text(
                                      nextDetails,
                                      style: GoogleFonts.rubik(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      overflow: TextOverflow.visible,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
                // QR Code
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      splashColor: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        final BaseAPI api = context.read<BaseAPI>();
                        final String code = await api.getCode();
                        if (code == "000000") {
                          showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Error"),
                                  content: const Text(
                                      "Your QR code is not available, as you signed up with an email address."),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("OK"),
                                    ),
                                  ],
                                );
                              });
                        } else {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) {
                              return QrCodePage(
                                  qrUrl:
                                      "https://api.qrserver.com/v1/create-qr-code/?data=${context.read<BaseAPI>().user!.$id.toUpperCase()}-$code");
                            }),
                          );
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "QR Code",
                                  style: GoogleFonts.rubik(
                                    fontSize: 22,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.keyboard_arrow_right),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Free friend display title
                freeFriends.isEmpty
                    ? const SizedBox()
                    : Text(
                        'Free Now:',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                // Display free friends (wrap to flow to next line if necessary)
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Wrap(
                    runSpacing: 2,
                    children: freeFriends,
                  ),
                ),
                // Conditional display of today's events
                events.where((event) {
                  final now = DateTime.now();
                  final todayStart = now.copyWith(
                      hour: 0, minute: 0, second: 0, millisecond: 0);
                  final todayEnd = now.copyWith(
                      hour: 23, minute: 59, second: 59, millisecond: 999);
                  final today = events
                      .where((event) =>
                          event.start.isAfter(todayStart) &&
                          event.end.isBefore(todayEnd))
                      .toList();
                  return today.isNotEmpty;
                }).isNotEmpty
                    // Just checks if there are any events today
                    ? Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Today:',
                          style: GoogleFonts.rubik(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    : const SizedBox(),
                // Display today's events
                events != []
                    ? TimetableList(
                        events: events,
                        dense: true,
                        todayOnly: true,
                      )
                    : const SizedBox(),
                const SizedBox(height: 8),
                if (userId == "row23207169")
                  // easter egg for a friend
                  RotatedBox(
                    quarterTurns: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://appwrite.danieldb.uk/v1/storage/buckets/cdn/files/charlie/view?project=66fdb56000209ea9ac18",
                        width: 80,
                        height: 80,
                      ),
                    ),
                  )
                else
                  const SizedBox(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          loadData();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
