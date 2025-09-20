import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CompactEventCard extends StatelessWidget {
  final String lessonName;
  final String roomAndTeacher;
  final String timing;
  final Color color;
  final VoidCallback? onTap;
  final bool placeholder;

  const CompactEventCard({
    super.key,
    required this.lessonName,
    required this.roomAndTeacher,
    required this.timing,
    required this.color,
    this.onTap,
    this.placeholder = false,
  });

  @override
  Widget build(BuildContext context) {
    if (placeholder) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            border: Border(
              left: BorderSide(
                color: color,
                width: 4,
              ),
            ),
          ),
          child: Text(
            lessonName,
            style: GoogleFonts.rubik(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
