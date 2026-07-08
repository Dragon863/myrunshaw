import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/models/event.dart';

class BusBayInfo {
  final String busNumber;
  final String bay;
  final Color color;

  const BusBayInfo({
    required this.busNumber,
    required this.bay,
    required this.color,
  });
}

class FreeFriendInfo {
  final String uid;
  final String name;
  final String pfpUrl;
  final String pfpPreviewUrl;

  const FreeFriendInfo({
    required this.uid,
    required this.name,
    required this.pfpUrl,
    required this.pfpPreviewUrl,
  });
}

class HomeController extends ChangeNotifier {
  final BaseAPI api;
  bool _isDisposed = false;

  String? pfpUrl;
  String name = "Loading...";
  String userId = "Loading...";
  String nextLesson = "Loading...";
  String nextDetails = "Loading...";
  List<Event> events = [];
  bool loading = false;
  List<BusBayInfo> busBayInfos = [];
  List<FreeFriendInfo> freeFriendsData = [];

  HomeController(this.api);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _notifySafe() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> init() async {
    await syncData();

    await Future.wait([loadData(), loadEvents()]);
  }

  Future<void> syncData() async {
    await api.refreshUser();

    if (api.currentUser != null) {
      name = api.currentUser!.name.isNotEmpty
          ? api.currentUser!.name
          : "Name not set";
      userId = api.currentUser!.id;
      pfpUrl = api.getPfpUrl(userId);
    }
    _notifySafe();
  }

  Future<void> loadEvents() async {
    try {
      final String? uid = api.currentUser?.id;
      if (uid == null) return;

      events = await api.fetchEvents(userId: uid, allowCache: true);
      _notifySafe();
    } catch (e) {
      debugLog("Error loading events: $e", level: 3);
    }
  }

  Future<String> _loadCurrentEventFor(String uid) async {
    try {
      final List<Event> evts =
          await api.fetchEvents(userId: uid, allowCache: true);
      return fetchCurrentEvent(evts);
    } catch (e) {
      return "internal:ignore";
    }
  }

  Future<void> loadData({bool allowCache = true}) async {
    if (loading) return;
    loading = true;
    freeFriendsData = [];
    _notifySafe();

    try {
      final String? uid = api.currentUser?.id;
      if (uid == null) {
        loading = false;
        _notifySafe();
        return;
      }

      if (_isDisposed) return;

      List<Event> evts =
          await api.fetchEvents(userId: uid, allowCache: allowCache);
      evts = evts.fillGaps().sortEvents();

      final now = DateTime.now();
      final Event next = evts.firstWhere(
        (event) => event.start.isAfter(now),
        orElse: () => Event(
          summary: 'No Event',
          location: '',
          start: now,
          end: now,
          description: '',
          uid: '',
        ),
      );

      if (next.summary == "No Event") {
        nextLesson = "No Event";
        nextDetails = "";
      } else {
        nextLesson = next.summary;
        nextDetails = next.description == null
            ? "No Description"
            : next.location != null && next.location != ""
                ? "${next.description!.replaceAll("Teacher: ", "")} in ${next.location}"
                : next.description!.replaceAll("Teacher: ", "");
      }

      final List<String> extraBuses = await api.getAllSubscribedBuses();

      extraBuses.sort(
        (a, b) => int.parse(a.replaceAll(RegExp(r'[A-Z]'), ""))
            .compareTo(int.parse(b.replaceAll(RegExp(r'[A-Z]'), ""))),
      );

      final List<Color> colors = MyRunshawConfig.busBayColors;
      final busBays = await api.getBusBays();
      final List<BusBayInfo> newBusBayInfos = [];

      for (var i = 0; i < extraBuses.length; i++) {
        final bus = extraBuses[i];
        final bay = busBays[bus];

        if (bay != "RSP_NYA" &&
            bay != null &&
            bay != "0" &&
            (DateTime.now().hour < 17 || kDebugMode)) {
          newBusBayInfos.add(
            BusBayInfo(
              busNumber: bus,
              bay: bay,
              color: colors[i % colors.length],
            ),
          );
        }
      }
      busBayInfos = newBusBayInfos;

      final List friends = api.cachedFriends ?? [];
      final List<FreeFriendInfo> newFreeFriends = [];

      for (final friend in friends) {
        if (_isDisposed) return;

        final String friendUid = friend["userid"];
        final friendCurrentLesson = await _loadCurrentEventFor(friendUid);

        final friendName = api.cachedNames[friendUid] ?? "Unknown User";

        if (friendCurrentLesson.contains("Aspire") ||
            friendCurrentLesson == "No Event") {
          newFreeFriends.add(FreeFriendInfo(
            uid: friendUid,
            name: friendName,
            pfpUrl: api.getPfpUrl(friendUid),
            pfpPreviewUrl: api.getPfpUrl(friendUid, isPreview: true),
          ));
        }
      }
      freeFriendsData = newFreeFriends;
    } catch (e) {
      debugLog("Error in loadData: $e", level: 3);
    }

    loading = false;
    _notifySafe();
  }
}
