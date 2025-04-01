import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/list/friends_list.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/requests/friend_requests_list.dart';
import 'package:runshaw/utils/api.dart';

class FriendsPage extends StatefulWidget {
  const FriendsPage({super.key});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  Future<void> addFriend(String? studentId) async {
    if (studentId == null) {
      return;
    }

    final BaseAPI api = context.read<BaseAPI>();
    final String response = await api.sendFriendRequest(studentId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 6),
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 700,
            ),
            child: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: const TabBar(
                  tabs: [
                    Tab(text: "Friends"),
                    Tab(text: "Requests"),
                  ],
                ),
                body: const TabBarView(
                  children: [
                    Column(
                      children: [
                        Expanded(
                          child: FriendsList(),
                        ),
                      ],
                    ),
                    FriendRequestsList(),
                  ],
                ),
                floatingActionButton: FloatingActionButton.extended(
                  label: const Text("Add"),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/friends/add').then(
                          (value) async => await addFriend(value as String?),
                        );
                  },
                  icon: const Icon(Icons.add),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
