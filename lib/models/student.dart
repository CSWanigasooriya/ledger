import 'package:cloud_firestore/cloud_firestore.dart';

/// Grade prefix mapping for auto-increment student IDs.
/// Grade 10 → 'B', Grade 11 → 'C', Grade 12 → 'D', Grade 13 → 'E'
class GradeConfig {
  static const Map<String, String> gradePrefixMap = {
    '10': 'B',
    '11': 'C',
    '12': 'D',
    '13': 'E',
  };

  static String prefixForGrade(String grade) {
    return gradePrefixMap[grade] ?? 'A';
  }

  static String? gradeForPrefix(String prefix) {
    for (final entry in gradePrefixMap.entries) {
      if (entry.value == prefix) return entry.key;
    }
    return null;
  }

  static List<String> get grades => gradePrefixMap.keys.toList();
}

enum StudentStatus {
  active,
  inactive,
  discontinued;

  String get displayName {
    switch (this) {
      case StudentStatus.active:
        return 'Active';
      case StudentStatus.inactive:
        return 'Inactive';
      case StudentStatus.discontinued:
        return 'Discontinued';
    }
  }

  static StudentStatus fromString(String? value) {
    if (value == null) return StudentStatus.active;
    return StudentStatus.values
            .where((s) => s.name == value)
            .firstOrNull ??
        StudentStatus.active;
  }
}

class Student {
  final String id;
  final String studentId; // Auto-increment ID like B1001
  final String firstName;
  final String lastName;
  final String grade;
  final String mobileNo;
  final String address;
  final String email;
  final String guardianName;
  final String guardianMobileNo;
  final String qrCode;
  final List<String> classIds;
  final bool isFreeCard;
  final StudentStatus status;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Student({
    required this.id,
    this.studentId = '',
    required this.firstName,
    required this.lastName,
    this.grade = '',
    this.mobileNo = '',
    this.address = '',
    this.email = '',
    this.guardianName = '',
    this.guardianMobileNo = '',
    this.qrCode = '',
    this.classIds = const [],
    this.isFreeCard = false,
    this.status = StudentStatus.active,
    this.isDeleted = false,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'firstName': firstName,
      'lastName': lastName,
      'grade': grade,
      'mobileNo': mobileNo,
      'address': address,
      'email': email,
      'guardianName': guardianName,
      'guardianMobileNo': guardianMobileNo,
      'qrCode': qrCode,
      'classIds': classIds,
      'isFreeCard': isFreeCard,
      'status': status.name,
      'isDeleted': isDeleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      grade: map['grade'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      guardianName: map['guardianName'] ?? '',
      guardianMobileNo: map['guardianMobileNo'] ?? '',
      qrCode: map['qrCode'] ?? '',
      classIds: List<String>.from(map['classIds'] ?? []),
      isFreeCard: map['isFreeCard'] ?? false,
      status: StudentStatus.fromString(map['status']),
      isDeleted: map['isDeleted'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Student copyWith({
    String? id,
    String? studentId,
    String? firstName,
    String? lastName,
    String? grade,
    String? mobileNo,
    String? address,
    String? email,
    String? guardianName,
    String? guardianMobileNo,
    String? qrCode,
    List<String>? classIds,
    bool? isFreeCard,
    StudentStatus? status,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      grade: grade ?? this.grade,
      mobileNo: mobileNo ?? this.mobileNo,
      address: address ?? this.address,
      email: email ?? this.email,
      guardianName: guardianName ?? this.guardianName,
      guardianMobileNo: guardianMobileNo ?? this.guardianMobileNo,
      qrCode: qrCode ?? this.qrCode,
      classIds: classIds ?? this.classIds,
      isFreeCard: isFreeCard ?? this.isFreeCard,
      status: status ?? this.status,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
