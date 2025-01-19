import 'package:intl/intl.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';

extension EventListExtensions on List<Event> {
  Map<DateTime, List<Event>> groupByDay({bool todayOnly = false}) {
    if (todayOnly) {
      final now = DateTime.now();
      final toReturn = {
        DateTime(now.year, now.month, now.day): where((event) =>
            event.start.year == now.year &&
            event.start.month == now.month &&
            event.start.day == now.day).toList()
      };
      return toReturn;
    }
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


String humaniseTime(DateTime start, DateTime end) {
  return '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')} - ${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';
}

String fetchCurrentEvent(events) {
  final now = DateTime.now();
  final currentEvent = events.firstWhere(
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

String fetchCurrentEventAt(events, DateTime time) {
  final currentEvent = events.firstWhere(
    (event) {
      return event.start.isBefore(time) && event.end.isAfter(time);
    },
    orElse: () => Event(
        summary: 'No Event',
        location: '',
        start: time,
        end: time,
        description: '',
        uid: ''),
  );
  return currentEvent.summary;
}
