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
