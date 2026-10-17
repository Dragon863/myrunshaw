import 'package:material_ui/material_ui.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/theme/appbar.dart';
import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

class ExtraBusPage extends StatefulWidget {
  const ExtraBusPage({super.key});

  @override
  State<ExtraBusPage> createState() => _ExtraBusPageState();
}

class _ExtraBusPageState extends State<ExtraBusPage> {
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
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 8),
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
    return Scaffold(
      appBar: const RunshawAppBar(title: "My Buses"),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 150,
                maxWidth: 700,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 18),
                  Text(
                    "Use this page to add or remove extra buses you want push notifications for! These will show up in the 'Buses' page on the sidebar.",
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 18),
                  ListView.builder(
                    shrinkWrap: true,
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
                      ? SizedBox.square(
                          dimension: 32,
                          child: LoadingIndicator(),
                        )
                      : Align(
                          alignment: Alignment.bottomRight,
                          child: ElevatedButton(
                            onPressed: addBus,
                            child: const Text("Add Bus"),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
