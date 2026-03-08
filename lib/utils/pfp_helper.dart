String getFirstNameCharacter(String name) {
  // Get the first character of the name. If it's an emoji, we need to get the next character (in a loop), as flutter will only render
  // utf-16 characters, and emojis are not in that range which causes renderer bugs.

  if (name.isEmpty) {
    return '?';
  }
  final firstChar = name[0];

  if (!RegExp(r'[a-zA-Z]').hasMatch(firstChar)) {
    // This is an emoji
    for (int i = 1; i < name.length; i++) {
      // Find the next utf-16 character
      if (RegExp(r'[a-zA-Z]').hasMatch(name[i])) {
        // Found it!
        return name[i];
      }
    }
    return '?';
  }

  return firstChar.toUpperCase();
}
