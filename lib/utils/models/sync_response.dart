import 'dart:convert';

import 'package:runshaw/utils/models/current_user.dart';
import 'package:runshaw/utils/models/event.dart';

/// typed representation of the `/api/sync` response
class SyncResponse {
  const SyncResponse({
    required this.me,
    required this.friends,
    required this.pendingRequests,
    required this.subscribedBusStatuses,
    required this.timetables,
  });

  final CurrentUser me;
  final List<SyncFriend> friends;
  final List<SyncFriendRequest> pendingRequests;
  final Map<String, String> subscribedBusStatuses;
  final Map<String, TimetableDocument> timetables;

  factory SyncResponse.fromJson(Map<String, dynamic> json) {
    if (json['me'] is! Map) {
      throw const FormatException('Sync response is missing the user');
    }
    final meJson = _asJsonMap(json['me']);
    final friendsJson = json['friends'];
    final pendingRequestsJson = json['pendingRequests'];
    final subscribedBusesJson = json['subscribedBusStatuses'];
    final timetablesJson = _asJsonMap(json['timetables']);

    return SyncResponse(
      me: CurrentUser.fromJson(meJson),
      friends: friendsJson is List
          ? friendsJson
              .whereType<Map>()
              .map((friend) => SyncFriend.fromJson(_asJsonMap(friend)))
              .toList(growable: false)
          : const [],
      pendingRequests: pendingRequestsJson is List
          ? pendingRequestsJson
              .whereType<Map>()
              .map((request) => SyncFriendRequest.fromJson(_asJsonMap(request)))
              .toList(growable: false)
          : const [],
      subscribedBusStatuses: subscribedBusesJson is List
          ? Map.fromEntries(subscribedBusesJson.whereType<Map>().map((entry) {
              final jsonEntry = _asJsonMap(entry);
              return MapEntry(
                (jsonEntry['key'] ?? jsonEntry['Key'])?.toString() ?? '',
                (jsonEntry['value'] ?? jsonEntry['Value'])?.toString() ?? '',
              );
            }))
          : const {},
      timetables: timetablesJson.map(
        (userId, value) => MapEntry(
          userId,
          TimetableDocument.fromJsonValue(value),
        ),
      ),
    );
  }
}

class SyncFriendRequest {
  const SyncFriendRequest({
    required this.requestId,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
  });

  final int requestId;
  final String senderId;
  final String senderName;
  final DateTime? createdAt;

  factory SyncFriendRequest.fromJson(Map<String, dynamic> json) =>
      SyncFriendRequest(
        requestId: _asInt(json['requestId']),
        senderId: json['senderId']?.toString() ?? '',
        senderName: json['senderName']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}

class SyncFriend {
  const SyncFriend({
    required this.studentId,
    required this.name,
    required this.profilePicVersion,
  });

  final String studentId;
  final String name;
  final int profilePicVersion;

  factory SyncFriend.fromJson(Map<String, dynamic> json) => SyncFriend(
        studentId: json['studentId']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        profilePicVersion: _asInt(json['profilePicVersion']),
      );
}

class TimetableDocument {
  const TimetableDocument({required this.events});

  final List<Event> events;

  factory TimetableDocument.fromJsonValue(Object? value) {
    Object? decoded = value;
    if (decoded is String) {
      try {
        decoded = jsonDecodeString(decoded);
      } on FormatException {
        return const TimetableDocument(events: []);
      }
    }

    final json = _asJsonMap(decoded);
    final data = json['data'];
    if (data is! List) return const TimetableDocument(events: []);

    final events = <Event>[];
    for (final item in data) {
      if (item is! Map) continue;
      try {
        events.add(Event.fromTimetableJson(_asJsonMap(item)));
      } on FormatException {
        // Ignore malformed rows as the previous parser did by failing to
        // construct a usable timetable response.
      }
    }
    return TimetableDocument(events: events);
  }
}

Map<String, dynamic> _asJsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.map((key, value) => MapEntry('$key', value));
  return const {};
}

int _asInt(Object? value) => value is int ? value : int.tryParse('$value') ?? 0;

Object? jsonDecodeString(String value) {
  return jsonDecode(value);
}
