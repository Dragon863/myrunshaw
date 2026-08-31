import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/list/friend_tile.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models/event.dart';

class FakeBaseAPI extends BaseAPI {
  bool delayName = false;
  bool delayEvents = false;

  @override
  Future<String> getName(String userId) async {
    if (delayName) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return 'Alice';
  }

  @override
  Future<List<Event>> fetchEvents({
    String? userId,
    bool includeAll = false,
    bool allowCache = false,
  }) async {
    if (delayEvents) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
    return [];
  }
}

void main() {
  testWidgets('FriendTile shows skeleton while async data is still loading',
      (tester) async {
    final api = FakeBaseAPI()
      ..delayName = true
      ..delayEvents = true;

    await tester.pumpWidget(
      ChangeNotifierProvider<BaseAPI>.value(
        value: api,
        child: MaterialApp(
          home: Scaffold(
            body: FriendTile(
              uid: 'abc123',
              profilePicUrl: 'https://example.com/avatar.jpg',
              freeOnly: false,
              inFiveMinutesNotifier: ValueNotifier(false),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(ListTile), findsOneWidget);
    expect(find.text('Alice'), findsNothing);

    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Alice'), findsOneWidget);
  });
}
