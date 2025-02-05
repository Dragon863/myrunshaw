import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:crop_your_image/crop_your_image.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/settings/extra_buses.dart';
import 'package:runshaw/pages/main/subpages/settings/popup_crop.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
  String appVersion = "Loading...";
  String? busNumber;
  String? profilePicUrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    fetchPrefs();
    loadVersion();
    super.initState();
  }

  Future<void> loadVersion() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String version = packageInfo.version;
    setState(() {
      appVersion = version;
    });
  }

  Future<void> fetchPrefs() async {
    final BaseAPI api = context.read<BaseAPI>();
    final models.User? latestUserModel = await api.account?.get();
    final String displayName = latestUserModel!.name;
    final String? busNumber = await api.getBusNumber();

    setState(() {
      profilePicUrl =
          "https://appwrite.danieldb.uk/v1/storage/buckets/${MyRunshawConfig.profileBucketId}/files/${api.currentUser.$id}/view?project=${MyRunshawConfig.projectId}&ts=${DateTime.now().millisecondsSinceEpoch.toString()}";
    });

    setState(() {
      if (displayName.isEmpty) {
        name = "Anonymous";
      } else {
        name = displayName;
      }
      email = latestUserModel.email;
      userId = latestUserModel.$id;
      if (busNumber != null) {
        this.busNumber = busNumber;
      }
    });

    final tags = await OneSignal.User.getTags();
    final bool showNotifs = tags["bus_optout"] == "true";
    if (showNotifs) {
      setState(() {
        this.showNotifs = !showNotifs;
      });
    }
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
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PopupCropPage(
          imageBytes: bytes,
        ),
      ),
    );
    if (result.runtimeType == CropSuccess) {
      final Uint8List croppedBytes = (result as CropSuccess).croppedImage;
      final InputFile profilePicture = InputFile.fromBytes(
        bytes: croppedBytes,
        filename: file.name,
      );

      await updateProfilePic(profilePicture);
      final api = context.read<BaseAPI>();
      await api.incrementPfpVersion();

      setState(() {
        profilePicUrl = "https://appwrite.danieldb.uk/v1/storage/buckets"
            "/${MyRunshawConfig.profileBucketId}/files/${api.currentUser.$id}/"
            "view?project=${MyRunshawConfig.projectId}"
            "&ts=${DateTime.now().millisecondsSinceEpoch.toString()}";
      });
    } else if (result.runtimeType == CropFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error cropping image"),
        ),
      );
      return;
    } else if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cancelled"),
        ),
      );
      return;
    }
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
      await api.incrementPfpVersion();
    } catch (e) {
      // ignore
    }

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

  Future<void> deleteAction() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Profile Picture"),
          content: const Text(
            "Are you sure you want to delete your profile picture?",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text("Cancel"),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final api = context.read<BaseAPI>();
      final Storage storage = Storage(api.client);

      try {
        storage.getFile(bucketId: "profiles", fileId: api.currentUser.$id);
        await storage.deleteFile(
          bucketId: "profiles",
          fileId: api.currentUser.$id,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error deleting profile picture"),
          ),
        );
      }

      setState(() {
        profilePicUrl = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Center(
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
                    Padding(
                      padding: const EdgeInsets.only(left: 48.0, right: 48.0),
                      child: CircleAvatar(
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
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                            ),
                            style: ButtonStyle(
                              backgroundColor:
                                  WidgetStateProperty.all(Colors.red),
                              shape:
                                  WidgetStateProperty.all(const CircleBorder()),
                            ),
                            onPressed: photoAction,
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color: Colors.grey.shade800,
                            ),
                            onPressed: deleteAction,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 24 + (10 * 2)),
                    Expanded(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.rubik(
                          fontSize: 32,
                          fontWeight: FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.mode_edit, color: Colors.grey.shade800),
                      onPressed: () async {
                        final name = await showDialog<String>(
                          context: context,
                          builder: (context) {
                            final controller = TextEditingController();

                            controller.text = this.name;
                            return AlertDialog(
                              title: const Text("Change Name"),
                              content: TextField(
                                controller: controller,
                                autofocus: true,
                                autocorrect: false,
                                decoration: const InputDecoration(
                                  hintText: "New Name",
                                ),
                                onSubmitted: (value) =>
                                    Navigator.of(context).pop(controller.text),
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
                          if (name.length < 40) {
                            final api = context.read<BaseAPI>();
                            await api.account!.updateName(name: name);
                            fetchPrefs();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Error: Name too long"),
                              ),
                            );
                          }
                        }
                      },
                    ),
                    const SizedBox(width: 10),
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
                ExpansionTile(
                  title: const Text(
                    "Buses",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    ListTile(
                      title: const Text(
                        "Bus Notifications",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      trailing: Switch(
                        value: showNotifs,
                        onChanged: (bool value) async {
                          setState(() {
                            showNotifs = value;
                          });
                          OneSignal.User.addTagWithKey("bus_optout", !value);
                        },
                      ),
                    ),
                    Form(
                      key: _formKey,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            DropdownButtonFormField2<String>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                enabled: busNumber != null,
                                contentPadding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              hint: const Text(
                                'Select Your Bus Number',
                                style: TextStyle(fontSize: 14),
                              ),
                              items: MyRunshawConfig.busNumbers
                                  .map((item) => DropdownMenuItem<String>(
                                        value: item.toString(),
                                        child: Text(
                                          item.toString(),
                                          style: const TextStyle(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ))
                                  .toList(),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select bus number.';
                                }
                                return null;
                              },
                              onChanged: (value) async {
                                final api = context.read<BaseAPI>();
                                try {
                                  await api.setBusNumber(value);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Bus number updated!"),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Error setting bus number"),
                                    ),
                                  );
                                }
                              },
                              buttonStyleData: const ButtonStyleData(
                                padding: EdgeInsets.only(right: 16),
                              ),
                              iconStyleData: const IconStyleData(
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: Colors.black45,
                                ),
                                iconSize: 24,
                              ),
                              dropdownStyleData: DropdownStyleData(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              menuItemStyleData: const MenuItemStyleData(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                              value: busNumber,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        "Add Extra Buses",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      subtitle: const Text(
                        "(notifications only)",
                      ),
                      trailing: const Icon(Icons.add),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExtraBusPage(),
                        ),
                      ),
                    )
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    "Legal",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed("/privacy_policy");
                      },
                      title: const Text(
                        "Privacy Policy",
                      ),
                      trailing: const Icon(Icons.privacy_tip_outlined),
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed("/terms");
                      },
                      title: const Text(
                        "Terms of Use",
                      ),
                      trailing: const Icon(Icons.gavel),
                    ),
                    ListTile(
                      onTap: () {
                        Navigator.of(context).pushNamed("/about");
                      },
                      title: const Text(
                        "About",
                      ),
                      trailing: const Icon(Icons.info_outline),
                    ),
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    "Manage Account",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    ListTile(
                      title: const Text(
                        "Change Password",
                      ),
                      onTap: () {
                        Navigator.of(context).pushNamed("/change_password");
                      },
                      trailing: const Icon(
                        Icons.password,
                      ),
                    ),
                    ListTile(
                      title: const Text("Close Account"),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text("Close Account"),
                              content: const Text(
                                "Are you sure you want to close your account? All data will be irreversibly deleted!",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text("Cancel"),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final api = context.read<BaseAPI>();
                                    try {
                                      await api.closeAccount();
                                      Navigator.of(context)
                                          .pushNamedAndRemoveUntil(
                                        "/splash",
                                        (route) => false,
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text("Error closing account"),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text("Close"),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      trailing: const Icon(
                        Icons.no_accounts,
                      ),
                    )
                  ],
                ),
                ExpansionTile(
                  title: const Text(
                    "Other",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  children: [
                    ListTile(
                      title: const Text(
                        "Reset Profile Picture Cache",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onTap: () {
                        DefaultCacheManager().emptyCache();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Profile pictures reset!"),
                          ),
                        );
                      },
                      trailing: const Icon(Icons.delete_outline),
                    ),
                    ListTile(
                      title: const Text(
                        "Report Bug",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      onTap: () async {
                        final Uri emailLaunchUri = Uri(
                          scheme: 'mailto',
                          path: 'hi@danieldb.uk',
                          query:
                              "subject=My Runshaw Bug Report&body=App version: v$appVersion\nBefore sending, please check you are on the latest version of the app from the App Store or Google Play Store. Describe the bug you encountered here:",
                        );
                        await launchUrl(emailLaunchUri);
                      },
                      trailing: const Icon(Icons.bug_report_outlined),
                    ),
                    ListTile(
                      title: const Text(
                        "App Version",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(appVersion),
                      trailing: const Icon(Icons.info_outline),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
