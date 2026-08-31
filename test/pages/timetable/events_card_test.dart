import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';

/// Wraps [widget] in a minimal [MaterialApp] so it has access to theme and
/// directionality — required by Material widgets.
Widget wrap(Widget widget) => MaterialApp(home: Scaffold(body: widget));

void main() {
  group('EventsCard', () {
    group('content rendering', () {
      testWidgets('displays the timing text', (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Computer Science',
            roomAndTeacher: 'Mr Smith in T1',
            timing: '09:00 - 10:30',
            color: Colors.blue,
          ),
        ));

        expect(find.text('09:00 - 10:30'), findsOneWidget);
      });

      testWidgets('displays the lesson name', (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Computer Science',
            roomAndTeacher: 'Mr Smith in T1',
            timing: '09:00 - 10:30',
            color: Colors.blue,
          ),
        ));

        expect(find.text('Computer Science'), findsOneWidget);
      });

      testWidgets('displays room and teacher text in normal mode',
          (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Maths',
            roomAndTeacher: 'Mrs Jones in M2',
            timing: '10:30 - 12:00',
            color: Colors.orange,
          ),
        ));

        expect(find.text('Mrs Jones in M2'), findsOneWidget);
      });
    });

    group('dense mode', () {
      testWidgets('hides room/teacher text when dense is true', (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Biology',
            roomAndTeacher: 'Dr Brown in S3',
            timing: '13:00 - 14:30',
            color: Colors.green,
            dense: true,
          ),
        ));

        expect(find.text('Dr Brown in S3'), findsNothing);
      });

      testWidgets('still shows lesson name and timing in dense mode',
          (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Biology',
            roomAndTeacher: 'Dr Brown in S3',
            timing: '13:00 - 14:30',
            color: Colors.green,
            dense: true,
          ),
        ));

        expect(find.text('Biology'), findsOneWidget);
        expect(find.text('13:00 - 14:30'), findsOneWidget);
      });
    });

    group('arrow icon visibility', () {
      testWidgets('shows arrow icon when onTap is provided', (tester) async {
        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Physics',
            roomAndTeacher: 'Mr Lee in P1',
            timing: '14:30 - 16:00',
            color: Colors.purple,
            onTap: () {},
          ),
        ));

        expect(find.byIcon(Icons.keyboard_arrow_right), findsOneWidget);
      });

      testWidgets('hides arrow icon when onTap is null', (tester) async {
        await tester.pumpWidget(wrap(
          const EventsCard(
            lessonName: 'Physics',
            roomAndTeacher: 'Mr Lee in P1',
            timing: '14:30 - 16:00',
            color: Colors.purple,
          ),
        ));

        expect(find.byIcon(Icons.keyboard_arrow_right), findsNothing);
      });
    });

    group('tap interaction', () {
      testWidgets('calls onTap callback when card is tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(wrap(
          EventsCard(
            lessonName: 'Chemistry',
            roomAndTeacher: 'Ms White in C4',
            timing: '09:00 - 10:30',
            color: Colors.teal,
            onTap: () => tapped = true,
          ),
        ));

        await tester.tap(find.byType(EventsCard));
        await tester.pump();

        expect(tapped, isTrue);
      });
    });
  });
}
