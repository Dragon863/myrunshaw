import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/helpers.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/utils/api.dart';
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
  String userId = "12345678901";
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

  Future<void> _ensureTimetableCacheReady(String uid) async {
    if (api.cachedTimetables.containsKey(uid)) {
      return;
    }

    // wait for any in-flight timetable batch cache to finish (or trigger one).
    await api.cacheTimetables();
  }

  Future<void> init() async {
    await loadPfp();
    await Future.wait([loadData(), loadEvents()]);
  }

  Future<void> loadPfp() async {
    await api.refreshUser();
    name = api.user!.name.isNotEmpty ? api.user!.name : "Name not set";
    userId = api.user!.$id;
    pfpUrl = api.getPfpUrl(userId);
    _notifySafe();
  }

  Future<void> loadEvents() async {
    try {
      final String? uid = api.user?.$id;
      if (uid == null) return;
      await _ensureTimetableCacheReady(uid);
      events = await api.fetchEvents(userId: uid, allowCache: true);
      _notifySafe();
    } catch (e) {
      debugLog("Error loading events: $e", level: 3);
    }
  }

  Future<String> _loadCurrentEventFor(String uid) async {
    if (api.cachedPfpVersions.isEmpty) {
      await api.cachePfpVersions();
    }
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
      final String? uid = api.user?.$id;
      if (uid == null) {
        loading = false;
        _notifySafe();
        return;
      }

      await _ensureTimetableCacheReady(uid);
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

      final busNumber = await api.getBusNumber();
      final List<String> extraBuses = await api.getAllBuses();
      if (busNumber != null &&
          !extraBuses.contains(busNumber) &&
          busNumber != "") {
        extraBuses.add(busNumber);
      }
      extraBuses.sort(
        (a, b) => int.parse(a.replaceAll(RegExp(r'[A-Z]'), ""))
            .compareTo(int.parse(b.replaceAll(RegExp(r'[A-Z]'), ""))),
      );

      const List<Color> colors = [
        Colors.red,
        Colors.blue,
        Colors.purple,
        Colors.orange,
        Colors.pink,
        Colors.teal,
        Colors.amber,
        Colors.cyan,
        Colors.lime,
      ];

      final busBays = await api.getBusBays();
      final List<BusBayInfo> newBusBayInfos = [];
      int index = 0;
      for (final bus in busBays.keys) {
        if (!extraBuses.contains(bus)) continue;
        final bay = busBays[bus];
        if (bay != "RSP_NYA" &&
            bay != null &&
            bay != "0" &&
            (DateTime.now().hour < 17 || kDebugMode)) {
          newBusBayInfos.add(BusBayInfo(
            busNumber: bus,
            bay: bay,
            color: colors[index % colors.length],
          ));
          index++;
        }
      }
      busBayInfos = newBusBayInfos;

      final List friends = await api.getFriends();

      final bool hasAllFriendTimetables = friends.every(
          (friend) => api.cachedTimetables.containsKey(friend["userid"]));
      if (!hasAllFriendTimetables) {
        await api.cacheTimetables();
      }
      if (_isDisposed) return;

      final List<FreeFriendInfo> newFreeFriends = [];
      for (final friend in friends) {
        if (_isDisposed) return;
        final String friendUid = friend["userid"];
        final friendCurrentLesson = await _loadCurrentEventFor(friendUid);
        final friendName = await api.getName(friendUid);
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
