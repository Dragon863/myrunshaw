import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/subpages/individual_event.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/pages/sync/sync.dart';
import 'package:runshaw/utils/models/event.dart';
import 'package:runshaw/utils/models/event_category.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

class TimetableList extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ListView(
      physics: dense
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      shrinkWrap: true,
      children: events.isEmpty && !dense
          ? [
              const SizedBox(height: 20),
              Center(
                child: SizedBox.square(
                  dimension: 30,
                  child: LoadingIndicator(),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Fetching Events...",
                textAlign: TextAlign.center,
              )
            ]
          : events
              .fillGaps(today: todayOnly)
              .sortEvents()
              .groupByDay(todayOnly: todayOnly)
              .entries
              .map(
              (entry) {
                final date = entry.key;
                final events = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!todayOnly)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          formatDayTitle(date),
                          style: GoogleFonts.rubik(
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ...events.map((event) => _buildEventCard(context, event)),
                  ],
                );
              },
            ).toList(),
    );
  }

  Widget _buildEventCard(BuildContext context, Event event) {
    final category = categoriseEvent(event);
    final isExam = category == EventCategory.exam;

    return EventsCard(
      lessonName: isExam ? "Exam" : event.summary,
      roomAndTeacher: _eventDetails(event),
      timing: humaniseTime(event.start, event.end),
      color: category.color,
      dense: dense,
      onTap: () => _handleEventTap(context, event, category),
    );
  }

  String _eventDetails(Event event) {
    final location = event.location;
    if (location == null || location.isEmpty) {
      return event.description ?? '';
    }

    final description = event.description;
    if (description == null) return location;

    return "${description.replaceAll("Teacher: ", "")} in $location";
  }

  void _handleEventTap(
    BuildContext context,
    Event event,
    EventCategory category,
  ) async {
    if (category == EventCategory.exam) {
      showExamAlert(context);
      return;
    }

    if (event.description
            ?.toLowerCase()
            .contains("try syncing your timetable") ==
        true) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SyncPage(),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IndividualEventPage(
          eventName: event.summary,
          eventDescription: event.description,
          eventLocation: event.location,
          dtStart: event.start,
          dtEnd: event.end,
          color: category.color,
        ),
      ),
    );
  }
}
