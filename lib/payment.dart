import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final double amount;
  final DateTime date;

  Payment({required this.amount, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      amount: map['amount'],
      date: (map['date'] as Timestamp).toDate(),
    );
  }
}