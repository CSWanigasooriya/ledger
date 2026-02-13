import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/payment.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.paymentsCollection);

  Future<Payment> recordPayment(Payment payment) async {
    final id = _uuid.v4();
    final record = payment.copyWith(id: id);
    await _collection.doc(id).set(record.toMap());
    return record;
  }

  Future<List<Payment>> getPaymentsByClassAndMonth(
    String classId,
    int month,
    int year,
  ) async {
    final snapshot = await _collection
        .where('classId', isEqualTo: classId)
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> getPaymentsByStudent(String studentId) async {
    final snapshot = await _collection
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Payment>> getPaymentsByMonth(int month, int year) async {
    final snapshot = await _collection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<double> getTotalPaymentsForClass(
    String classId,
    int month,
    int year,
  ) async {
    final payments = await getPaymentsByClassAndMonth(classId, month, year);
    return payments.fold<double>(0.0, (total, p) => total + p.amount);
  }

  Stream<List<Payment>> getPaymentsStream() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<void> deletePayment(String id) async {
    await _collection.doc(id).delete();
  }
}
