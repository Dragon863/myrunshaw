import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models/event.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:skeletonizer/skeletonizer.dart';

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
  bool isLoadingName = true;
  bool isLoadingEvent = true;

  Icon statusIcon = const Icon(Icons.question_mark, color: Colors.orange);
  bool free = false;

  void _handleInFiveMinutesChanged() {
    setState(() {
      currentLesson = null;
      free = false;
      isLoadingEvent = true;
    });
    getCurrentEvent();
  }

  @override
  void initState() {
    super.initState();
    getName();
    getCurrentEvent();

    widget.inFiveMinutesNotifier.addListener(_handleInFiveMinutesChanged);
  }

  @override
  void dispose() {
    widget.inFiveMinutesNotifier.removeListener(_handleInFiveMinutesChanged);
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
          statusIcon = const Icon(
            Icons.event_available,
            color: Colors.green,
            semanticLabel: "Currently free",
          );
        });
      } else {
        setState(() {
          free = false;
          statusIcon = const Icon(
            Icons.event_busy,
            color: Colors.red,
            semanticLabel: "Currently busy",
          );
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
    if (!mounted) return;
    setState(() {
      this.name = name.isEmpty ? "Unknown" : name;
      isLoadingName = false;
    });
  }

  Future<void> getCurrentEvent() async {
    setState(() {
      isLoadingEvent = true;
    });
    final currentLesson = await loadCurrentEventFor(widget.uid);
    if (!mounted) return;
    setState(() {
      this.currentLesson = currentLesson;
      isLoadingEvent = false;
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
    final isSkeletonLoading = isLoadingName || isLoadingEvent;

    return Visibility(
      visible: !(widget.freeOnly && !free),
      child: Skeletonizer(
        enabled: isSkeletonLoading,
        child: ListTile(
          leading: CircleAvatar(
            foregroundImage: CachedNetworkImageProvider(
              widget.profilePicUrl!,
              errorListener: (error) {},
            ),
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
              ExcludeSemantics(
                child: IconButton(
                  onPressed: () => pushPage(context),
                  icon: const Icon(Icons.keyboard_arrow_right),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
