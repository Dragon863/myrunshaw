// import 'package:dropdown_button2/dropdown_button2.dart';
// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:provider/provider.dart';
// import 'package:runshaw/utils/api.dart';
// import 'package:runshaw/utils/theme/appbar.dart';
// import 'package:runshaw/utils/vendor/spinner/loading_indicator.dart';

// class ExtraBusPage extends StatefulWidget {
//   const ExtraBusPage({super.key});

//   @override
//   State<ExtraBusPage> createState() => _ExtraBusPageState();
// }

// class _ExtraBusPageState extends State<ExtraBusPage> {
//   List<String> _extraBuses = [];
//   List<String> _availableBuses = [];
//   bool _loading = true;
//   final _formKey = GlobalKey<FormState>();
//   String? busNumber;
//   late ValueNotifier<String?> _busNumberNotifier;

//   Future<void> fetchCurrentBuses() async {
//     setState(() {
//       _loading = true;
//     });
//     final api = context.read<BaseAPI>();
//     final response = await api.getAllSubscribedBuses();

//     setState(() {
//       _extraBuses = response;
//       _loading = false;
//     });
//   }

//   Future<void> populateBusList() async {
//     final api = context.read<BaseAPI>();
//     final List<Map<String, dynamic>> response = await api.getBusArrivals();

//     setState(() {
//       _availableBuses =
//           response.map((bus) => bus['bus_id'].toString()).toList();
//     });
//   }

//   @override
//   void initState() {
//     _busNumberNotifier = ValueNotifier<String?>(null);
//     fetchCurrentBuses();
//     super.initState();
//   }

//   @override
//   void dispose() {
//     _busNumberNotifier.dispose();
//     super.dispose();
//   }

//   Future<void> addBus() async {
//     final api = context.read<BaseAPI>();
//     await showDialog(
//         context: context,
//         builder: (context) {
//           return AlertDialog(
//             title: const Text("Add a Bus"),
//             content: Form(
//               key: _formKey,
//               child: Padding(
//                 padding: const EdgeInsets.all(8.0),
//                 child: DropdownButtonFormField2<String>(
//                   isExpanded: true,
//                   decoration: InputDecoration(
//                     contentPadding: const EdgeInsets.symmetric(vertical: 16),
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                     hintText: busNumber,
//                   ),
//                   hint: const Text(
//                     'Select Your Bus Number',
//                     style: TextStyle(fontSize: 14),
//                   ),
//                   items: _availableBuses
//                       .map((item) => DropdownItem<String>(
//                             value: item.toString(),
//                             child: Text(
//                               item.toString(),
//                               style: const TextStyle(
//                                 fontSize: 14,
//                               ),
//                             ),
//                           ))
//                       .toList(),
//                   validator: (value) {
//                     if (value == null) {
//                       return 'Please select bus number.';
//                     }
//                     return null;
//                   },
//                   onChanged: (value) {
//                     _busNumberNotifier.value = value;
//                     busNumber = value;
//                   },
//                   iconStyleData: IconStyleData(
//                     icon: Icon(
//                       Icons.arrow_drop_down,
//                       color: ColorScheme.of(context).onSurfaceVariant,
//                     ),
//                     iconSize: 18,
//                   ),
//                   dropdownStyleData: DropdownStyleData(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15),
//                     ),
//                   ),
//                   menuItemStyleData: const MenuItemStyleData(
//                     padding: EdgeInsets.symmetric(horizontal: 16),
//                   ),
//                   valueListenable: _busNumberNotifier,
//                 ),
//               ),
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: const Text("Cancel"),
//               ),
//               ElevatedButton(
//                 onPressed: () async {
//                   if (_formKey.currentState!.validate()) {
//                     try {
//                       await api.addBus(busNumber!);
//                     } catch (e) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text(e.toString()),
//                         ),
//                       );
//                     }
//                     if (mounted) {
//                       Navigator.pop(context);
//                     }
//                     await fetchCurrentBuses();
//                   }
//                 },
//                 child: const Text("Add"),
//               ),
//             ],
//           );
//         });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: const RunshawAppBar(title: "My Buses"),
//       body: SingleChildScrollView(
//         child: Center(
//           child: Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Container(
//               constraints: const BoxConstraints(
//                 minWidth: 150,
//                 maxWidth: 700,
//               ),
//               child: Column(
//                 children: [
//                   const SizedBox(height: 18),
//                   Text(
//                     "Use this page to add or remove extra buses you want push notifications for! These will show up in the 'Buses' page on the sidebar.",
//                     style: GoogleFonts.rubik(
//                       fontSize: 16,
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//                   ListView.builder(
//                     shrinkWrap: true,
//                     itemBuilder: (context, index) {
//                       return ListTile(
//                         title: Text(_extraBuses[index]),
//                         trailing: IconButton(
//                           icon: const Icon(Icons.delete_outline),
//                           onPressed: () async {
//                             try {
//                               await context.read<BaseAPI>().removeBus(
//                                     _extraBuses[index],
//                                   );
//                               fetchCurrentBuses();
//                             } catch (e) {
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 SnackBar(
//                                   content: Text(e.toString()),
//                                 ),
//                               );
//                             }
//                           },
//                         ),
//                       );
//                     },
//                     itemCount: _extraBuses.length,
//                   ),
//                   _loading
//                       ? SizedBox.square(
//                           dimension: 32,
//                           child: LoadingIndicator(),
//                         )
//                       : Align(
//                           alignment: Alignment.bottomRight,
//                           child: ElevatedButton(
//                             onPressed: addBus,
//                             child: const Text("Add Bus"),
//                           ),
//                         ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
