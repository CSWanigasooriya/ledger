import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String classId;
  final String studentId;
  final DateTime date;
  final bool isPresent;
  final String markedBy;

  Attendance({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.date,
    this.isPresent = false,
    this.markedBy = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'classId': classId,
      'studentId': studentId,
      'date': Timestamp.fromDate(date),
      'isPresent': isPresent,
      'markedBy': markedBy,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPresent: map['isPresent'] ?? false,
      markedBy: map['markedBy'] ?? '',
    );
  }

  Attendance copyWith({
    String? id,
    String? classId,
    String? studentId,
    DateTime? date,
    bool? isPresent,
    String? markedBy,
  }) {
    return Attendance(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      studentId: studentId ?? this.studentId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      markedBy: markedBy ?? this.markedBy,
    );
  }
}
