import 'package:flutter/widgets.dart';

String getFirstNameCharacter(String name) {
  // Get the first character of the name. If it's an emoji, we need to get the next character (in a loop), as flutter will only render
  // utf-16 characters, and emojis are not in that range which causes renderer bugs.
  final List<String> letters = [
    "A",
    "B",
    "C",
    "D",
    "E",
    "F",
    "G",
    "H",
    "I",
    "J",
    "K",
    "L",
    "M",
    "N",
    "O",
    "P",
    "Q",
    "R",
    "S",
    "T",
    "U",
    "V",
    "W",
    "X",
    "Y",
    "Z"
  ];

  if (name.isEmpty) {
    return '?';
  }
  final firstChar = name[0];

  if (!letters.contains(firstChar.toUpperCase())) {
    // This is an emoji
    for (int i = 1; i < name.length; i++) {
      // Find the next utf-16 character
      if (letters.contains(name[i].toUpperCase())) {
        // Found it!
        return name[i];
      }
    }
    return '?';
  }

  return firstChar.toUpperCase();
}

Color? getPfpColour(String url) {
  // I've temporarily disabled this function just because personally I think it looked better wihout it, but
  // leaving it here for future reference :)

  // // Get a color for the background of the CircleAvatar based on the URL of the profile picture.
  // // It gets one of the primary colours based on the hashed URL, and mutes it a little

  // final colors = [
  //   const Color(0xFFF44336),
  //   const Color(0xFFFF9800),
  //   const Color(0xFF8BC34A),
  //   const Color(0xFF009688),
  //   const Color(0xFF448AFF)
  // ];
  // final hash = url.hashCode;
  // final color = colors[hash % colors.length];
  // return color;
  return null;
}
