import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';
import 'package:runshaw/pages/sync/sync.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:intl/intl.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  List<Event> _events = [];
  String currentTitle = 'Loading...';

  @override
  void initState() {
    _refresh();
    currentTitle = _fetchCurrentEvent();
    super.initState();
  }

  Future<void> _refresh() async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents();
      setState(() {
        _events = events;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst syncing: $e"),
        ),
      );
    }
  }

  String _humaniseTime(DateTime start, DateTime end) {
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  String _fetchCurrentEvent() {
    final now = DateTime.now();
    final currentEvent = _events.firstWhere(
      (event) {
        return event.start.isBefore(now) && event.end.isAfter(now);
      },
      orElse: () => Event(
          summary: 'No Event',
          location: '',
          start: now,
          end: now,
          description: '',
          uid: ''),
    );
    return currentEvent.summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current:',
                      style: GoogleFonts.rubik(),
                    ),
                    Text(
                      currentTitle,
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
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                children: _events.fillGaps().groupByDay().entries.map((entry) {
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
                            timing: _humaniseTime(event.start, event.end),
                            color: Colors.blue,
                          );
                        } else {
                          return EventsCard(
                            lessonName: event.summary,
                            roomAndTeacher: event.description,
                            timing: _humaniseTime(event.start, event.end),
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return const SyncPage();
            },
          ).then((value) {
            Future.delayed(const Duration(milliseconds: 500), () {
              // Allow changes to propogate
              _refresh();
            });
          });
        },
        child: const Icon(Icons.sync),
      ),
    );
  }
}

extension EventListExtensions on List<Event> {
  Map<DateTime, List<Event>> groupByDay() {
    final groups = <DateTime, List<Event>>{};
    for (var event in this) {
      final date =
          DateTime(event.start.year, event.start.month, event.start.day);
      if (!groups.containsKey(date)) {
        groups[date] = [];
      }
      groups[date]!.add(event);
    }
    return Map.fromEntries(
        groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

String formatDayTitle(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  if (date == today) return 'Today';
  if (date == tomorrow) return 'Tomorrow';

  final dateFormatted = DateFormat('EEEE d MMM').format(date);

  return dateFormatted;
}

extension EventScheduleFiller on List<Event> {
  List<Event> fillGaps() {
    if (isEmpty) return this;
    final filledEvents = <Event>[];

    for (int index = 0; index < length; index++) {
      // Index does NOT reset to zero for each day - this list contains every calendar event
      final currentEvent = this[index];
      final dayStart = currentEvent.start.copyWith(hour: 9, minute: 0);
      final dayEnd = currentEvent.start.copyWith(hour: 15, minute: 40);

      filledEvents.add(currentEvent);

      // If there is a gap between the current event and the next event (or end of the day), fill it with an Aspire event
      if (index < length - 1) {
        final nextEvent = this[index + 1];
        if (currentEvent.end.isBefore(nextEvent.start) &&
            currentEvent.end.isBefore(dayEnd)) {
          DateTime freePeriodEnd = nextEvent.start;
          if (nextEvent.start.isAfter(dayEnd)) {
            freePeriodEnd = dayEnd;
          }
          filledEvents.add(Event(
            summary: 'Aspire',
            description: 'Aspire (Free Period)',
            location: '',
            start: currentEvent.end,
            end: freePeriodEnd,
            uid: 'aspire-${currentEvent.end.millisecondsSinceEpoch}',
          ));
        }
      }

      if (index == 0 ||
          (index > 0 && this[index - 1].start.day != currentEvent.start.day)) {
        if (currentEvent.start.isAfter(dayStart)) {
          filledEvents.insert(
            filledEvents.length - 1,
            Event(
              summary: 'Aspire',
              description: 'Aspire (Free Period)',
              location: '',
              start: dayStart,
              end: currentEvent.start,
              uid:
                  'aspire-morning-${currentEvent.start.millisecondsSinceEpoch}',
            ),
          );
        }
      }
    }

    return filledEvents;
  }
}
