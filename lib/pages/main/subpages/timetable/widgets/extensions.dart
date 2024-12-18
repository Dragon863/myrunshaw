import 'package:runshaw/pages/sync/sync_controller.dart';

extension EventScheduleFiller on List<Event> {
  List<Event> fillGaps({bool today = false}) {
    if (isEmpty) return this;
    if (length == 1 && this[0].summary.contains("Events not found")) {
      return this;
    }
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

    if (!today) return filledEvents;

    final now = DateTime.now();
    final todayStart =
        now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final todayEnd =
        now.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    return filledEvents
        .where((event) =>
            event.start.isAfter(todayStart) && event.end.isBefore(todayEnd))
        .toList();
  }
}
