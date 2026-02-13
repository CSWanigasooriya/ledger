import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherPayment {
  final String id;
  final String teacherId;
  final double amount;
  final int month;
  final int year;
  final double salesAmount;
  final double commissionAmount;
  final DateTime date;
  final String notes;

  TeacherPayment({
    required this.id,
    required this.teacherId,
    required this.amount,
    required this.month,
    required this.year,
    this.salesAmount = 0.0,
    this.commissionAmount = 0.0,
    DateTime? date,
    this.notes = '',
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teacherId': teacherId,
      'amount': amount,
      'month': month,
      'year': year,
      'salesAmount': salesAmount,
      'commissionAmount': commissionAmount,
      'date': Timestamp.fromDate(date),
      'notes': notes,
    };
  }

  factory TeacherPayment.fromMap(Map<String, dynamic> map) {
    return TeacherPayment(
      id: map['id'] ?? '',
      teacherId: map['teacherId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      salesAmount: (map['salesAmount'] ?? 0.0).toDouble(),
      commissionAmount: (map['commissionAmount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }

  TeacherPayment copyWith({
    String? id,
    String? teacherId,
    double? amount,
    int? month,
    int? year,
    double? salesAmount,
    double? commissionAmount,
    DateTime? date,
    String? notes,
  }) {
    return TeacherPayment(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      amount: amount ?? this.amount,
      month: month ?? this.month,
      year: year ?? this.year,
      salesAmount: salesAmount ?? this.salesAmount,
      commissionAmount: commissionAmount ?? this.commissionAmount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
    );
  }
}
