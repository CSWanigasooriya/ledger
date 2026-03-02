import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/teacher.dart';

class TeacherService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.teachersCollection);

  Future<Teacher> createTeacher(Teacher teacher) async {
    final id = _uuid.v4();
    final newTeacher = teacher.copyWith(id: id, createdAt: DateTime.now());
    await _collection.doc(id).set(newTeacher.toMap());
    return newTeacher;
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _collection.doc(teacher.id).update(
      teacher.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  /// Soft delete — marks teacher as deleted/inactive.
  Future<void> deleteTeacher(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'status': TeacherStatus.inactive.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Hard delete for when truly needed.
  Future<void> permanentDeleteTeacher(String id) async {
    await _collection.doc(id).delete();
  }

  Future<Teacher?> getTeacher(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return Teacher.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<Teacher>> getTeachersStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Teacher.fromMap(doc.data() as Map<String, dynamic>))
              .where((t) => !t.isDeleted)
              .toList(),
        );
  }

  /// Stream including soft-deleted teachers (for admin views).
  Stream<List<Teacher>> getAllTeachersStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Teacher.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<List<Teacher>> searchTeachers(String query) async {
    final snapshot = await _collection.get();
    final allTeachers = snapshot.docs
        .map((doc) => Teacher.fromMap(doc.data() as Map<String, dynamic>))
        .where((t) => !t.isDeleted)
        .toList();
    final lowerQuery = query.toLowerCase();
    return allTeachers
        .where(
          (t) =>
              t.name.toLowerCase().contains(lowerQuery) ||
              t.email.toLowerCase().contains(lowerQuery) ||
              t.contactNo.contains(lowerQuery),
        )
        .toList();
  }

  /// Restore a soft-deleted teacher.
  Future<void> restoreTeacher(String id) async {
    await _collection.doc(id).update({
      'isDeleted': false,
      'status': TeacherStatus.active.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }
}
