import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/teacher_payment.dart';

class TeacherPaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.teacherPaymentsCollection);

  Future<TeacherPayment> createPayment(TeacherPayment payment) async {
    final id = _uuid.v4();
    final newPayment = payment.copyWith(id: id);
    await _collection.doc(id).set(newPayment.toMap());
    return newPayment;
  }

  Future<void> deletePayment(String id) async {
    await _collection.doc(id).delete();
  }

  Future<List<TeacherPayment>> getPaymentsByTeacher(String teacherId) async {
    final snapshot = await _collection
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TeacherPayment.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<TeacherPayment>> getPaymentsByMonth(int month, int year) async {
    final snapshot = await _collection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map(
          (doc) => TeacherPayment.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Stream<List<TeacherPayment>> getPaymentsStream() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) =>
                    TeacherPayment.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  Future<List<TeacherPayment>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map(
          (doc) => TeacherPayment.fromMap(doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  /// Get teacher payments grouped by teacher for a month.
  Future<Map<String, List<TeacherPayment>>> getPaymentsByTeacherForMonth(
    int month,
    int year,
  ) async {
    final payments = await getPaymentsByMonth(month, year);
    final grouped = <String, List<TeacherPayment>>{};
    for (final p in payments) {
      grouped.putIfAbsent(p.teacherId, () => []).add(p);
    }
    return grouped;
  }
}
