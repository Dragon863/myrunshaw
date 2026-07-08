import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

class OnBoardingStageThree extends StatefulWidget {
  const OnBoardingStageThree({super.key});

  @override
  State<OnBoardingStageThree> createState() => _OnBoardingStageThreeState();
}

class _OnBoardingStageThreeState extends State<OnBoardingStageThree> {
  String? busNumber;
  BaseAPI? api;
  List<String> _extraBuses = [];
  List<String> _availableBuses = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  late ValueNotifier<String?> _busNumberNotifier;

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
    _busNumberNotifier = ValueNotifier<String?>(null);
    populateBusList();
    fetchCurrentBuses();
    super.initState();
  }

  @override
  void dispose() {
    _busNumberNotifier.dispose();
    super.dispose();
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
                child: DropdownButtonFormField2<String>(
                  isExpanded: true,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    hintText: busNumber,
                  ),
                  hint: const Text(
                    'Select Your Bus',
                    style: TextStyle(fontSize: 14),
                  ),
                  items: _availableBuses
                      .map((item) => DropdownItem<String>(
                            value: item.toString(),
                            child: Text(
                              item.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ))
                      .toList(),
                  validator: (value) {
                    if (value == null) {
                      return 'Please select bus.';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    _busNumberNotifier.value = value;
                    busNumber = value;
                  },
                  dropdownStyleData: DropdownStyleData(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  valueListenable: _busNumberNotifier,
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
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "If you use the college bus services, you can subscribe to push notifications for when they arrive. Please add any you wish to subscribe to.",
              style: GoogleFonts.rubik(
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
