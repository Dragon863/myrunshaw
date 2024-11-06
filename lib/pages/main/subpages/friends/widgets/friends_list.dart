import 'package:flutter/material.dart';
import 'package:runshaw/pages/main/subpages/friends/widgets/friend_tile.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return FriendTile(
          name: "Daniel B",
          uid: "1234",
          currentLesson: "Maths",
          profilePicUrl:
              "https://appwrite.danieldb.uk/v1/avatars/initials?name=Daniel+Benge&width=96&height=96&project=console&name=Daniel+Benge&width=96&height=96&project=console",
        );
      },
      itemCount: 100,
    );
  }
}
