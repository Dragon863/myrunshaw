import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_widgets.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';

/// Wraps [widget] in a minimal [MaterialApp] so it has access to theme and
/// directionality — required by most Material widgets.
Widget wrap(Widget widget) => MaterialApp(home: Scaffold(body: widget));

void main() {
  group('BusCard', () {
    group('waiting state', () {
      testWidgets('displays the bus number', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '760',
              status: BusStatus.waiting,
            ),
          ),
        ));

        expect(find.text('760'), findsOneWidget);
      });

      testWidgets('shows "Not arrived yet" subtitle', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '760',
              status: BusStatus.waiting,
            ),
          ),
        ));

        expect(find.text('Not arrived yet'), findsOneWidget);
      });

      testWidgets('bay badge shows "..." when waiting', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '760',
              status: BusStatus.waiting,
            ),
          ),
        ));

        expect(find.text('...'), findsOneWidget);
      });

      testWidgets('uses clock icon for waiting status', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '760',
              status: BusStatus.waiting,
            ),
          ),
        ));

        expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
      });
    });

    group('arrived state', () {
      testWidgets('displays the bus number', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '762',
              bay: 'B2',
              bayColor: Colors.blue,
              status: BusStatus.arrived,
              arrivedTimeAgo: '3m ago',
            ),
          ),
        ));

        expect(find.text('762'), findsOneWidget);
      });

      testWidgets('shows "Arrived X ago" subtitle', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '762',
              bay: 'B2',
              bayColor: Colors.blue,
              status: BusStatus.arrived,
              arrivedTimeAgo: '3m ago',
            ),
          ),
        ));

        expect(find.text('Arrived 3m ago'), findsOneWidget);
      });

      testWidgets('bay badge displays the bay label', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '762',
              bay: 'B2',
              bayColor: Colors.blue,
              status: BusStatus.arrived,
              arrivedTimeAgo: '3m ago',
            ),
          ),
        ));

        expect(find.text('B2'), findsOneWidget);
      });

      testWidgets('uses check icon for arrived status', (tester) async {
        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '762',
              bay: 'B2',
              bayColor: Colors.blue,
              status: BusStatus.arrived,
              arrivedTimeAgo: '2m ago',
            ),
          ),
        ));

        expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      });
    });

    group('tap interaction', () {
      testWidgets('calls onTap when card is tapped', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(wrap(
          BusCard(
            bus: const BusInfo(
              number: '760',
              bay: 'A1',
              bayColor: Colors.red,
              status: BusStatus.arrived,
              arrivedTimeAgo: '1m ago',
            ),
            onTap: () => tapped = true,
          ),
        ));

        await tester.tap(find.byType(BusCard));
        await tester.pump();

        expect(tapped, isTrue);
      });

      testWidgets('does not throw when onTap is null', (tester) async {
        await tester.pumpWidget(wrap(
          const BusCard(
            bus: BusInfo(
              number: '760',
              status: BusStatus.waiting,
            ),
          ),
        ));

        // Should not throw even with no callback
        await tester.tap(find.byType(BusCard));
        await tester.pump();
      });
    });
  });

  group('BayBadge', () {
    testWidgets('renders the bay label text', (tester) async {
      await tester.pumpWidget(wrap(
        BayBadge(
          bus: const BusInfo(
            number: '760',
            bay: 'C3',
            bayColor: Colors.green,
            status: BusStatus.arrived,
          ),
          colorAt: (_) => Colors.green,
        ),
      ));

      expect(find.text('C3'), findsOneWidget);
    });

    testWidgets('renders "..." when bus is waiting', (tester) async {
      await tester.pumpWidget(wrap(
        BayBadge(
          bus: const BusInfo(
            number: '760',
            status: BusStatus.waiting,
          ),
          colorAt: (_) => Colors.grey,
        ),
      ));

      expect(find.text('...'), findsOneWidget);
    });
  });
}
