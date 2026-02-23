class Transaction {
  String date;
  String details;
  String action;
  String amount;
  String balance;

  Transaction(
    this.date,
    this.details,
    this.action,
    this.amount,
    this.balance,
  );
}

class RunshawPayException implements Exception {
  String cause;
  RunshawPayException(this.cause);
}

class Event {
  final String summary;
  final DateTime start;
  final DateTime end;
  final String? description;
  final String uid;
  final String? location;

  Event({
    required this.summary,
    required this.start,
    required this.end,
    required this.uid,
    this.description,
    this.location,
  });
}
