import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/buses/bus_list/bus_map_view.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/individual_friend.dart';
import 'package:runshaw/pages/main/subpages/home/home_controller.dart';
import 'package:runshaw/pages/main/subpages/home/inapp/inapp.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/list.dart';
import 'package:runshaw/pages/qr/qr_page.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/pfp_helper.dart';
import 'package:runshaw/utils/string_utils.dart';
import 'package:runshaw/utils/theme/theme_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final HomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = HomeController(context.read<BaseAPI>());
    _controller.addListener(_rebuild);
    _controller.init().then((_) {
      if (mounted) checkInAppAlerts(context);
    });
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_rebuild);
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBusCard(BusBayInfo info) {
    return Card.filled(
      color: info.color,
      child: ListTile(
        title: Text(
          'The ${info.busNumber} is in bay ${info.bay}!',
          style: GoogleFonts.rubik(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        trailing: const Icon(Icons.directions_bus, color: Colors.white),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusMapViewPage(
              bay: info.bay,
              busNumber: info.busNumber,
              color: info.color,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendAvatar(FreeFriendInfo friend) {
    return GestureDetector(
      onLongPress: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${friend.name} (tap to view)")),
        );
      },
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => IndividualFriendPage(
            userId: friend.uid,
            name: friend.name,
            profilePicUrl: friend.pfpUrl,
          ),
        ),
      ),
      child: Align(
        widthFactor: 0.8,
        child: CircleAvatar(
          radius: 25,
          foregroundImage: CachedNetworkImageProvider(
            friend.pfpPreviewUrl,
            errorListener: (error) {},
          ),
          child: Text(
            getFirstNameCharacter(friend.name),
            style: GoogleFonts.rubik(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return AspectRatio(
      aspectRatio: 1,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  foregroundImage: CachedNetworkImageProvider(
                    _controller.pfpUrl ?? "",
                    errorListener: (error) {},
                  ),
                  child: Text(
                    _controller.name == "Loading..."
                        ? "..."
                        : getFirstNameCharacter(_controller.name),
                    style: GoogleFonts.rubik(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Skeletonizer(
                  enabled: _controller.name == "Loading...",
                  child: Text(
                    truncateName(_controller.name),
                    style: GoogleFonts.rubik(fontSize: 22),
                  ),
                ),
                Skeletonizer(
                  enabled: _controller.userId == "12345678901",
                  child: Text(
                    _controller.userId,
                    style: GoogleFonts.rubik(fontWeight: FontWeight.w200),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNextEventColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 2 / 1,
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Next Event:', style: GoogleFonts.rubik()),
                    Skeletonizer(
                      enabled: _controller.nextLesson == "Loading...",
                      child: Text(
                        _controller.nextLesson,
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AspectRatio(
          aspectRatio: 2 / 1,
          child: Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 8, right: 8),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Details:', style: GoogleFonts.rubik()),
                    Skeletonizer(
                      enabled: _controller.nextDetails == "Loading...",
                      child: Text(
                        _controller.nextDetails,
                        style: GoogleFonts.rubik(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQrCard() {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 1,
        child: InkWell(
          splashColor: context.read<ThemeProvider>().isLightMode
              ? Colors.grey.shade300
              : null,
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final BaseAPI api = context.read<BaseAPI>();
            final String code = await api.getCode();
            if (!mounted) return;
            if (code == "000000") {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Error"),
                  content: const Text(
                    "Your QR code is not available, as you signed up with an email address.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text("OK"),
                    ),
                  ],
                ),
              );
            } else {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => QrCodePage(
                    qrUrl:
                        "https://api.qrserver.com/v1/create-qr-code/?data=${context.read<BaseAPI>().user!.$id.toUpperCase()}-$code",
                  ),
                ),
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Icon(Icons.qr_code),
                const SizedBox(width: 8),
                Text("QR Code", style: GoogleFonts.rubik(fontSize: 22)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_right),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool get _hasTodayEvents {
    final now = DateTime.now();
    final todayStart =
        now.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
    final todayEnd =
        now.copyWith(hour: 23, minute: 59, second: 59, millisecond: 999);
    return _controller.events.any((event) =>
        event.start.isAfter(todayStart) && event.end.isBefore(todayEnd));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.only(left: 6, right: 6),
            child: ListView(
              children: [
                ..._controller.busBayInfos.map(_buildBusCard),
                Row(
                  children: [
                    Expanded(child: _buildProfileCard()),
                    Expanded(child: _buildNextEventColumn()),
                  ],
                ),
                _buildQrCard(),
                const SizedBox(height: 8),
                if (_controller.freeFriendsData.isNotEmpty) ...[
                  Text(
                    'Free Now:',
                    style: GoogleFonts.rubik(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Wrap(
                      runSpacing: 2,
                      children: _controller.freeFriendsData
                          .map(_buildFriendAvatar)
                          .toList(),
                    ),
                  ),
                ],
                if (_hasTodayEvents)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      'Today:',
                      style: GoogleFonts.rubik(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (_controller.events.isNotEmpty)
                  TimetableList(
                    events: _controller.events,
                    dense: true,
                    todayOnly: true,
                  ),
                const SizedBox(height: 8),
                if (_controller.userId == "row23207169")
                  // easter egg for a friend
                  RotatedBox(
                    quarterTurns: 1,
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: CachedNetworkImage(
                        imageUrl:
                            "https://appwrite.danieldb.uk/v1/storage/buckets/cdn/files/charlie/view?project=66fdb56000209ea9ac18",
                        width: 80,
                        height: 80,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _controller.loadData(allowCache: false),
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
