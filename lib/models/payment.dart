import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  final String id;
  final String classId;
  final String studentId;
  final double amount;
  final DateTime date;
  final int month;
  final int year;
  final bool isFreeCard; // Was this a free card student (for records)
  final bool institutePaid; // Has the institute paid the teacher for this
  final DateTime? institutePaidDate;

  Payment({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.amount,
    DateTime? date,
    int? month,
    int? year,
    this.isFreeCard = false,
    this.institutePaid = false,
    this.institutePaidDate,
  }) : date = date ?? DateTime.now(),
       month = month ?? (date ?? DateTime.now()).month,
       year = year ?? (date ?? DateTime.now()).year;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'month': month,
      'year': year,
      'isFreeCard': isFreeCard,
      'institutePaid': institutePaid,
      'institutePaidDate': institutePaidDate != null
          ? Timestamp.fromDate(institutePaidDate!)
          : null,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
      isFreeCard: map['isFreeCard'] ?? false,
      institutePaid: map['institutePaid'] ?? false,
      institutePaidDate:
          (map['institutePaidDate'] as Timestamp?)?.toDate(),
    );
  }

  Payment copyWith({
    String? id,
    String? classId,
    String? studentId,
    double? amount,
    DateTime? date,
    int? month,
    int? year,
    bool? isFreeCard,
    bool? institutePaid,
    DateTime? institutePaidDate,
  }) {
    return Payment(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      month: month ?? this.month,
      year: year ?? this.year,
      isFreeCard: isFreeCard ?? this.isFreeCard,
      institutePaid: institutePaid ?? this.institutePaid,
      institutePaidDate: institutePaidDate ?? this.institutePaidDate,
    );
  }
}
