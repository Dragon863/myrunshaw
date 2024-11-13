import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/requests/friend_req_tile.dart';
import 'package:runshaw/utils/api.dart';

class FriendRequestsList extends StatefulWidget {
  const FriendRequestsList({super.key});

  @override
  State<FriendRequestsList> createState() => _FriendRequestsListState();
}

class _FriendRequestsListState extends State<FriendRequestsList> {
  List<Map> requests = [];

  Future<void> loadFriends() async {
    // Load friends from API
    final api = context.read<BaseAPI>();
    final response = await api.getFriendRequests();
    final friends = await api.getFriends();
    for (final userId in response) {
      if (mounted && !friends.contains(userId)) {
        setState(() {
          requests.add({
            "id": userId,
          });
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        final friend = requests[index];
        return FriendRequestTile(
          uid: friend["id"],
          profilePicUrl:
              "https://appwrite.danieldb.uk/v1/storage/buckets/profiles/files/${friend["id"]}/view?project=66fdb56000209ea9ac18",
        );
      },
      itemCount: requests.length,
    );
  }
}
