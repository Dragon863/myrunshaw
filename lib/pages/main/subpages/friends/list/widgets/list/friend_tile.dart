import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/sync/sync_controller.dart';
import 'package:runshaw/utils/api.dart';

class FriendTile extends StatefulWidget {
  final String uid;
  final String? profilePicUrl;

  const FriendTile({
    super.key,
    required this.uid,
    this.profilePicUrl,
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
  }

  void pushPage(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IndividualFriendPage(
          userId: widget.uid,
          name: name,
          profilePicUrl: widget.profilePicUrl!,
        ),
      ),
    );
  }

  Future<String> loadCurrentEventFor(String userId) async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents(userId: userId);

      final String current = fetchCurrentEvent(events);
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
      if (name == "") {
        this.name = "Unknown";
      } else {
        this.name = name;
      }
    });
  }

  Future<void> getCurrentEvent() async {
    final currentLesson = await loadCurrentEventFor(widget.uid);
    setState(() {
      this.currentLesson = currentLesson;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: CachedNetworkImageProvider(
          widget.profilePicUrl!,
          errorListener: (error) {},
        ),
        child: Text(
          name[0].toUpperCase(),
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
          /*widget.free
              ? const Icon(Icons.event_available, color: Colors.green)
              : const Icon(Icons.event_busy, color: Colors.red),*/
          statusIcon,
          const SizedBox(width: 10),
          IconButton(
            onPressed: () => pushPage(context),
            icon: const Icon(Icons.keyboard_arrow_right),
          )
        ],
      ),
    );
  }
}
