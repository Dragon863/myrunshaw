import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInfoPage extends StatefulWidget {
  final String id;
  final String name;
  final String profilePicUrl;

  const UserInfoPage({
    super.key,
    required this.id,
    required this.name,
    required this.profilePicUrl,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const RunshawAppBar(title: "Profile"),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 120,
                      foregroundImage: CachedNetworkImageProvider(
                        widget.profilePicUrl,
                        errorListener: (error) {},
                      ),
                      child: Text(
                        widget.name[0].toUpperCase(),
                        style: GoogleFonts.rubik(
                          fontSize: 100,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.name,
                      style: GoogleFonts.rubik(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.id,
                      style: GoogleFonts.rubik(
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              onTap: () async {
                if (!await launchUrl(
                  Uri.parse("mailto:${widget.id}@student.runshaw.ac.uk"),
                )) {
                  throw Exception('Could not launch email');
                }
              },
              title: const Text('Email'),
              trailing: const Icon(Icons.email),
            ),
            const Spacer(),
            ListTile(
              onTap: () async {
                final BaseAPI api = context.read<BaseAPI>();
                try {
                  await api.blockUser(widget.id);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                  // Twice to go back to the friends page
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                    ),
                  );
                }
              },
              title: Text(
                'Block "${widget.name}"',
                style: const TextStyle(color: Colors.red),
              ),
              trailing: const Icon(Icons.block, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
