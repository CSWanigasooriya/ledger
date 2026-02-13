import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String id;
  final String className;
  final String teacherId;
  final double teacherCommissionRate;
  final List<String> studentIds;
  final double classFees;
  final DateTime createdAt;

  ClassModel({
    required this.id,
    required this.className,
    this.teacherId = '',
    this.teacherCommissionRate = 0.0,
    this.studentIds = const [],
    this.classFees = 0.0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'teacherId': teacherId,
      'teacherCommissionRate': teacherCommissionRate,
      'studentIds': studentIds,
      'classFees': classFees,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> map) {
    return ClassModel(
      id: map['id'] ?? '',
      className: map['className'] ?? '',
      teacherId: map['teacherId'] ?? '',
      teacherCommissionRate: (map['teacherCommissionRate'] ?? 0.0).toDouble(),
      studentIds: List<String>.from(map['studentIds'] ?? []),
      classFees: (map['classFees'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ClassModel copyWith({
    String? id,
    String? className,
    String? teacherId,
    double? teacherCommissionRate,
    List<String>? studentIds,
    double? classFees,
    DateTime? createdAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherCommissionRate:
          teacherCommissionRate ?? this.teacherCommissionRate,
      studentIds: studentIds ?? this.studentIds,
      classFees: classFees ?? this.classFees,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
