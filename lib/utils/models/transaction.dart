class Transaction {
  final String date;
  final String details;
  final String action;
  final String amount;
  final String balance;

  Transaction(
    this.date,
    this.details,
    this.action,
    this.amount,
    this.balance,
  );

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        json['date']?.toString() ?? '',
        json['details']?.toString() ?? '',
        json['action']?.toString() ?? '',
        json['amount']?.toString() ?? '',
        json['balance']?.toString() ?? '',
      );
}
