import 'dart:convert';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/config.dart';
import 'api_core.dart';

mixin ApiFriends on ApiCore {
  Future<void> cacheFriends() async {
    final friends = await getFriends(force: true);

    cachedFriends = friends;
    notifyListeners();
    return;
  }

  Future<void> cachePfpVersions() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();
    cachedPfpVersions = {};

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache!

    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/cache/get/pfp-versions'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );
    cachedPfpVersions = jsonDecode(response.body);
  }

  Future<void> cacheNames() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache!

    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/name/get/batch'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );

    cachedNames = jsonDecode(response.body);
  }

  String getPfpUrl(String userId, {bool isPreview = false}) {
    String urlPath = "/view";
    const int previewSize = MyRunshawConfig.previewImageResolution;

    if (isPreview) {
      // Used to save data when rendering in small widgets, as used on the home page
      urlPath = "/preview?";
    }
    if (cachedPfpVersions.containsKey(userId)) {
      return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId$urlPath?project=${MyRunshawConfig.projectId}&version=${cachedPfpVersions[userId]}&width=$previewSize&height=$previewSize";
    }
    return "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/$userId$urlPath?project=${MyRunshawConfig.projectId}&version=0";
  }

  Future<void> incrementPfpVersion() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/cache/update/pfp-version'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    if (response.statusCode != 200) {
      throw "Error incrementing pfp version";
    }
    await cachePfpVersions();
    await Posthog().capture(
      eventName: 'pfp_updated',
    );
  }

  Future<String> sendFriendRequest(String userId) async {
    final String jwtToken = await getJwt();

    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'receiver_id': userId}),
    );
    await cacheFriends();
    return humanResponse(response.body);
  }

  Future<void> blockUser(String userId) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/block'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'blocked_id': userId}),
    );
    if (response.statusCode != 201) {
      throw "Error blocking user";
    }
    await cacheFriends();
    return;
  }

  Future<bool> respondToFriendRequest(
      String userId, bool accept, int id) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.put(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests/${id.toString()}'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'action': accept ? 'accept' : 'decline',
      }),
    );
    await cacheFriends();
    return response.statusCode == 200;
  }

  Future<List> getFriends({bool force = false}) async {
    if (cachedFriends != null && !force) {
      return Future.value(cachedFriends);
    }

    final String jwtToken = await getJwt();
    List<Map> friends = [];

    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/friends'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    for (final friend in jsonDecode(response.body)) {
      if (friend["receiver_id"] == user!.$id) {
        friends.add({
          "userid": friend["sender_id"],
          "status": friend["status"],
          "id": friend["id"],
          "created_at": friend["created_at"],
          "updated_at": friend["updated_at"],
        });
      } else {
        friends.add(
          {
            "userid": friend["receiver_id"],
            "status": friend["status"],
            "id": friend["id"],
            "created_at": friend["created_at"],
            "updated_at": friend["updated_at"],
          },
        );
      }
    }
    return friends;
  }

  Future<List> getFriendRequests() async {
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/friend-requests?status=pending'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    return jsonDecode(response.body);
  }

  Future<String> getName(String userId) async {
    if (cachedNames.containsKey(userId)) {
      return cachedNames[userId].toString();
    }
    final String jwtToken = await getJwt();
    final response = await httpClient.get(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/name/get/$userId'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
      },
    );
    return jsonDecode(response.body)["name"];
  }

  Future<bool> userExists(String userId) async {
    final response = await httpClient.get(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/exists/$userId'),
    );
    return jsonDecode(response.body)["exists"];
  }
}
