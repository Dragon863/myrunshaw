import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';

class FriendRequestTile extends StatefulWidget {
  final String uid;
  final String? profilePicUrl;
  final int id;

  const FriendRequestTile({
    super.key,
    required this.uid,
    required this.id,
    this.profilePicUrl,
  });

  @override
  State<FriendRequestTile> createState() => _FriendRequestTileState();
}

class _FriendRequestTileState extends State<FriendRequestTile> {
  String name = "Loading...";
  bool responded = false;
  bool disableButtons = false;

  @override
  void initState() {
    super.initState();
    getName();
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

  Future<void> respond(bool response) async {
    if (disableButtons) {
      return;
    }
    final api = context.read<BaseAPI>();
    setState(() {
      disableButtons = true;
    });
    final bool result =
        await api.respondToFriendRequest(widget.uid, response, widget.id);
    if (result) {
      setState(() {
        responded = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response
                ? "Accepted friend request from $name!"
                : "Declined friend request from $name!",
          ),
        ),
      );
    }
    setState(() {
      name = response ? "Accepted" : "Declined";
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        foregroundImage: CachedNetworkImageProvider(
          widget.profilePicUrl!,
          cacheKey: widget.uid,
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
      subtitle: const Text("Received"),
      trailing: !responded
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () async => await respond(true),
                  style: const ButtonStyle(
                    foregroundColor: WidgetStatePropertyAll(Colors.green),
                  ),
                  child: const Text("Accept"),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () async => await respond(false),
                  icon: const Icon(Icons.close, color: Colors.red),
                ),
              ],
            )
          : null,
    );
  }
}
