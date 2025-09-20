import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/friends/individual/split/compact_event_card.dart';
import 'package:runshaw/pages/main/subpages/timetable/subpages/individual_event.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/extensions.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:runshaw/pages/sync/sync_controller.dart' as runshaw;

Color getEventColour(String eventName) {
  return eventName.contains("Aspire")
      ? Colors.green
      : eventName.contains("Exam")
          ? Colors.red
          : Colors.blue;
}

class SplitTimetablePage extends StatefulWidget {
  final String friendId;
  final String friendName;

  const SplitTimetablePage({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  @override
  State<SplitTimetablePage> createState() => _SplitTimetablePageState();
}

class _SplitTimetablePageState extends State<SplitTimetablePage> {
  bool _isLoading = true;
  List<runshaw.Event> _myEvents = [];
  List<runshaw.Event> _friendEvents = [];
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadTimetables();
  }

  Future<void> _loadTimetables() async {
    final api = context.read<BaseAPI>();
    final myEvents =
        (await api.fetchEvents(allowCache: true, includeAll: true)).fillGaps();
    final friendEvents = (await api.fetchEvents(
            userId: widget.friendId, allowCache: true, includeAll: true))
        .fillGaps();

    if (mounted) {
      setState(() {
        _myEvents = myEvents;
        _friendEvents = friendEvents;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myTodaysEvents = _myEvents
        .where((e) =>
            e.start.year == _selectedDate.year &&
            e.start.month == _selectedDate.month &&
            e.start.day == _selectedDate.day)
        .toList();
    final friendTodaysEvents = _friendEvents
        .where((e) =>
            e.start.year == _selectedDate.year &&
            e.start.month == _selectedDate.month &&
            e.start.day == _selectedDate.day)
        .toList();

    const heightPerMinute = 1.0;
    // start at first event in your or friend's timetable, whichever is earlier. Default to 9am if no events
    final startHour = ((myTodaysEvents.isNotEmpty
                    ? myTodaysEvents.first.start.hour
                    : 9) <
                (friendTodaysEvents.isNotEmpty
                    ? friendTodaysEvents.first.start.hour
                    : 9)
            ? (myTodaysEvents.isNotEmpty ? myTodaysEvents.first.start.hour : 9)
            : (friendTodaysEvents.isNotEmpty
                ? friendTodaysEvents.first.start.hour
                : 9))
        .clamp(8, 14); // clamp between 8am and 2pm to avoid extreme cases

    // same applies to end hour - last event + 1 hour, default to 5pm
    final endHour = (myTodaysEvents.isNotEmpty
                ? myTodaysEvents.last.end.hour
                : 17) >
            (friendTodaysEvents.isNotEmpty
                ? friendTodaysEvents.last.end.hour
                : 17)
        ? ((myTodaysEvents.isNotEmpty ? myTodaysEvents.last.end.hour : 17) + 1)
        : ((friendTodaysEvents.isNotEmpty
                    ? friendTodaysEvents.last.end.hour
                    : 17) +
                1)
            .clamp(10, 18); // clamp between 10am and 6pm

    const timeLineWidth = 28.0;

    return Scaffold(
      appBar: const RunshawAppBar(
        title: 'Compare',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.subtract(const Duration(days: 1));
                          });
                        },
                      ),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: GoogleFonts.rubik(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const SizedBox(width: timeLineWidth),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'You',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          widget.friendName,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.rubik(
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Stack(
                      children: [
                        _buildHourLines(
                            startHour, endHour, heightPerMinute, timeLineWidth),
                        Row(
                          children: [
                            const SizedBox(width: timeLineWidth),
                            Expanded(
                              child: _buildEventColumn(
                                  myTodaysEvents, startHour, heightPerMinute),
                            ),
                            Expanded(
                              child: _buildEventColumn(friendTodaysEvents,
                                  startHour, heightPerMinute),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHourLines(
      int startHour, int endHour, double heightPerMinute, double width) {
    return Positioned(
      left: 0,
      top: 0,
      width: width,
      height: (endHour - startHour) * 60 * heightPerMinute,
      child: Column(
        children: List.generate(endHour - startHour, (index) {
          final hour = startHour + index;
          return SizedBox(
            height: 60 * heightPerMinute,
            child: Text(
              '$hour',
              style: GoogleFonts.rubik(fontSize: 10),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEventColumn(
      List<runshaw.Event> events, int startHour, double heightPerMinute) {
    return Container(
      height: (17 - 8) * 60 * heightPerMinute,
      child: Stack(
        children: events.map((event) {
          final top = (event.start.hour - startHour) * 60 * heightPerMinute +
              event.start.minute * heightPerMinute;
          final height =
              event.end.difference(event.start).inMinutes * heightPerMinute;

          return Positioned(
            top: top,
            left: 0,
            right: 0,
            height: height,
            child: CompactEventCard(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IndividualEventPage(
                      eventName: event.summary,
                      eventDescription: event.description,
                      eventLocation: event.location,
                      dtStart: event.start,
                      dtEnd: event.end,
                      color: getEventColour(event.summary),
                    ),
                  ),
                );
              },
              lessonName: event.summary,
              roomAndTeacher: event.description ?? '',
              timing:
                  "${TimeOfDay.fromDateTime(event.start).format(context)} - ${TimeOfDay.fromDateTime(event.end).format(context)}",
              color: getEventColour(event.summary),
            ),
          );
        }).toList(),
      ),
    );
  }
}
