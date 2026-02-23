import 'dart:convert';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/logging.dart';
import 'package:runshaw/utils/models.dart';
import 'api_core.dart';
import 'api_friends.dart';

mixin ApiTimetable on ApiCore, ApiFriends {
  Future<void> cacheTimetables() async {
    final String jwtToken = await getJwt();
    final friends = await getFriends();

    List<String> userIds = [];
    for (var friend in friends) {
      userIds.add(friend["userid"]);
    }
    userIds.add(user!.$id); // include self in the cache

    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable/batch_get'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_ids': userIds,
      }),
    );
    cachedTimetables = jsonDecode(response.body);
  }

  Future<void> syncTimetable(timetable) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse('${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'timetable': timetable}),
    );
    if (response.statusCode != 201) {
      throw "Error syncing timetable";
    }
    await Posthog().capture(
      eventName: 'timetable_synced',
    );
    return;
  }

  Future<void> associateTimetableUrl(String url) async {
    final String jwtToken = await getJwt();
    final response = await httpClient.post(
      Uri.parse(
          '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable/associate'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'url': url}),
    );
    if (response.statusCode != 201) {
      throw "Error associating timetable";
    }
    await Posthog().capture(
      eventName: 'associated_timetable_url',
    );
    return;
  }

  Future<List<Event>> fetchEvents(
      {String? userId,
      bool includeAll = false,
      bool allowCache = false}) async {
    userId ??= user!.$id;

    List<Event> timetable = [];
    String query = "";
    if (userId != user!.$id) {
      query = "?user_id=$userId";
    }

    Map events;

    if (!cachedTimetables.containsKey(userId) || !allowCache) {
      debugLog("Fetching timetable for $userId");
      final String jwtToken = await getJwt();

      final response = await httpClient.get(
        Uri.parse(
            '${MyRunshawConfig.friendsMicroserviceUrl}/api/timetable$query'),
        headers: {
          'Authorization': 'Bearer $jwtToken',
        },
      );

      if (response.statusCode != 200) {
        return [];
      }
      events = jsonDecode(response.body)["timetable"];
    } else {
      if (cachedTimetables[userId].runtimeType == String) {
        // Legacy API support; not sure why this happend but sometimes the timetable is a string and sometimes it's a map :/
        events = jsonDecode(cachedTimetables[userId]);
      } else {
        events = cachedTimetables[userId];
      }
    }

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
