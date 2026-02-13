import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String mobileNo;
  final String address;
  final String email;
  final String guardianName;
  final String guardianMobileNo;
  final String qrCode;
  final List<String> classIds;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.mobileNo = '',
    this.address = '',
    this.email = '',
    this.guardianName = '',
    this.guardianMobileNo = '',
    this.qrCode = '',
    this.classIds = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      'mobileNo': mobileNo,
      'address': address,
      'email': email,
      'guardianName': guardianName,
      'guardianMobileNo': guardianMobileNo,
      'qrCode': qrCode,
      'classIds': classIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      mobileNo: map['mobileNo'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      guardianName: map['guardianName'] ?? '',
      guardianMobileNo: map['guardianMobileNo'] ?? '',
      qrCode: map['qrCode'] ?? '',
      classIds: List<String>.from(map['classIds'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? mobileNo,
    String? address,
    String? email,
    String? guardianName,
    String? guardianMobileNo,
    String? qrCode,
    List<String>? classIds,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      mobileNo: mobileNo ?? this.mobileNo,
      address: address ?? this.address,
      email: email ?? this.email,
      guardianName: guardianName ?? this.guardianName,
      guardianMobileNo: guardianMobileNo ?? this.guardianMobileNo,
      qrCode: qrCode ?? this.qrCode,
      classIds: classIds ?? this.classIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
