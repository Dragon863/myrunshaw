import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  BaseAPI? _api;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final api = context.read<BaseAPI>();
    if (_api != api) {
      _api?.removeListener(_onApiUpdate);
      _api = api;
      _api?.addListener(_onApiUpdate);
    }
  }

  void _onApiUpdate() {
    if (mounted) {
      loadFriends(showSkeleton: false);
    }
  }

  @override
  void dispose() {
    _api?.removeListener(_onApiUpdate);
    inFiveMinutesNotifier.dispose();
    super.dispose();
  }

  Future<void> loadFriends({bool showSkeleton = true}) async {
    if (showSkeleton) {
      setState(() {
        isLoading = true;
        friends = List.generate(10, (_) => {"id": "skeleton"});
      });
    }

    final api = context.read<BaseAPI>();
    final response = await api.getFriends();

    final List<Map<String, dynamic>> loadedFriends = [];
    for (final friendItem in response) {
      final dynamic uid = friendItem is Map
          ? (friendItem["userid"] ??
              friendItem["id"] ??
              friendItem["studentId"])
          : friendItem;
      if (uid != null && uid.toString().isNotEmpty && uid != "skeleton") {
        loadedFriends.add({
          "id": uid.toString(),
        });
      }
    }

    if (mounted) {
      setState(() {
        friends = loadedFriends;
        isLoading = false;
      });
    }
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
              await loadFriends();
            },
            child: Skeletonizer(
              enabled: isLoading,
              child: ListView.builder(
                scrollCacheExtent: ScrollCacheExtent.pixels(9999),
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
                  final String? friendId = friend["id"]?.toString();
                  if (friendId == null || friendId.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return FriendTile(
                    uid: friendId,
                    profilePicUrl: api.getPfpUrl(friendId, isPreview: true),
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
