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
}
