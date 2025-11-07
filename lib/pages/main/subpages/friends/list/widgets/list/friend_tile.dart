import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';

class FriendTile extends StatefulWidget {
  final String uid;
  final String? profilePicUrl;
  final bool freeOnly;
  final ValueNotifier<bool> inFiveMinutesNotifier;

  const FriendTile({
    super.key,
    required this.uid,
    this.profilePicUrl, // deprecated; uses API instead to prevent low-res preview being passed in
    required this.freeOnly,
    required this.inFiveMinutesNotifier,
  });

  @override
  State<FriendTile> createState() => _FriendTileState();
}

class _FriendTileState extends State<FriendTile> {
  String name = "Loading...";
  String? currentLesson;
  String subtitle = "Loading...";

  Icon statusIcon = const Icon(Icons.question_mark, color: Colors.orange);
  bool free = false;

  @override
  void initState() {
    super.initState();
    getName();
    getCurrentEvent();

    widget.inFiveMinutesNotifier.addListener(() {
      setState(() {
        currentLesson = null;
        free = false;
      });
      getCurrentEvent();
    });
  }

  @override
  void dispose() {
    widget.inFiveMinutesNotifier.removeListener(() {});
    super.dispose();
  }

  Future<String> loadCurrentEventFor(String userId) async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events =
          await api.fetchEvents(userId: userId, allowCache: true);
      String current = "";
      if (widget.inFiveMinutesNotifier.value) {
        final timeInFive = DateTime.now().add(const Duration(minutes: 5));
        current = fetchCurrentEventAt(events, timeInFive);
      } else {
        current = fetchCurrentEvent(events);
      }
      if (current == "No Event" || current.contains("Aspire")) {
        setState(() {
          free = true;
          statusIcon = const Icon(Icons.event_available, color: Colors.green);
        });
      } else {
        setState(() {
          free = false;
          statusIcon = const Icon(Icons.event_busy, color: Colors.red);
        });
      }
      return current;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst syncing: $e"),
        ),
      );
      return "Error";
    }
  }

  Future<void> getName() async {
    final api = context.read<BaseAPI>();
    final name = await api.getName(widget.uid);
    setState(() {
      this.name = name.isEmpty ? "Unknown" : name;
    });
  }

  Future<void> getCurrentEvent() async {
    final currentLesson = await loadCurrentEventFor(widget.uid);
    setState(() {
      this.currentLesson = currentLesson;
    });
  }

  void pushPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IndividualFriendPage(
          userId: widget.uid,
          name: name,
          profilePicUrl: context.read<BaseAPI>().getPfpUrl(widget.uid),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !(widget.freeOnly && !free),
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage: CachedNetworkImageProvider(
            widget.profilePicUrl!,
            errorListener: (error) {},
          ),
          backgroundColor: getPfpColour(widget.profilePicUrl!),
          child: Text(
            getFirstNameCharacter(name),
            style: GoogleFonts.rubik(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(name),
        subtitle: free
            ? const Text('Currently Free')
            : Text(currentLesson ?? 'Loading...'),
        onTap: () => pushPage(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            statusIcon,
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => pushPage(context),
              icon: const Icon(Icons.keyboard_arrow_right),
            )
          ],
        ),
      ),
    );
  }
}
