import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final int weekNumber; // 1-4, which week of the month
  final bool isPresent;
  final String markedBy;
  final String? studentDisplayId; // Auto-increment ID for display

  Attendance({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    this.weekNumber = 0,
    this.isPresent = false,
    this.markedBy = '',
    this.studentDisplayId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'weekNumber': weekNumber,
      'isPresent': isPresent,
      'markedBy': markedBy,
      'studentDisplayId': studentDisplayId,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      weekNumber: map['weekNumber'] ?? 0,
      isPresent: map['isPresent'] ?? false,
      markedBy: map['markedBy'] ?? '',
      studentDisplayId: map['studentDisplayId'],
    );
  }

  Attendance copyWith({
    String? id,
    String? classId,
    String? studentId,
    DateTime? date,
    int? weekNumber,
    bool? isPresent,
    String? markedBy,
    String? studentDisplayId,
  }) {
    return Attendance(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      weekNumber: weekNumber ?? this.weekNumber,
      isPresent: isPresent ?? this.isPresent,
      markedBy: markedBy ?? this.markedBy,
      studentDisplayId: studentDisplayId ?? this.studentDisplayId,
    );
  }
}
