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
  final _formKey = GlobalKey<FormState>();

  Future<void> fetchPrefs() async {
    final BaseAPI api = context.read<BaseAPI>();
    final busNumber = await api.getBusNumber();

    setState(() {
      this.busNumber = busNumber;
    });
  }

  @override
  void initState() {
    fetchPrefs();
    super.initState();
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
              "If you take the bus to college, you can be notified when your bus arrives at the college with the bay number it is at. You can set your bus number below",
              style: GoogleFonts.rubik(
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButtonFormField2<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      enabled: busNumber != null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    hint: const Text(
                      'Bus Number',
                      style: TextStyle(fontSize: 14),
                    ),
                    items: [
                      ...Config.busNumbers
                          .map((item) => DropdownMenuItem<String>(
                                value: item.toString(),
                                child: Text(
                                  item.toString(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              )),
                      const DropdownMenuItem(
                        value: "000",
                        child: Text("No Bus"),
                      ),
                    ],
                    validator: (value) {
                      if (value == null) {
                        return 'Please select bus number.';
                      }
                      return null;
                    },
                    onChanged: (value) async {
                      final api = context.read<BaseAPI>();
                      try {
                        await api.setBusNumber(value);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Bus number updated!"),
                          ),
                        );
                      } catch (e) {
                        print(e);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Error setting bus number"),
                          ),
                        );
                      }
                    },
                    buttonStyleData: const ButtonStyleData(
                      padding: EdgeInsets.only(right: 8),
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
