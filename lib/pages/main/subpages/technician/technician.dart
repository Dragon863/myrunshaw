import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/scan/controller.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class TechnicianPage extends StatefulWidget {
  const TechnicianPage({super.key});

  @override
  State<TechnicianPage> createState() => _TechnicianPageState();
}

class _TechnicianPageState extends State<TechnicianPage> {
  final MobileScannerController cameraController = MobileScannerController();
  Widget? content;
  String bottomText = 'Scan an ID badge';
  bool scanned = false;

  Future<void> _buildContent(String studentID, Map data) async {
    setState(() {
      content = SingleChildScrollView(
        child: Center(
          child: Container(
            constraints: const BoxConstraints(
              minWidth: 150,
              maxWidth: 1000,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 9),
                Padding(
                  padding: const EdgeInsets.only(left: 48.0, right: 48.0),
                  child: CircleAvatar(
                    radius: 100,
                    foregroundImage: NetworkImage(data['pfp_url']),
                    child: Text(
                      getFirstNameCharacter(data['name']),
                      style: GoogleFonts.rubik(
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Text(
                  data['name'],
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.rubik(
                    fontSize: 32,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                Text(
                  studentID,
                  style: GoogleFonts.rubik(
                    fontSize: 16,
                    fontWeight: FontWeight.normal,
                    color: context.read<ThemeProvider>().isLightMode
                        ? Colors.grey.shade800
                        : null,
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      splashColor: context.read<ThemeProvider>().isLightMode
                          ? Colors.grey.shade300
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await _launchUrl(data['runshaw_pay_url']);
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.payments),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Pay",
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.link),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      onTap: () async {
                        const String appwriteURL =
                            MyRunshawConfig.endpointHostname;
                        const String appwriteProject =
                            MyRunshawConfig.projectId;

                        final String url =
                            'https://$appwriteURL/console/project-default-$appwriteProject/auth/user-$studentID';
                        await launchUrl(Uri.parse(url));
                      },
                      splashColor: context.read<ThemeProvider>().isLightMode
                          ? Colors.grey.shade300
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.person),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Appwrite',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.link),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      onTap: () async {
                        await launchUrl(Uri.parse(data['timetable_url']));
                      },
                      splashColor: context.read<ThemeProvider>().isLightMode
                          ? Colors.grey.shade300
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Timetable',
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Icon(Icons.link),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: Card(
                    elevation: 1,
                    child: InkWell(
                      splashColor: context.read<ThemeProvider>().isLightMode
                          ? Colors.grey.shade300
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_bus),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['buses'],
                                  style: GoogleFonts.rubik(
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                ListView.builder(
                    itemBuilder: (context, index) {
                      final friend = data['friends'][index];
                      return ListTile(
                        title: Text(friend['name'] ?? 'Unknown'),
                        subtitle: Text(friend['id'] ?? 'Unknown'),
                        onTap: () async {
                          const String appwriteURL =
                              MyRunshawConfig.endpointHostname;
                          const String appwriteProject =
                              MyRunshawConfig.projectId;

                          final String url =
                              'https://$appwriteURL/console/project-default-$appwriteProject/auth/user-${friend['id']}';
                          await launchUrl(Uri.parse(url));
                        },
                      );
                    },
                    itemCount: data['friends'].length,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics()),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content ??
          Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                onDetect: (result) async {
                  if (result.barcodes.isNotEmpty && !scanned) {
                    // don't keep sending requests
                    final String code = result.barcodes.first.rawValue!;
                    setState(() {
                      bottomText = code;
                      scanned = true;
                    });
                    await cameraController.stop();
                    final bool valid = validate(
                        result.barcodes.firstOrNull?.displayValue ?? "");

                    if (valid) {
                      final BaseAPI api = context.read<BaseAPI>();
                      String studentId = result
                          .barcodes.firstOrNull!.displayValue!
                          .split("-")[0];
                      final Map studentInfo =
                          await api.getUserInfoTechnician(studentId);
                      await _buildContent(studentInfo['user_id'], studentInfo);
                    }
                  }
                },
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  alignment: Alignment.bottomCenter,
                  height: 100,
                  color: Colors.black.withValues(alpha: 0.4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            bottomText,
                            overflow: TextOverflow.fade,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
      floatingActionButton: content != null
          ? FloatingActionButton(
              onPressed: () async {
                setState(() {
                  content = null;
                  scanned = false;
                  bottomText = 'Scan a QR code';
                });
                await cameraController.start();
              },
              child: const Icon(Icons.arrow_back),
            )
          : null,
    );
  }
}
