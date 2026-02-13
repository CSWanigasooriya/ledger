import 'package:cloud_firestore/cloud_firestore.dart';

class BankDetails {
  final String bankName;
  final String accountNo;
  final String branch;

  BankDetails({this.bankName = '', this.accountNo = '', this.branch = ''});

  Map<String, dynamic> toMap() {
    return {'bankName': bankName, 'accountNo': accountNo, 'branch': branch};
  }

  factory BankDetails.fromMap(Map<String, dynamic> map) {
    return BankDetails(
      bankName: map['bankName'] ?? '',
      accountNo: map['accountNo'] ?? '',
      branch: map['branch'] ?? '',
    );
  }

  BankDetails copyWith({String? bankName, String? accountNo, String? branch}) {
    return BankDetails(
      bankName: bankName ?? this.bankName,
      accountNo: accountNo ?? this.accountNo,
      branch: branch ?? this.branch,
    );
  }
}

class Teacher {
  final String id;
  final String name;
  final String email;
  final String contactNo;
  final String address;
  final BankDetails bankDetails;
  final String nic;
  final DateTime createdAt;

  Teacher({
    required this.id,
    required this.name,
    this.email = '',
    this.contactNo = '',
    this.address = '',
    BankDetails? bankDetails,
    this.nic = '',
    DateTime? createdAt,
  }) : bankDetails = bankDetails ?? BankDetails(),
       createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'contactNo': contactNo,
      'address': address,
      'bankDetails': bankDetails.toMap(),
      'nic': nic,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      contactNo: map['contactNo'] ?? '',
      address: map['address'] ?? '',
      bankDetails: map['bankDetails'] != null
          ? BankDetails.fromMap(Map<String, dynamic>.from(map['bankDetails']))
          : BankDetails(),
      nic: map['nic'] ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? email,
    String? contactNo,
    String? address,
    BankDetails? bankDetails,
    String? nic,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      contactNo: contactNo ?? this.contactNo,
      address: address ?? this.address,
      bankDetails: bankDetails ?? this.bankDetails,
      nic: nic ?? this.nic,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
