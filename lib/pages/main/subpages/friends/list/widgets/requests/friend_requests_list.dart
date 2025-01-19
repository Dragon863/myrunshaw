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
  String profilePicUrl = "";

  Future<void> loadFriends() async {
    // Load friends from API
    final api = context.read<BaseAPI>();
    final response = await api.getFriendRequests();
    for (final friendRequest in response) {
      final String url = api.getPfpUrl(friendRequest["sender_id"]);
      if (mounted) {
        setState(() {
          requests.add({
            "id": friendRequest["sender_id"],
            "req_id": friendRequest["id"],
            "pfpUrl": url,
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
          id: friend["req_id"],
          profilePicUrl: friend["pfpUrl"],
        );
      },
      itemCount: requests.length,
    );
  }
}
