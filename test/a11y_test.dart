import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_widgets.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/events_card.dart';

void main() {
  group('Accessibility Guidelines & Semantics Tests', () {
    testWidgets('BusCard merges subtree semantics into unified node',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BusCard(
              bus: BusInfo(
                number: '760',
                bay: 'A1',
                bayColor: Colors.red,
                status: BusStatus.arrived,
                arrivedTimeAgo: '5m ago',
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      // Verify labeled tap target guideline
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      // Verify semantics node combines bus information
      expect(
        tester.getSemantics(find.byType(BusCard)),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: '760\nArrived 5m ago\nA1',
        ),
      );

      handle.dispose();
    });

    testWidgets('EventsCard provides unified semantic announcement',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EventsCard(
              lessonName: 'Computer Science',
              roomAndTeacher: 'Teacher: Mr Smith in Room T1',
              timing: '09:00 - 10:30',
              color: Colors.blue,
              onTap: () {},
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      expect(
        tester.getSemantics(find.byType(EventsCard)),
        matchesSemantics(
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label:
              '09:00 - 10:30\nComputer Science\nTeacher: Mr Smith in Room T1',
        ),
      );

      handle.dispose();
    });

    testWidgets('IconButtons provide non-empty accessible labels',
        (WidgetTester tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IconButton(
              tooltip: 'Delete item',
              icon: const Icon(Icons.delete, semanticLabel: 'Delete item'),
              onPressed: () {},
            ),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      handle.dispose();
    });
  });
}
