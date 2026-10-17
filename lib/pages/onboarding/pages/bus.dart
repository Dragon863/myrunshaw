import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

class OnBoardingBusStage extends StatefulWidget {
  const OnBoardingBusStage({super.key});

  @override
  State<OnBoardingBusStage> createState() => _OnBoardingBusStageState();
}

class _OnBoardingBusStageState extends State<OnBoardingBusStage> {
  String? busNumber;
  BaseAPI? api;
  List<String> _extraBuses = [];
  List<String> _availableBuses = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

  Future<void> fetchCurrentBuses() async {
    setState(() {
      _loading = true;
    });
    final api = context.read<BaseAPI>();
    final response = await api.getAllSubscribedBuses();
    response.sort((a, b) => a.compareTo(b));

    setState(() {
      _extraBuses = response;
      _loading = false;
    });
  }

  Future<void> populateBusList() async {
    final api = context.read<BaseAPI>();
    final List<Map<String, dynamic>> response = await api.getBusArrivals();

    setState(() {
      _availableBuses =
          response.map((bus) => bus['bus_id'].toString()).toList();
    });
  }

  @override
  void initState() {
    FocusManager.instance.primaryFocus?.unfocus();
    populateBusList();
    fetchCurrentBuses();
    super.initState();
  }

  Future<void> addBus() async {
    if (_availableBuses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text("Please wait a second while we fetch the available buses!"),
        ),
      );
      return;
    }

    final api = context.read<BaseAPI>();
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Add a Bus"),
            content: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FormField<String>(
                  initialValue: busNumber,
                  validator: (value) =>
                      value == null ? 'Please select bus.' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownMenu<String>(
                        initialSelection: field.value,
                        expandedInsets: EdgeInsets.zero,
                        hintText: 'Select Your Bus',
                        inputDecorationTheme: InputDecorationTheme(
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        dropdownMenuEntries: _availableBuses
                            .map((item) => DropdownMenuEntry<String>(
                                  value: item,
                                  label: item,
                                ))
                            .toList(),
                        onSelected: (value) {
                          field.didChange(value);
                          busNumber = value;
                        },
                      ),
                      if (field.errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 12, top: 8),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      await api.addBus(busNumber!);
                      if (!mounted) return;
                      Navigator.pop(context);
                      fetchCurrentBuses();
                    } catch (e) {
                      if (!mounted) return;
                      await Posthog().captureException(
                        error: e,
                        stackTrace: StackTrace.current,
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    }
                  }
                },
                child: const Text("Add"),
              ),
            ],
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 250,
                ),
                child: Image.asset('assets/img/onboarding/bus-graphic.png'),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Bus Tracking",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "If you use the college bus services, you can subscribe to push notifications for when they arrive. Please add any you wish to subscribe to.",
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics:
                  const NeverScrollableScrollPhysics(), // already in a scroll view
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_extraBuses[index]),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      try {
                        await context.read<BaseAPI>().removeBus(
                              _extraBuses[index],
                            );
                        fetchCurrentBuses();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
              itemCount: _extraBuses.length,
            ),
            _loading
                ? Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: LoadingIndicator(),
                        ),
                        SizedBox(width: 8),
                        Text("Please wait..."),
                      ],
                    ),
                  )
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: addBus,
                      child: const Text("Add a Bus"),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
