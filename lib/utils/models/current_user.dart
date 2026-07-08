class CurrentUser {
  final String id;
  final String name;
  final int profilePicVersion;
  final bool hasTimetableLinked;

  // Appwrite compatibility getters
  String get $id => id;
  String get email =>
      "$id@student.runshaw.ac.uk"; // Dynamically generated email

  CurrentUser({
    required this.id,
    required this.name,
    required this.profilePicVersion,
    required this.hasTimetableLinked,
  });

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    return CurrentUser(
      id: json['studentId'] ?? '',
      name: json['name'] ?? '',
      profilePicVersion: json['profilePicVersion'] ?? 0,
      hasTimetableLinked: json['hasTimetableLinked'] ?? false,
    );
  }
}
