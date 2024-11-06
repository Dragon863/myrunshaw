import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendTile extends StatelessWidget {
  final String name;
  final String uid;
  final String? currentLesson;
  final String? profilePicUrl;

  const FriendTile({
    super.key,
    required this.name,
    required this.uid,
    this.currentLesson,
    this.profilePicUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: CachedNetworkImageProvider(
          profilePicUrl!,
        ),
        child: profilePicUrl == null
            ? Text(
                name[0].toUpperCase(),
                style: GoogleFonts.rubik(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
      ),
      title: Text(name),
      subtitle: currentLesson != null
          ? Text(currentLesson!)
          : const Text('Currently Free'),
      trailing: currentLesson != null
          ? const Icon(Icons.event_busy, color: Colors.red)
          : const Icon(Icons.event_available, color: Colors.green),
    );
  }
}
