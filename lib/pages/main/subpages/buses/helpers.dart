List<double> calculatePosition(String bayNumber) {
  double xPercentage = 0.0;
  double yPercentage = 0.0;

  switch (bayNumber) {
    // T1 and T2 are special cases
    case "T1":
      xPercentage = 0.84;
      yPercentage = 0.55;
      return [xPercentage, yPercentage];
    case "T2":
      xPercentage = 0.84;
      yPercentage = 0.37;
      return [xPercentage, yPercentage];
  }
  final bayChar = bayNumber[0];
  final bayNum = int.parse(bayNumber.substring(1));
  xPercentage = 0.75 - (bayNum - 1) * 0.095;
  switch (bayChar) {
    case "A":
      yPercentage = 0.40;
      return [xPercentage, yPercentage];
    case "B":
      yPercentage = 0.48;
      return [xPercentage, yPercentage];
    case "C":
      yPercentage = 0.54;
      return [xPercentage, yPercentage];
  }
  return [xPercentage, yPercentage];
}
