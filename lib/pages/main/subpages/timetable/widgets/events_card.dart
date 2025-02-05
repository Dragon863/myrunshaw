import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EventsCard extends StatelessWidget {
  final String lessonName;
  final String roomAndTeacher;
  final String timing;
  final Color color;
  final bool dense;
  final Function()? onTap;

  const EventsCard({
    super.key,
    required this.lessonName,
    required this.roomAndTeacher,
    required this.timing,
    required this.color,
    this.dense = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(6),
          bottomLeft: Radius.circular(6),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(6),
            bottomLeft: Radius.circular(6),
          ),
        ),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                  color: color,
                ),
                width: 5,
                child: const SizedBox.expand(),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(dense ? 4.0 : 6.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        timing,
                        style: GoogleFonts.rubik(
                          fontSize: 14,
                          color: color,
                        ),
                      ),
                      Text(
                        lessonName,
                        style: GoogleFonts.rubik(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (!dense)
                        Text(
                          roomAndTeacher,
                          style: GoogleFonts.rubik(
                            fontSize: 14,
                          ),
                        )
                    ],
                  ),
                ),
              ),
              onTap != null
                  ? const Padding(
                      padding: EdgeInsets.only(right: 6.0),
                      child: Icon(Icons.keyboard_arrow_right),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
