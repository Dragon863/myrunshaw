import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:runshaw/utils/api.dart';
import 'package:runshaw/utils/config.dart';

class OnBoardingStageThree extends StatefulWidget {
  const OnBoardingStageThree({super.key});

  @override
  State<OnBoardingStageThree> createState() => _OnBoardingStageThreeState();
}

class _OnBoardingStageThreeState extends State<OnBoardingStageThree> {
  String? busNumber;
  BaseAPI? api;
  List<String> _extraBuses = [];
  bool _loading = true;
  final _formKey = GlobalKey<FormState>();

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
                    Navigator.pop(context);
                    fetchCurrentBuses();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 150,
                  maxWidth: 600,
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.fromSize(
                      size: const Size.fromRadius(120),
                      child: Image.asset('assets/img/stage3.png'),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "Setup Buses",
              style: GoogleFonts.rubik(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "If you take the bus to college, you can be notified when your bus arrives at the college with the bay number it is at. Please add any college buses you take below.",
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
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
                ? const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(),
                      ),
                      SizedBox(width: 8),
                      Text("Please wait..."),
                    ],
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
