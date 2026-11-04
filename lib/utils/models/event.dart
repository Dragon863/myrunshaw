class Event {
  final String summary;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String uid;
  final String? location;

  Event({
    required this.summary,
    required this.start,
    required this.end,
    required this.uid,
    this.description,
    this.location,
  });

  factory Event.fromTimetableJson(Map<String, dynamic> json) {
    final start = _readTimetableDate(json['dtstart']);
    final end = _readTimetableDate(json['dtend']);

    return Event(
      summary: json['summary']?.toString() ?? '',
      location: json['location']?.toString(),
      start: start,
      end: end,
      description: json['description']?.toString(),
      uid: json['uid']?.toString() ?? '',
    );
  }
}

DateTime _readTimetableDate(Object? value) {
  final dateValue = value is Map ? value['dt'] : value;
  if (dateValue is DateTime) return dateValue;
  if (dateValue is String) return DateTime.parse(dateValue);
  throw const FormatException('Timetable event has an invalid date');
}
