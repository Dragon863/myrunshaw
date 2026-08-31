import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/utils/models/event.dart';

/// Builds a minimal [Event] with the given start/end times and optional fields.
Event makeEvent({
  required DateTime start,
  required DateTime end,
  String summary = 'Lesson',
  String uid = 'uid-1',
  String? description,
  String? location,
}) {
  return Event(
    summary: summary,
    start: start,
    end: end,
    uid: uid,
    description: description,
    location: location,
  );
}

void main() {
  group('EventScheduleFiller.sortEvents', () {
    test('sorts events by start time ascending', () {
      final d = DateTime(2024, 9, 2);
      final events = [
        makeEvent(
          start: d.copyWith(hour: 13),
          end: d.copyWith(hour: 14),
          uid: 'c',
        ),
        makeEvent(
          start: d.copyWith(hour: 9),
          end: d.copyWith(hour: 10),
          uid: 'a',
        ),
        makeEvent(
          start: d.copyWith(hour: 11),
          end: d.copyWith(hour: 12),
          uid: 'b',
        ),
      ];

      final sorted = events.sortEvents();

      expect(sorted[0].uid, equals('a'));
      expect(sorted[1].uid, equals('b'));
      expect(sorted[2].uid, equals('c'));
    });

    test('returns the same list instance (in-place sort)', () {
      final events = [
        makeEvent(
          start: DateTime(2024, 9, 2, 11),
          end: DateTime(2024, 9, 2, 12),
        ),
      ];
      final result = events.sortEvents();
      expect(identical(result, events), isTrue);
    });
  });

  group('EventScheduleFiller.fillGaps', () {
    test('returns empty list unchanged', () {
      final List<Event> events = [];
      expect(events.fillGaps(), isEmpty);
    });

    test('passes through single "Events not found" entry unchanged', () {
      final events = [
        makeEvent(
          summary: 'Events not found',
          start: DateTime(2024, 9, 2, 9),
          end: DateTime(2024, 9, 2, 10),
        ),
      ];
      final result = events.fillGaps();
      expect(result.length, equals(1));
      expect(result.first.summary, equals('Events not found'));
    });

    test('inserts an Aspire gap between two non-adjacent lessons', () {
      final d = DateTime(2024, 9, 2);
      final events = [
        makeEvent(
          summary: 'Maths',
          start: d.copyWith(hour: 9),
          end: d.copyWith(hour: 10),
          uid: 'math',
        ),
        makeEvent(
          summary: 'English',
          start: d.copyWith(hour: 11),
          end: d.copyWith(hour: 12),
          uid: 'eng',
        ),
      ];

      final result = events.fillGaps();

      // Expect: Maths → Aspire (10:00–11:00) → English
      final aspire = result.firstWhere(
        (e) => e.summary == 'Aspire',
        orElse: () => throw TestFailure('No Aspire event found'),
      );
      expect(aspire.start, equals(d.copyWith(hour: 10)));
      expect(aspire.end, equals(d.copyWith(hour: 11)));
    });

    test('inserts a morning Aspire event when first lesson starts after 09:00',
        () {
      final d = DateTime(2024, 9, 2);
      final events = [
        makeEvent(
          summary: 'Late Lesson',
          start: d.copyWith(hour: 10),
          end: d.copyWith(hour: 11),
          uid: 'late',
        ),
      ];

      final result = events.fillGaps();

      final morningAspire = result.firstWhere(
        (e) => e.summary == 'Aspire' && e.start.hour == 9,
        orElse: () => throw TestFailure('No morning Aspire event found'),
      );
      expect(morningAspire.start.hour, equals(9));
      expect(morningAspire.end, equals(d.copyWith(hour: 10)));
    });

    test('does not insert morning Aspire when lesson starts at exactly 09:00',
        () {
      final d = DateTime(2024, 9, 2);
      final events = [
        makeEvent(
          summary: 'On Time Lesson',
          start: d.copyWith(hour: 9),
          end: d.copyWith(hour: 10),
          uid: 'ontime',
        ),
      ];

      final result = events.fillGaps();

      final morningAspires = result
          .where((e) => e.summary == 'Aspire' && e.uid.contains('morning'))
          .toList();
      expect(morningAspires, isEmpty);
    });

    test('does not insert gap event between adjacent lessons', () {
      final d = DateTime(2024, 9, 2);
      final events = [
        makeEvent(
          summary: 'Lesson A',
          start: d.copyWith(hour: 9),
          end: d.copyWith(hour: 10),
          uid: 'a',
        ),
        makeEvent(
          summary: 'Lesson B',
          start: d.copyWith(hour: 10),
          end: d.copyWith(hour: 11),
          uid: 'b',
        ),
      ];

      final result = events.fillGaps();
      final aspireEvents = result.where((e) => e.summary == 'Aspire').toList();
      expect(aspireEvents, isEmpty);
    });
  });
}
