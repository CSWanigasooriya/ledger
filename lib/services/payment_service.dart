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

  /// Mark payment as institute-paid (teacher's share remitted to teacher).
  Future<void> markInstitutePaid(String paymentId) async {
    await _collection.doc(paymentId).update({
      'institutePaid': true,
      'institutePaidDate': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Get all unpaid student payments for a class/month (students who haven't paid yet).
  /// This returns students enrolled in a class minus those with a Payment record.
  Future<List<String>> getUnpaidStudentIds(
    String classId,
    int month,
    int year,
    List<String> enrolledStudentIds,
  ) async {
    final payments = await getPaymentsByClassAndMonth(classId, month, year);
    final paidStudentIds = payments
        .where((p) => !p.isFreeCard)
        .map((p) => p.studentId)
        .toSet();
    // Free-card students are considered "paid"
    final freeCardStudentIds = payments
        .where((p) => p.isFreeCard)
        .map((p) => p.studentId)
        .toSet();
    return enrolledStudentIds
        .where(
          (id) => !paidStudentIds.contains(id) && !freeCardStudentIds.contains(id),
        )
        .toList();
  }

  /// Get payments where institute hasn't paid teacher yet.
  Future<List<Payment>> getUnpaidToTeacher(int month, int year) async {
    final snapshot = await _collection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .where('institutePaid', isEqualTo: false)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get payments by date range (for reports).
  Future<List<Payment>> getPaymentsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final snapshot = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Record a free-card payment entry (amount = 0, marked as free card).
  Future<Payment> recordFreeCardPayment({
    required String studentId,
    required String classId,
    required int month,
    required int year,
  }) async {
    final payment = Payment(
      id: '',
      studentId: studentId,
      classId: classId,
      amount: 0,
      date: DateTime.now(),
      month: month,
      year: year,
      isFreeCard: true,
      institutePaid: true,
    );
    return recordPayment(payment);
  }
}
