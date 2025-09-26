import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:runshaw/utils/theme/light.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UserInfoPage extends StatefulWidget {
  final String id;
  final String name;
  final String profilePicUrl;
  final String bus;

  const UserInfoPage({
    super.key,
    required this.id,
    required this.name,
    required this.profilePicUrl,
    required this.bus,
  });

  @override
  State<UserInfoPage> createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.read<ThemeProvider>().isLightMode ? Colors.white : (context.read<ThemeProvider>().amoledEnabled ? Colors.black : const Color(0xFF1E1E1E)),
      child: SafeArea(
        child: Scaffold(
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
                          backgroundColor: getPfpColour(widget.profilePicUrl),
                          child: Text(
                            getFirstNameCharacter(widget.name),
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
                  title: Text(
                    'Email',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${widget.id}@student.runshaw.ac.uk'),
                  trailing: const Icon(Icons.email),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: Text(
                    'Bus',
                    style: GoogleFonts.rubik(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(widget.bus),
                  trailing: const Icon(Icons.directions_bus),
                  // Legacy from when the app supported only one bus. TODO: Will rewrite in v1.3.1 to have a popup
                  //   onTap: () async {
                  //     if (widget.bus == "Not Set") {
                  //       return;
                  //     }
                  //     final BaseAPI api = context.read<BaseAPI>();
                  //     final String busBay = await api.getBusBay(widget.bus);

                  //     if (busBay == "RSP_NYA" || busBay == "0") {
                  //       // Response-Not-Yet-Arrived
                  //       ScaffoldMessenger.of(context).showSnackBar(
                  //         const SnackBar(
                  //           content: Text(
                  //             "Bus has not arrived yet",
                  //           ),
                  //         ),
                  //       );
                  //     } else {
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => BusMapViewPage(
                  //             bay: busBay,
                  //             busNumber: widget.bus,
                  //           ),
                  //         ),
                  //       );
                  //     }
                  //   },
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
                    'Unfriend "${widget.name}"',
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: const Icon(Icons.block, color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } 
}
