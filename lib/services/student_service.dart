import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/student.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.studentsCollection);

  DocumentReference get _counterDoc => _firestore
      .collection(AppConstants.countersCollection)
      .doc(AppConstants.studentCounterDoc);

  /// Generate the next auto-increment student ID.
  /// Uses a Firestore transaction to atomically increment the counter.
  /// Format: {GradePrefix}{SequentialNumber} e.g., B1001, C1002
  /// The sequential number is global across all grades.
  Future<String> _generateStudentId(String grade) async {
    final prefix = GradeConfig.prefixForGrade(grade);

    final nextNumber = await _firestore.runTransaction<int>((transaction) async {
      final snapshot = await transaction.get(_counterDoc);
      int currentCounter;
      if (!snapshot.exists) {
        currentCounter = AppConstants.studentIdStart;
        transaction.set(_counterDoc, {'currentId': currentCounter});
      } else {
        currentCounter = (snapshot.data()
                as Map<String, dynamic>)['currentId'] ??
            AppConstants.studentIdStart;
        currentCounter++;
        transaction.update(_counterDoc, {'currentId': currentCounter});
      }
      return currentCounter;
    });

    return '$prefix$nextNumber';
  }

  Future<Student> createStudent(Student student) async {
    final id = _uuid.v4();
    final studentId = await _generateStudentId(student.grade);
    final qrCode = studentId; // QR code is the student ID itself
    final newStudent = student.copyWith(
      id: id,
      studentId: studentId,
      qrCode: qrCode,
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(newStudent.toMap());
    return newStudent;
  }

  Future<void> updateStudent(Student student) async {
    await _collection.doc(student.id).update(
      student.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  /// Soft delete — marks student as deleted instead of removing the document.
  Future<void> deleteStudent(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'status': StudentStatus.discontinued.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Hard delete for when truly needed.
  Future<void> permanentDeleteStudent(String id) async {
    await _collection.doc(id).delete();
  }

  Future<Student?> getStudent(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Student.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Find a student by their auto-increment student ID (e.g., B1001).
  Future<Student?> getStudentByStudentId(String studentId) async {
    final snapshot = await _collection
        .where('studentId', isEqualTo: studentId)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return Student.fromMap(
          snapshot.docs.first.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<Student>> getStudentsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
              .where((s) => !s.isDeleted)
              .toList(),
        );
  }

  /// Stream including soft-deleted students (for admin views).
  Stream<List<Student>> getAllStudentsStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<List<Student>> getStudentsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    // Firestore whereIn supports up to 30 items
    final List<Student> students = [];
    for (var i = 0; i < ids.length; i += 30) {
      final batch = ids.sublist(i, i + 30 > ids.length ? ids.length : i + 30);
      final snapshot = await _collection.where('id', whereIn: batch).get();
      students.addAll(
        snapshot.docs
            .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
            .toList(),
      );
    }
    return students;
  }

  Future<List<Student>> searchStudents(String query) async {
    final snapshot = await _collection.get();
    final allStudents = snapshot.docs
        .map((doc) => Student.fromMap(doc.data() as Map<String, dynamic>))
        .where((s) => !s.isDeleted)
        .toList();
    final lowerQuery = query.toLowerCase();
    return allStudents
        .where(
          (s) =>
              s.firstName.toLowerCase().contains(lowerQuery) ||
              s.lastName.toLowerCase().contains(lowerQuery) ||
              s.email.toLowerCase().contains(lowerQuery) ||
              s.mobileNo.contains(lowerQuery) ||
              s.studentId.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Future<void> assignToClass(String studentId, String classId) async {
    await _collection.doc(studentId).update({
      'classIds': FieldValue.arrayUnion([classId]),
    });
  }

  Future<void> removeFromClass(String studentId, String classId) async {
    await _collection.doc(studentId).update({
      'classIds': FieldValue.arrayRemove([classId]),
    });
  }

  /// Restore a soft-deleted student.
  Future<void> restoreStudent(String id) async {
    await _collection.doc(id).update({
      'isDeleted': false,
      'status': StudentStatus.active.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Toggle the free card status for a student.
  Future<void> setFreeCard(String studentId, bool isFreeCard) async {
    await _collection.doc(studentId).update({
      'isFreeCard': isFreeCard,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
