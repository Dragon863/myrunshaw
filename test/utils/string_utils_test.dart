import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/utils/string_utils.dart';

void main() {
  group('truncateName', () {
    test('returns short names unchanged', () {
      expect(truncateName('Alice'), equals('Alice'));
    });

    test('returns a name of exactly 18 characters unchanged', () {
      // 18 chars exactly — should NOT be truncated
      const name = 'ABCDEFGHIJKLMNOPQR'; // 18 chars
      expect(truncateName(name), equals(name));
    });

    test('truncates a name longer than 18 characters', () {
      // 19 chars — should be truncated to first 15 + '...'
      const name = 'ABCDEFGHIJKLMNOPQRS'; // 19 chars
      expect(truncateName(name), equals('ABCDEFGHIJKLMNO...'));
    });

    test('truncated result is at most 18 characters long', () {
      const name = 'A very long name that goes well beyond the limit';
      expect(truncateName(name).length, lessThanOrEqualTo(18));
    });

    test('handles empty string', () {
      expect(truncateName(''), equals(''));
    });

    test('a name of exactly 19 characters is truncated', () {
      const name = '1234567890123456789'; // 19 chars
      expect(truncateName(name), equals('123456789012345...'));
    });
  });
}
