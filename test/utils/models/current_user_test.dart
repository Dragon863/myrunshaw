import 'package:flutter_test/flutter_test.dart';
import 'package:runshaw/utils/models/current_user.dart';

void main() {
  group('CurrentUser.fromJson', () {
    test('parses all fields correctly from a complete JSON object', () {
      final json = {
        'studentId': 'stu12345',
        'name': 'Jane Smith',
        'profilePicVersion': 3,
        'hasTimetableLinked': true,
      };

      final user = CurrentUser.fromJson(json);

      expect(user.id, equals('stu12345'));
      expect(user.name, equals('Jane Smith'));
      expect(user.profilePicVersion, equals(3));
      expect(user.hasTimetableLinked, isTrue);
    });

    test('falls back to empty string when studentId is missing', () {
      final json = {'name': 'No ID'};
      final user = CurrentUser.fromJson(json);
      expect(user.id, equals(''));
    });

    test('falls back to empty string when name is missing', () {
      final json = {'studentId': 'abc'};
      final user = CurrentUser.fromJson(json);
      expect(user.name, equals(''));
    });

    test('falls back to 0 when profilePicVersion is missing', () {
      final json = {'studentId': 'abc', 'name': 'Test'};
      final user = CurrentUser.fromJson(json);
      expect(user.profilePicVersion, equals(0));
    });

    test('falls back to false when hasTimetableLinked is missing', () {
      final json = {'studentId': 'abc', 'name': 'Test'};
      final user = CurrentUser.fromJson(json);
      expect(user.hasTimetableLinked, isFalse);
    });

    test('handles a completely empty JSON object', () {
      final user = CurrentUser.fromJson({});
      expect(user.id, equals(''));
      expect(user.name, equals(''));
      expect(user.profilePicVersion, equals(0));
      expect(user.hasTimetableLinked, isFalse);
    });
  });

  group('CurrentUser computed getters', () {
    late CurrentUser user;

    setUp(() {
      user = CurrentUser(
        id: 'stu99999',
        name: 'Alex Jones',
        profilePicVersion: 1,
        hasTimetableLinked: false,
      );
    });

    test('\$id getter aliases id', () {
      expect(user.$id, equals(user.id));
    });

    test('email getter builds the expected address from id', () {
      expect(user.email, equals('stu99999@student.runshaw.ac.uk'));
    });
  });
}

