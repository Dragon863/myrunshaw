import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/pages/main/subpages/timetable/widgets/list.dart';
import 'package:runshaw/pages/sync/sync.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/models/event.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  @override
  State<TimetablePage> createState() => _TimetablePageState();
}

class _TimetablePageState extends State<TimetablePage> {
  List<Event> _events = [];
  String currentTitle = 'Loading...';

  @override
  void initState() {
    _refresh();
    super.initState();
  }

  Future<void> _refresh({bool allowCache = true}) async {
    final BaseAPI api = context.read<BaseAPI>();
    try {
      final List<Event> events = await api.fetchEvents(allowCache: allowCache);
      if (!mounted) return;
      if (events.isNotEmpty) {
        setState(() {
          _events = events;
          currentTitle = _fetchCurrentEvent();
        });
      } else {
        events.add(
          Event(
            summary: 'Events not found',
            location: '',
            start: DateTime.now(),
            end: DateTime.now(),
            description: 'Try syncing your timetable by tapping this card',
            uid: '',
          ),
        );
        setState(() {
          _events = events;
          currentTitle = "Not synced";
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred whilst syncing: $e"),
        ),
      );
    }
  }

  String _fetchCurrentEvent() {
    final now = DateTime.now();
    final currentEvent = _events.firstWhere(
      (event) {
        return event.start.isBefore(now) && event.end.isAfter(now);
      },
      orElse: () => Event(
        summary: 'No Event',
        location: '',
        start: now,
        end: now,
        description: '',
        uid: '',
      ),
    );
    return currentEvent.summary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Card(
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current:',
                      style: TextStyle(),
                    ),
                    Text(
                      currentTitle,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => await _refresh(allowCache: false),
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 700,
                ),
                child: TimetableList(events: _events),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SyncPage(),
            ),
          ).then((value) {
            Future.delayed(const Duration(milliseconds: 1000), () {
              // Allow changes to propogate
              _refresh();
            });
          });
        },
        child: const Icon(Icons.sync),
      ),
    );
  }
}
