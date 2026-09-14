import 'package:flutter/material.dart';
import 'package:runshaw/utils/models/event.dart';

enum EventCategory {
  aspire,
  lesson,
  exam,
  appointment,
}

extension EventCategoryPresentation on EventCategory {
  Color get color {
    switch (this) {
      case EventCategory.aspire:
        return Colors.green.shade400;
      case EventCategory.lesson:
        return Colors.blue;
      case EventCategory.exam:
      case EventCategory.appointment:
        return Colors.red;
    }
  }
}

EventCategory categoriseEvent(Event event) {
  /*
  This needs a little explanation:
  # Aspire
  - Has no location, and the summary is "Aspire"
  # Lesson
  - Generally has a location, and the summary is the event name
  # Exam
  - Can have a location but often doesn't, and the summary is blank
  */
  if (event.summary == 'Aspire') {
    return EventCategory.aspire;
  }
  if (event.summary.isEmpty) {
    return EventCategory.exam;
  }
  if (event.summary.toLowerCase().contains('appointment')) {
    return EventCategory.appointment;
  }
  return EventCategory.lesson;
}
