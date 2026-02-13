import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/student.dart';

class StudentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.studentsCollection);

  Future<Student> createStudent(Student student) async {
    final id = _uuid.v4();
    final newStudent = student.copyWith(
      id: id,
      qrCode: 'STU-$id',
      createdAt: DateTime.now(),
    );
    await _collection.doc(id).set(newStudent.toMap());
    return newStudent;
  }

  Future<void> updateStudent(Student student) async {
    await _collection.doc(student.id).update(student.toMap());
  }

  Future<void> deleteStudent(String id) async {
    await _collection.doc(id).delete();
  }

  Future<Student?> getStudent(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Student.fromMap(doc.data() as Map<String, dynamic>);
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
        .toList();
    final lowerQuery = query.toLowerCase();
    return allStudents
        .where(
          (s) =>
              s.firstName.toLowerCase().contains(lowerQuery) ||
              s.lastName.toLowerCase().contains(lowerQuery) ||
              s.email.toLowerCase().contains(lowerQuery) ||
              s.mobileNo.contains(lowerQuery),
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
}
