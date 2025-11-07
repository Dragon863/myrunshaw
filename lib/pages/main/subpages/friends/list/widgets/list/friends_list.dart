import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/list/widgets/list/friend_tile.dart';
import 'package:runshaw/utils/api.dart';
import 'package:skeletonizer/skeletonizer.dart';

class FriendsList extends StatefulWidget {
  const FriendsList({super.key});

  @override
  State<FriendsList> createState() => _FriendsListState();
}

class _FriendsListState extends State<FriendsList> {
  List friends = [];
  final ValueNotifier<bool> inFiveMinutesNotifier = ValueNotifier(false);
  bool freeOnly = false;
  bool isLoading = true;

  Future<void> loadFriends() async {
    isLoading = true;
    // first generate some fake data
    for (int i = 0; i < 10; i++) {
      if (mounted) {
        setState(() {
          friends.add({
            "id": "skeleton",
          });
        });
      }
    }
    final api = context.read<BaseAPI>();
    final response = await api.getFriends();
    friends = [];

    for (final friendId in response) {
      if (mounted) {
        setState(() {
          friends.add({
            "id": friendId["userid"],
          });
        });
      }
    }
    setState(() => isLoading = false);
  }

  @override
  void initState() {
    loadFriends();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: const Text("Filters"),
            children: [
              ListTile(
                dense: true,
                title: const Text("In 5 minutes"),
                trailing: ValueListenableBuilder<bool>(
                  valueListenable: inFiveMinutesNotifier,
                  builder: (context, inFiveMinutes, _) {
                    return Checkbox(
                      value: inFiveMinutes,
                      onChanged: (bool? value) {
                        inFiveMinutesNotifier.value = value!;
                      },
                    );
                  },
                ),
              ),
              ListTile(
                dense: true,
                title: const Text("Free only"),
                trailing: Checkbox(
                  value: freeOnly,
                  onChanged: (bool? value) {
                    setState(() {
                      freeOnly = value!;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 2),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              setState(() {
                friends = [];
              });
              loadFriends();
            },
            child: Skeletonizer(
              enabled: isLoading,
              child: ListView.builder(
                cacheExtent: 9999,
                itemBuilder: (context, index) {
                  if (friends[index]["id"] == "skeleton") {
                    return ListTile(
                      title: Text(
                        BoneMock.name,
                      ),
                      subtitle: Text(BoneMock.words(2)),
                      leading: const CircleAvatar(),
                    );
                  }

                  final BaseAPI api = context.read<BaseAPI>();

                  final friend = friends[index];
                  return FriendTile(
                    uid: friend["id"],
                    profilePicUrl: api.getPfpUrl(friend["id"], isPreview: true),
                    freeOnly: freeOnly,
                    inFiveMinutesNotifier: inFiveMinutesNotifier,
                  );
                },
                itemCount: friends.length,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
