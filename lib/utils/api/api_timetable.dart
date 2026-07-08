import 'dart:convert';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/models/event.dart';
import 'api_core.dart';
import 'api_friends.dart';

mixin ApiTimetable on ApiCore, ApiFriends {
  Future<void> cacheTimetables() async {
    if (timetableCacheInFlight != null) {
      return timetableCacheInFlight!;
    }

    timetableCacheInFlight = _cacheTimetablesInternal();
    try {
      await timetableCacheInFlight;
    } finally {
      timetableCacheInFlight = null;
    }
  }

  Future<void> _cacheTimetablesInternal() async {
    final friends = await getFriends();

    List<String> userIds = friends.map((f) => f["userid"].toString()).toList();
    if (user != null) {
      userIds.add(user!.id); // include self in the cache
    }

    final response = await apiPost(
      '/api/timetable/batch_get',
      body: {'user_ids': userIds},
    );

    if (response.statusCode != 200) {
      throw "Error caching timetables";
    }
    cachedTimetables = jsonDecode(response.body);
  }

  Future<void> associateTimetableUrl(String url) async {
    final response = await apiPost(
      '/api/timetable/associate',
      body: {'url': url},
    );

    if (response.statusCode != 201) {
      throw "Error associating timetable";
    }
    await Posthog().capture(eventName: 'associated_timetable_url');
  }

  Future<List<Event>> fetchEvents(
      {String? userId,
      bool includeAll = false,
      bool allowCache = false}) async {
    userId ??= user?.id;
    if (userId == null) return [];

    List<Event> timetable = [];
    String query = (userId != user?.id) ? "?user_id=$userId" : "";
    Map events;

    if (allowCache && !cachedTimetables.containsKey(userId)) {
      // Prefer batch cache population over individual fetches when cache usage is requested.
      if (timetableCacheInFlight != null) {
        await timetableCacheInFlight;
      } else {
        await cacheTimetables();
      }
    }

    if (!cachedTimetables.containsKey(userId) || !allowCache) {
      debugLog("Fetching timetable for $userId");

      final response = await apiGet('/api/timetable$query');

      if (response.statusCode != 200) {
        return [];
      }
      events = jsonDecode(response.body)["timetable"];
    } else {
      // Safely handle the legacy string-or-map issue
      var cached = cachedTimetables[userId];
      events = (cached is String) ? jsonDecode(cached) : cached;
    }

    if (events["data"] == null) return [];

    for (final event in events["data"]) {
      final String start = event["dtstart"]["dt"];
      final String end = event["dtend"]["dt"];

      final DateTime startDateTime = DateTime.parse(start);
      final DateTime endDateTime = DateTime.parse(end);

      final startOfToday = DateTime.now().subtract(
        Duration(
          hours: DateTime.now().hour,
          minutes: DateTime.now().minute,
          seconds: DateTime.now().second,
        ),
      );

      if (!includeAll) {
        if (startDateTime.isBefore(startOfToday) &&
            endDateTime.isBefore(startOfToday)) {
          // Skip past events that have already happened!
          // Starting at the beginning of the day prevents aspire weirdness
          continue;
        }
      }
      timetable.add(Event(
        summary: event['summary'],
        location: event['location'],
        start: startDateTime,
        end: endDateTime,
        description: event["description"],
        uid: event["uid"],
      ));
    }
    return timetable;
  }
}
