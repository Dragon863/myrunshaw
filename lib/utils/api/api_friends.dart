import 'dart:convert';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'api_core.dart';

mixin ApiFriends on ApiCore {
  Future<void> cacheFriends() async {
    final friends = await getFriends(force: true);
    cachedFriends = friends;
    notifyListeners();
  }

  /// create a URL for a user's profile picture, with versioning for cache busting
  String getPfpUrl(String userId, {bool isPreview = false}) {
    // if the version isn't cached yet, default to 0.
    final version = cachedPfpVersions[userId] ?? 0;
    return "https://s3.danieldb.uk/profiles/$userId.webp?v=$version";
  }

  // DEPRECATED: The backend automatically increments the version in Postgres
  // when you upload a new image via POST /api/users/me/profile-pic
  Future<void> incrementPfpVersion() async {
    // Just capture the analytics event now.
    await Posthog().capture(eventName: 'pfp_updated');
  }

  Future<String> sendFriendRequest(String userId) async {
    final response = await apiPost(
      '/api/friend-requests',
      body: {'receiver_id': userId},
    );

    await cacheFriends();
    return humanResponse(response.body);
  }

  Future<void> blockUser(String userId) async {
    final response = await apiPost(
      '/api/block',
      body: {'blocked_id': userId},
    );

    // OpenAPI schema says 200 OK, updated from 201
    if (response.statusCode != 200) {
      throw "Error blocking user";
    }

    await cacheFriends();
  }

  Future<bool> respondToFriendRequest(
      String userId, bool accept, int id) async {
    final response = await apiPut(
      '/api/friend-requests/$id',
      body: {'action': accept ? 'accept' : 'decline'},
    );

    await cacheFriends();
    return response.statusCode == 200;
  }

  Future<List> getFriends({bool force = false}) async {
    if (cachedFriends != null && !force) {
      return Future.value(cachedFriends);
    }

    final response = await apiGet('/api/friends');

    if (response.statusCode != 200) {
      return [];
    }

    List<Map> friends = [];
    final body = jsonDecode(response.body);

    for (final friend in body) {
      if (friend["receiver_id"] == user?.id) {
        friends.add({
          "userid": friend["sender_id"],
          "status": friend["status"],
          "id": friend["id"],
          "created_at": friend["created_at"],
          "updated_at": friend["updated_at"],
        });
      } else {
        friends.add({
          "userid": friend["receiver_id"],
          "status": friend["status"],
          "id": friend["id"],
          "created_at": friend["created_at"],
          "updated_at": friend["updated_at"],
        });
      }
    }
    return friends;
  }

  Future<List> getFriendRequests() async {
    final response = await apiGet('/api/friend-requests?status=pending');

    if (response.statusCode != 200) return [];
    return jsonDecode(response.body);
  }

  Future<String> getName(String userId) async {
    if (cachedNames.containsKey(userId)) {
      return cachedNames[userId].toString();
    }

    final response = await apiGet('/api/name/get/$userId');

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["name"] ?? "Unknown";
    }
    return "Unknown";
  }

  /// TODO: redundant with entra login?
  Future<bool> userExists(String userId) async {
    try {
      final response = await apiGet('/api/name/get/$userId');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
