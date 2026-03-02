import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/class_model.dart';
import 'audit_service.dart';

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();
  final AuditService _auditService = AuditService();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.classesCollection);

  Future<ClassModel> createClass(ClassModel classModel) async {
    final id = _uuid.v4();
    final newClass = classModel.copyWith(id: id, createdAt: DateTime.now());
    await _collection.doc(id).set(newClass.toMap());
    return newClass;
  }

  Future<void> updateClass(ClassModel classModel, {String changedBy = ''}) async {
    // Get the old class data for audit
    final oldDoc = await _collection.doc(classModel.id).get();
    if (oldDoc.exists) {
      final oldData = oldDoc.data() as Map<String, dynamic>;
      final newData = classModel.toMap();

      // Track specific field changes for audit
      final fieldsToAudit = [
        'teacherId',
        'teacherCommissionRate',
        'classFees',
        'className',
      ];
      for (final field in fieldsToAudit) {
        if (oldData[field]?.toString() != newData[field]?.toString()) {
          await _auditService.logChange(
            entityType: 'class',
            entityId: classModel.id,
            field: field,
            oldValue: oldData[field],
            newValue: newData[field],
            changedBy: changedBy,
          );
        }
      }
    }

    await _collection.doc(classModel.id).update(
      classModel.copyWith(updatedAt: DateTime.now()).toMap(),
    );
  }

  /// Soft delete a class.
  Future<void> deleteClass(String id) async {
    await _collection.doc(id).update({
      'isDeleted': true,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
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
              .where((c) => !c.isDeleted)
              .toList(),
        );
  }

  Future<List<ClassModel>> getClassesByTeacher(String teacherId) async {
    final snapshot = await _collection
        .where('teacherId', isEqualTo: teacherId)
        .get();
    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>))
        .where((c) => !c.isDeleted)
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
