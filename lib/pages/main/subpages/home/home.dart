import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/qr/qr_page.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';

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

  Future<void> loadPfp() async {
    final BaseAPI api = context.read<BaseAPI>();
    setState(() {
      if (api.user!.name != "") {
        name = api.user!.name;
      } else {
        name = "Anonymous";
      }
      pfpUrl =
          "https://appwrite.danieldb.uk/v1/storage/buckets/profiles/files/${api.user!.$id}/view?project=66fdb56000209ea9ac18";
      userId = api.user!.$id;
    });
  }

  @override
  void initState() {
    super.initState();
    loadPfp();
    loadData();
  }

  Future<String> loadCurrentEventFor(String userId) async {
    final BaseAPI api = context.read<BaseAPI>();
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
            uid: ''),
      );

      setState(() {
        nextLesson = next.summary;
        nextDetails =
            "${next.description.replaceAll("Teacher: ", "")} in ${next.location}";
      });
      final List<String> friends = await api.getFriends();
      for (final friend in friends) {
        final friendCurrentLesson = await loadCurrentEventFor(friend);
        final name = await api.getName(friend);
        if (friendCurrentLesson.contains("Aspire") ||
            friendCurrentLesson == "No Event") {
          setState(() {
            freeFriends.add(
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => IndividualFriendPage(
                        userId: friend,
                        name: name,
                        profilePicUrl:
                            "https://appwrite.danieldb.uk/v1/storage/buckets/profiles/files/$friend/view?project=66fdb56000209ea9ac18",
                      ),
                    ),
                  );
                },
                child: CircleAvatar(
                  radius: 25,
                  foregroundImage: CachedNetworkImageProvider(
                    "https://appwrite.danieldb.uk/v1/storage/buckets/profiles/files/$friend/view?project=66fdb56000209ea9ac18",
                  ),
                  child: Text(
                    friend[0].toUpperCase(),
                    style: GoogleFonts.rubik(
                      fontSize: 5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          });
        }
      }
    } catch (e) {
      print(e);
    }
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
            padding: const EdgeInsets.all(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
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
                                    ),
                                    child: Text(
                                      name[0].toUpperCase(),
                                      style: GoogleFonts.rubik(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
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
                        AspectRatio(
                          aspectRatio: 2 / 1,
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8, right: 8, top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next Event:',
                                    style: GoogleFonts.rubik(),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        nextLesson,
                                        style: GoogleFonts.rubik(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        AspectRatio(
                          aspectRatio: 2 / 1,
                          child: Card(
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Details:',
                                    style: GoogleFonts.rubik(),
                                  ),
                                  Expanded(
                                    child: SingleChildScrollView(
                                      scrollDirection: Axis.vertical,
                                      child: Text(
                                        nextDetails,
                                        style: GoogleFonts.rubik(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                        overflow: TextOverflow.visible,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    )),
                  ],
                ),
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
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_right),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                freeFriends.isEmpty
                    ? const SizedBox()
                    : Text(
                        'Free Now:',
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                Row(
                  children: [
                    Row(
                      children: freeFriends,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          freeFriends = [];
          loadData();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
