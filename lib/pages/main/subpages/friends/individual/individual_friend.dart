import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/split/split_timetable.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/user_info/user_info.dart';
import 'package:runshaw/pages/main/subpages/timetable/subpages/individual_event.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class IndividualFriendPage extends StatefulWidget {
  final String userId;
  final String name;
  final String profilePicUrl;

  const IndividualFriendPage({
    super.key,
    required this.userId,
    required this.name,
    required this.profilePicUrl,
  });

  @override
  State<IndividualFriendPage> createState() => _IndividualFriendPageState();
}

class _IndividualFriendPageState extends State<IndividualFriendPage> {
  List<Event> _events = [];
  String currentEvent = "Loading...";
  String? bus;

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  Future<void> _refresh() async {
    final BaseAPI api = context.read<BaseAPI>();
    final busNumber = await api.getBusFor(widget.userId);

    if (!mounted) return;
    setState(() {
      bus = busNumber;
    });

    final List<Event> events =
        await api.fetchEvents(userId: widget.userId, allowCache: true);
    if (events.isEmpty) {
      events.add(
        Event(
          summary: 'Events not found',
          location: '',
          start: DateTime.now(),
          end: DateTime.now(),
          description: '${widget.name} has not synced their timetable yet',
          uid: '',
        ),
      );
      setState(() {
        _events = events;
        currentEvent = "Not synced";
      });
    } else {
      setState(() {
        _events = events;
        currentEvent = fetchCurrentEvent(_events);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(
        title: widget.name,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UserInfoPage(
                    id: widget.userId,
                    name: widget.name,
                    profilePicUrl: widget.profilePicUrl,
                    bus: bus ?? "Not set",
                  ),
                ),
              );
            },
            icon: CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white,
              child: CircleAvatar(
                radius: 16,
                foregroundImage: CachedNetworkImageProvider(
                  widget.profilePicUrl,
                  errorListener: (error) {},
                ),
                child: Text(
                  getFirstNameCharacter(widget.name),
                  style: GoogleFonts.rubik(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 700,
                ),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Card(
                          elevation: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now:',
                                  style: GoogleFonts.rubik(),
                                ),
                                Text(
                                  currentEvent,
                                  style: GoogleFonts.rubik(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Card(
                        elevation: 1,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => SplitTimetablePage(
                                  friendId: widget.userId,
                                  friendName: widget.name,
                                ),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(9),
                          child: Padding(
                            padding: const EdgeInsets.all(4.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                const SizedBox(height: 4),
                                const Icon(Icons.vertical_split),
                                const SizedBox(height: 4),
                                Text(
                                  "Split",
                                  style: GoogleFonts.rubik(),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 150,
                        maxWidth: 700,
                      ),
                      child: ListView(
                        children: _events.isEmpty
                            ? const [
                                SizedBox(height: 20),
                                Center(
                                  child: SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  "Fetching Events...",
                                  textAlign: TextAlign.center,
                                )
                              ]
                            : _events
                                .fillGaps()
                                .sortEvents()
                                .groupByDay()
                                .entries
                                .map((entry) {
                                final date = entry.key;
                                final events = entry.value;
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        formatDayTitle(date),
                                        style: GoogleFonts.rubik(
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    ...events.map((event) {
                                      if (event.description != null) {
                                      } else {}
                                      if (event.location != "") {
                                        String eventDetails;
                                        if (event.description != null) {
                                          eventDetails =
                                              "${event.description!.replaceAll("Teacher: ", "")} in ${event.location}";
                                        } else {
                                          eventDetails =
                                              event.location ?? 'Undefined';
                                        }
                                        return EventsCard(
                                          lessonName: event.summary == ''
                                              ? "Exam"
                                              : event.summary,
                                          roomAndTeacher: eventDetails,
                                          timing: humaniseTime(
                                              event.start, event.end),
                                          color: event.summary != ""
                                              ? Colors.blue
                                              : Colors.red,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    IndividualEventPage(
                                                  eventName: event.summary,
                                                  eventDescription:
                                                      event.description,
                                                  eventLocation: event.location,
                                                  dtStart: event.start,
                                                  dtEnd: event.end,
                                                  color: event.summary != ""
                                                      ? Colors.blue
                                                      : Colors.red,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      } else {
                                        return EventsCard(
                                          lessonName: event.summary == ''
                                              ? "Exam"
                                              : event.summary,
                                          roomAndTeacher:
                                              event.description ?? '',
                                          timing: humaniseTime(
                                              event.start, event.end),
                                          color: event.summary == ''
                                              ? Colors.red
                                              : Colors.green.shade400,
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    IndividualEventPage(
                                                  eventName: event.summary,
                                                  eventDescription:
                                                      event.description,
                                                  eventLocation: event.location,
                                                  dtStart: event.start,
                                                  dtEnd: event.end,
                                                  color: event.summary == ''
                                                      ? Colors.red
                                                      : Colors.green.shade400,
                                                ),
                                              ),
                                            );
                                          },
                                        );
                                      }
                                    }),
                                  ],
                                );
                              }).toList(),
                      ),
                    ),
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
