import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool showNotifs = true;
  String name = "Loading...";
  String email = "Loading...";
  String userId = "Loading...";
  String? profilePicUrl;

  @override
  void initState() {
    fetchPrefs();
    super.initState();
  }

  Future<void> fetchPrefs() async {
    final BaseAPI api = context.read<BaseAPI>();
    final models.User? latestUserModel = await api.account?.get();
    final String displayName = latestUserModel!.name;

    setState(() {
      profilePicUrl =
          "https://appwrite.danieldb.uk/v1/storage/buckets/profiles/files/${api.currentUser.$id}/view?project=66fdb56000209ea9ac18&ts=${DateTime.now().millisecondsSinceEpoch.toString()}";
    });

    setState(() {
      if (displayName.isEmpty) {
        name = "Anonymous";
      } else {
        name = displayName;
      }
      email = latestUserModel.email;
      userId = latestUserModel.$id;
    });
  }

  Future<void> photoAction() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Source"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Camera"),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.camera);
                },
              ),
              ListTile(
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.of(context).pop(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.front,
    );

    if (file == null) {
      return;
    }

    final Uint8List bytes = await file.readAsBytes();
    final InputFile profilePicture = InputFile.fromBytes(
      bytes: bytes,
      filename: file.name,
    );
    await updateProfilePic(profilePicture);
    final api = context.read<BaseAPI>();

    setState(() {
      profilePicUrl = "https://appwrite.danieldb.uk/v1/storage/buckets"
          "/profiles/files/${api.currentUser.$id}/"
          "view?project=66fdb56000209ea9ac18"
          "&ts=${DateTime.now().millisecondsSinceEpoch.toString()}";
    });
  }

  Future<void> updateProfilePic(InputFile profilePicture) async {
    final api = context.read<BaseAPI>();

    final Storage storage = Storage(api.client);

    //try {
    try {
      storage.getFile(bucketId: "profiles", fileId: api.currentUser.$id);
      await storage.deleteFile(
        bucketId: "profiles",
        fileId: api.currentUser.$id,
      );
    } catch (e) {}

    await storage.createFile(
      bucketId: "profiles",
      fileId: api.currentUser.$id,
      file: profilePicture,
      permissions: [
        Permission.read(Role.any()),
        Permission.write(Role.user(api.currentUser.$id)),
        Permission.update(Role.user(api.currentUser.$id)),
        Permission.delete(Role.user(api.currentUser.$id)),
      ],
    ); /*
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error uploading profile picture")));
      throw e;
    }*/
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 150,
            maxWidth: 700,
          ),
          child: Column(
            children: [
              const SizedBox(height: 18),
              Stack(
                children: [
                  CircleAvatar(
                    radius: 75,
                    foregroundImage: profilePicUrl != null
                        ? NetworkImage(profilePicUrl!)
                        : null,
                    child: Text(
                      name[0].toUpperCase(),
                      style: GoogleFonts.rubik(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.red),
                        shape: WidgetStateProperty.all(const CircleBorder()),
                      ),
                      onPressed: photoAction,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(width: 24 + 10),
                  Text(
                    name,
                    style: GoogleFonts.rubik(
                      fontSize: 32,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(Icons.mode_edit, color: Colors.grey.shade800),
                    onPressed: () async {
                      final name = await showDialog<String>(
                        context: context,
                        builder: (context) {
                          final controller = TextEditingController();
                          return AlertDialog(
                            title: const Text("Change Name"),
                            content: TextField(
                              controller: controller,
                              decoration: const InputDecoration(
                                hintText: "New Name",
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop(controller.text);
                                },
                                child: const Text("Change"),
                              ),
                            ],
                          );
                        },
                      );
                      if (name != null) {
                        final api = context.read<BaseAPI>();
                        await api.account!.updateName(name: name);
                        fetchPrefs();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 9),
              const Padding(
                padding: EdgeInsets.only(
                  left: 12.0,
                  right: 12.0,
                ),
                child: Divider(),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  const SizedBox(width: 14),
                  const Text(
                    "Demo Toggle",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Switch(
                      value: showNotifs,
                      onChanged: (bool value) {
                        setState(() {
                          showNotifs = value;
                        });
                      }),
                  const SizedBox(width: 10),
                ],
              ),
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  //Navigator.of(context).pushNamed("/privacy_policy");
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('no'),
                    ),
                  );
                },
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    const Text(
                      "Privacy Policy",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.of(context).pushNamed("/privacy_policy");
                      },
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Spacer(),
              SelectableText(
                email,
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
              SelectableText(
                userId,
                style: GoogleFonts.rubik(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
