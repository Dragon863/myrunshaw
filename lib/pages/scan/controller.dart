bool validate(String input) {
  RegExp regExp = RegExp(r'^[a-zA-Z]{3}\d{8}-\d{6}$');

  if (regExp.hasMatch(input)) {
    return true;
  } else {
    return false;
  }
}
