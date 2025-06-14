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
