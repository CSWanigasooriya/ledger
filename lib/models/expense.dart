import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String type;
  final String description;
  final double amount;
  final DateTime date;

  Expense({
    required this.id,
    required this.type,
    this.description = '',
    required this.amount,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      type: map['type'] ?? 'Other',
      description: map['description'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Expense copyWith({
    String? id,
    String? type,
    String? description,
    double? amount,
    DateTime? date,
  }) {
    return Expense(
      id: id ?? this.id,
      type: type ?? this.type,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }
}
