import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TransactionCard extends StatelessWidget {
  final String topText;
  final String bottomText;
  final Widget trailing;

  const TransactionCard({
    super.key,
    required this.topText,
    required this.bottomText,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    right: 12, top: 12, bottom: 12, left: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      topText,
                      style: GoogleFonts.rubik(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      bottomText,
                      style: GoogleFonts.rubik(
                        fontSize: 14,
                      ),
                    )
                  ],
                ),
              ),
            ),
            trailing,
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}
