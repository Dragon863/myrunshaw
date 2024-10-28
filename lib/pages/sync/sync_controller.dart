import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:http/http.dart' as http;

class Event {
  final String summary;
  final String location;
  final DateTime start;
  final DateTime end;
  final String description;
  final String uid;

  Event({
    required this.summary,
    required this.location,
    required this.start,
    required this.end,
    required this.description,
    required this.uid,
  });
}

Future<void> syncFromUrl(String icalUrl, BuildContext context) async {
  final BaseAPI api = context.read<BaseAPI>();
  final response = await http.get(Uri.parse(icalUrl));
  final events = ICalendar.fromString(
      response.body.replaceAll("PROID", "PRODID")); // Hehe runshaw made a typo

  await api.syncTimetable(events);
}
