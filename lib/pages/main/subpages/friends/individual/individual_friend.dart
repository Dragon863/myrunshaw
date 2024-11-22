import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
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

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  Future<void> _refresh() async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents(userId: widget.userId);
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst syncing: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RunshawAppBar(
        title: widget.name,
        actions: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 16,
              foregroundImage: CachedNetworkImageProvider(
                widget.profilePicUrl,
                errorListener: (error) {},
              ),
              child: Text(
                widget.name != "" ? widget.name[0].toUpperCase() : "?",
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
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
                child: SizedBox(
                  width: double.infinity,
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
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                                      if (event.location != "") {
                                        return EventsCard(
                                          lessonName: event.summary,
                                          roomAndTeacher:
                                              "${event.description.replaceAll("Teacher: ", "")} in ${event.location}",
                                          timing: humaniseTime(
                                              event.start, event.end),
                                          color: Colors.blue,
                                        );
                                      } else {
                                        return EventsCard(
                                          lessonName: event.summary,
                                          roomAndTeacher: event.description,
                                          timing: humaniseTime(
                                              event.start, event.end),
                                          color: Colors.green.shade400,
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
