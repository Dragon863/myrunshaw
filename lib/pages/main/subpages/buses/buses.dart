import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusesPage extends StatefulWidget {
  const BusesPage({super.key});

  @override
  State<BusesPage> createState() => _BusesPageState();
}

class _BusesPageState extends State<BusesPage> {
  String myBus = '762';
  List<String> toDisplay = ["has", "not yet arrived"];
  bool loading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 750) {
                  return Image.asset(
                    "assets/img/busesmap.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  );
                } else {
                  return Image.asset(
                    "assets/img/busesmap.png",
                    width: MediaQuery.of(context).size.width / 1.5,
                    fit: BoxFit.cover,
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                text: 'The ',
                style: GoogleFonts.rubik(
                  fontSize: 24,
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
                children: <TextSpan>[
                  TextSpan(
                    text: myBus,
                    style: GoogleFonts.rubik(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  TextSpan(text: " ${toDisplay[0]}"),
                  TextSpan(
                    text: ' ${toDisplay[1]}',
                    style: GoogleFonts.rubik(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            
          ],
        ),
      ),
    );
  }
}
