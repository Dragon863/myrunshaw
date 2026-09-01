import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/list/friend_tile.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models/event.dart';

class FakeBaseAPI extends BaseAPI {
  bool delayName = false;
  bool delayEvents = false;
  http.Response? postResponse;
  List friendsResult = ['existing-friend'];

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

  @override
  Future<http.Response> apiPost(String endpoint,
      {Map<String, dynamic>? body}) async {
    return postResponse ?? http.Response('{}', 200);
  }

  @override
  Future<List> getFriends({bool force = false}) async {
    if (force) {
      return [];
    }
    return friendsResult;
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

  test(
      'sendFriendRequest keeps the current friend cache when the API rejects the request',
      () async {
    final api = FakeBaseAPI()
      ..postResponse = http.Response('{"error":"User not found"}', 404)
      ..cachedFriends = ['existing-friend'];

    final response = await api.sendFriendRequest('missing-user');

    expect(response, 'User not found');
    expect(api.cachedFriends, ['existing-friend']);
  });
}
