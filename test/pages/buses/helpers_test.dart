import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/pages/main/subpages/buses/helpers.dart';

void main() {
  group('calculatePosition', () {
    group('special T bays', () {
      test('T1 returns fixed coordinates', () {
        final pos = calculatePosition('T1');
        expect(pos[0], closeTo(0.86, 0.001));
        expect(pos[1], closeTo(0.52, 0.001));
      });

      test('T2 returns fixed coordinates', () {
        final pos = calculatePosition('T2');
        expect(pos[0], closeTo(0.86, 0.001));
        expect(pos[1], closeTo(0.37, 0.001));
      });

      test('T3 returns fixed coordinates', () {
        final pos = calculatePosition('T3');
        expect(pos[0], closeTo(0.86, 0.001));
        expect(pos[1], closeTo(0.22, 0.001));
      });
    });

    group('Row A bays', () {
      test('A1 has correct y-percentage for row A', () {
        final pos = calculatePosition('A1');
        expect(pos[1], closeTo(0.32, 0.001));
      });

      test('A1 has the expected x-percentage', () {
        // Bay 1: x = 0.70 - (1-1)*0.105 = 0.70
        final pos = calculatePosition('A1');
        expect(pos[0], closeTo(0.70, 0.001));
      });

      test('A2 x-percentage is shifted left by 0.105 from A1', () {
        final a1 = calculatePosition('A1');
        final a2 = calculatePosition('A2');
        expect(a2[0], closeTo(a1[0] - 0.105, 0.001));
      });

      test('A3 x-percentage is shifted left by 0.105 from A2', () {
        final a2 = calculatePosition('A2');
        final a3 = calculatePosition('A3');
        expect(a3[0], closeTo(a2[0] - 0.105, 0.001));
      });
    });

    group('Row B bays', () {
      test('B1 has correct y-percentage for row B', () {
        final pos = calculatePosition('B1');
        expect(pos[1], closeTo(0.42, 0.001));
      });

      test('B1 has the same x-percentage as A1', () {
        final a1 = calculatePosition('A1');
        final b1 = calculatePosition('B1');
        expect(b1[0], closeTo(a1[0], 0.001));
      });
    });

    group('Row C bays', () {
      test('C1 has correct y-percentage for row C', () {
        final pos = calculatePosition('C1');
        expect(pos[1], closeTo(0.52, 0.001));
      });

      test('C1 has the same x-percentage as A1 and B1', () {
        final a1 = calculatePosition('A1');
        final c1 = calculatePosition('C1');
        expect(c1[0], closeTo(a1[0], 0.001));
      });
    });

    test('returns a list of exactly 2 elements', () {
      final pos = calculatePosition('A1');
      expect(pos.length, equals(2));
    });
  });

  group('BusStatus', () {
    test('has waiting and arrived values', () {
      expect(BusStatus.values,
          containsAll([BusStatus.waiting, BusStatus.arrived]));
    });
  });
}
