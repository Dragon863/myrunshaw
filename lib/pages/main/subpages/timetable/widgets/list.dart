import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';

class TimetableList extends StatefulWidget {
  final List<Event> events;
  final bool dense;
  final bool todayOnly;

  const TimetableList({
    super.key,
    required this.events,
    this.dense = false,
    this.todayOnly = false,
  });

  @override
  State<TimetableList> createState() => _TimetableListState();
}

class _TimetableListState extends State<TimetableList> {
  final List<Event> _events = [];
  bool emptyAndDense = false;

  @override
  void initState() {
    _events.addAll(widget.events);
    if (widget.events.isEmpty && widget.dense) {
      emptyAndDense = true;
    }
    super.initState();
  }

  String _humaniseTime(DateTime start, DateTime end) {
    return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: widget.dense
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      children: widget.events.isEmpty && !emptyAndDense
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
          : widget.events
              .fillGaps(today: widget.todayOnly)
              .groupByDay(todayOnly: widget.todayOnly)
              .entries
              .map(
              (entry) {
                final date = entry.key;
                final events = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!widget.todayOnly)
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
                        String eventDetails;
                        if (event.description != null) {
                          eventDetails =
                              "${event.description!.replaceAll("Teacher: ", "")} in ${event.location}";
                        } else {
                          eventDetails = event.location ?? 'Undefined';
                        }
                        return EventsCard(
                          lessonName:
                              event.summary == '' ? "Exam" : event.summary,
                          roomAndTeacher: eventDetails,
                          timing: _humaniseTime(event.start, event.end),
                          color: event.summary != "" ? Colors.blue : Colors.red,
                          dense: widget.dense,
                        );
                      } else {
                        return EventsCard(
                          lessonName:
                              event.summary == '' ? "Exam" : event.summary,
                          roomAndTeacher: event.description ?? '',
                          timing: _humaniseTime(event.start, event.end),
                          color: Colors.green.shade400,
                          dense: widget.dense,
                        );
                      }
                    }),
                  ],
                );
              },
            ).toList(),
    );
  }
}
