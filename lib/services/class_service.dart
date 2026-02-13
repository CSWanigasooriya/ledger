import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.classesCollection);

  Future<ClassModel> createClass(ClassModel classModel) async {
    final id = _uuid.v4();
    final newClass = classModel.copyWith(id: id, createdAt: DateTime.now());
    await _collection.doc(id).set(newClass.toMap());
    return newClass;
  }

  Future<void> updateClass(ClassModel classModel) async {
    await _collection.doc(classModel.id).update(classModel.toMap());
  }

  Future<void> deleteClass(String id) async {
    await _collection.doc(id).delete();
  }

  Future<ClassModel?> getClass(String id) async {
    final doc = await _collection.doc(id).get();
    if (doc.exists) {
      return ClassModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  Stream<List<ClassModel>> getClassesStream() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    final snapshot = await _collection
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<void> enrollStudent(String classId, String studentId) async {
    await _collection.doc(classId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  Future<void> removeStudent(String classId, String studentId) async {
    await _collection.doc(classId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }
}
