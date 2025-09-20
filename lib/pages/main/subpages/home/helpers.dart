String truncateName(String name) {
  if (name.length > 18) {
    return "${name.substring(0, 18 - 3)}...";
  } else {
    return name;
  }
}
