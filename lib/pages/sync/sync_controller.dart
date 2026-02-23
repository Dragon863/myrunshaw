import 'package:flutter/material.dart';
import 'package:icalendar_parser/icalendar_parser.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:http/http.dart' as http;

Future<void> syncFromUrl(String icalUrl, BuildContext context) async {
  final BaseAPI api = context.read<BaseAPI>();
  final response = await http.get(Uri.parse(icalUrl));
  final events =
      ICalendar.fromString(response.body.replaceAll("PROID", "PRODID"));

  await api.syncTimetable(events);
  await api.associateTimetableUrl(icalUrl);
  await api.cacheTimetables();
}
