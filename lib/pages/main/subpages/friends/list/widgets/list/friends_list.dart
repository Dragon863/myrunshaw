import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/list/friend_tile.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  List friends = [];

  Future<void> loadFriends() async {
    // Load friends from API
    final api = context.read<BaseAPI>();
    final response = await api.getFriends();
    for (final friendId in response) {
      if (mounted) {
        setState(() {
          friends.add({
            "id": friendId["userid"],
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
        final friend = friends[index];
        return FriendTile(
          uid: friend["id"],
          profilePicUrl:
              "https://appwrite.danieldb.uk/v1/storage/buckets/${Config.profileBucketId}/files/${friend["id"]}/view?project=${Config.projectId}",
        );
      },
      itemCount: friends.length,
    );
  }
}
