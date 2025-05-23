import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';
import 'package:runshaw/utils/theme/appbar.dart';

class ExtraBusPage extends StatefulWidget {
  const ExtraBusPage({super.key});

  @override
  State<ExtraBusPage> createState() => _ExtraBusPageState();
}

class _ExtraBusPageState extends State<ExtraBusPage> {
  List<String> _extraBuses = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();
  String? busNumber;

  Future<void> fetchCurrentBuses() async {
    setState(() {
      _loading = true;
    });
    final api = context.read<BaseAPI>();
    final response = await api.getAllBuses();

    setState(() {
      _extraBuses = response;
      _loading = false;
    });
  }

  @override
  void initState() {
    fetchCurrentBuses();
    super.initState();
  }

  Future<void> addBus() async {
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
                  ),
                  hint: const Text(
                    'Select Your Bus Number',
                    style: TextStyle(fontSize: 14),
                  ),
                  items: MyRunshawConfig.busNumbers
                      .map((item) => DropdownMenuItem<String>(
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
                      return 'Please select bus number.';
                    }
                    return null;
                  },
                  onChanged: (value) async {
                    setState(() {
                      busNumber = value;
                    });
                  },
                  buttonStyleData: const ButtonStyleData(
                    padding: EdgeInsets.only(right: 16),
                  ),
                  iconStyleData: const IconStyleData(
                    icon: Icon(
                      Icons.arrow_drop_down,
                      color: Colors.black45,
                    ),
                    iconSize: 24,
                  ),
                  dropdownStyleData: DropdownStyleData(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  menuItemStyleData: const MenuItemStyleData(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                  ),
                  value: busNumber,
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
                      await api.addExtraBus(busNumber!);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(e.toString()),
                        ),
                      );
                    }
                    if (mounted) {
                      Navigator.pop(context);
                    }
                    await fetchCurrentBuses();
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
                    style: GoogleFonts.rubik(
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
                              await context.read<BaseAPI>().removeExtraBus(
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
                      ? const CircularProgressIndicator()
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
