import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a single week's class schedule within a month.
class ClassSchedule {
  final int weekNumber; // 1, 2, 3, 4
  final DateTime date;

  ClassSchedule({required this.weekNumber, required this.date});

  Map<String, dynamic> toMap() {
    return {
      'weekNumber': weekNumber,
      'date': Timestamp.fromDate(date),
    };
  }

  factory ClassSchedule.fromMap(Map<String, dynamic> map) {
    return ClassSchedule(
      weekNumber: map['weekNumber'] ?? 1,
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  ClassSchedule copyWith({int? weekNumber, DateTime? date}) {
    return ClassSchedule(
      weekNumber: weekNumber ?? this.weekNumber,
      date: date ?? this.date,
    );
  }
}

/// Monthly schedule entry for a class.
class MonthlySchedule {
  final int month;
  final int year;
  final List<ClassSchedule> weeks;

  MonthlySchedule({
    required this.month,
    required this.year,
    required this.weeks,
  });

  Map<String, dynamic> toMap() {
    return {
      'month': month,
      'year': year,
      'weeks': weeks.map((w) => w.toMap()).toList(),
    };
  }

  factory MonthlySchedule.fromMap(Map<String, dynamic> map) {
    return MonthlySchedule(
      month: map['month'] ?? 1,
      year: map['year'] ?? DateTime.now().year,
      weeks: (map['weeks'] as List<dynamic>?)
              ?.map((w) => ClassSchedule.fromMap(Map<String, dynamic>.from(w)))
              .toList() ??
          [],
    );
  }
}

/// Audit log entry for tracking changes.
class AuditEntry {
  final String field;
  final dynamic oldValue;
  final dynamic newValue;
  final DateTime changedAt;
  final String changedBy;

  AuditEntry({
    required this.field,
    this.oldValue,
    this.newValue,
    DateTime? changedAt,
    this.changedBy = '',
  }) : changedAt = changedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'field': field,
      'oldValue': oldValue?.toString(),
      'newValue': newValue?.toString(),
      'changedAt': Timestamp.fromDate(changedAt),
      'changedBy': changedBy,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      field: map['field'] ?? '',
      oldValue: map['oldValue'],
      newValue: map['newValue'],
      changedAt: (map['changedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      changedBy: map['changedBy'] ?? '',
    );
  }
}

class ClassModel {
  final String id;
  final String className;
  final String teacherId;
  final double teacherCommissionRate;
  final List<String> studentIds;
  final double classFees;
  final int numberOfWeeks; // How many weeks per month (typically 4)
  final bool isDeleted;
  final List<AuditEntry> auditLog;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ClassModel({
    required this.id,
    required this.className,
    this.teacherId = '',
    this.teacherCommissionRate = 0.0,
    this.studentIds = const [],
    this.classFees = 0.0,
    this.numberOfWeeks = 4,
    this.isDeleted = false,
    this.auditLog = const [],
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'className': className,
      'teacherId': teacherId,
      'teacherCommissionRate': teacherCommissionRate,
      'studentIds': studentIds,
      'classFees': classFees,
      'numberOfWeeks': numberOfWeeks,
      'isDeleted': isDeleted,
      'auditLog': auditLog.map((a) => a.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
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
      numberOfWeeks: map['numberOfWeeks'] ?? 4,
      isDeleted: map['isDeleted'] ?? false,
      auditLog: (map['auditLog'] as List<dynamic>?)
              ?.map((a) => AuditEntry.fromMap(Map<String, dynamic>.from(a)))
              .toList() ??
          [],
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  ClassModel copyWith({
    String? id,
    String? className,
    String? teacherId,
    double? teacherCommissionRate,
    List<String>? studentIds,
    double? classFees,
    int? numberOfWeeks,
    bool? isDeleted,
    List<AuditEntry>? auditLog,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassModel(
      id: id ?? this.id,
      className: className ?? this.className,
      teacherId: teacherId ?? this.teacherId,
      teacherCommissionRate:
          teacherCommissionRate ?? this.teacherCommissionRate,
      studentIds: studentIds ?? this.studentIds,
      classFees: classFees ?? this.classFees,
      numberOfWeeks: numberOfWeeks ?? this.numberOfWeeks,
      isDeleted: isDeleted ?? this.isDeleted,
      auditLog: auditLog ?? this.auditLog,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
