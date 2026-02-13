import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.expensesCollection);

  Future<Expense> createExpense(Expense expense) async {
    final id = _uuid.v4();
    final newExpense = expense.copyWith(id: id);
    await _collection.doc(id).set(newExpense.toMap());
    return newExpense;
  }

  Future<void> updateExpense(Expense expense) async {
    await _collection.doc(expense.id).update(expense.toMap());
  }

  Future<void> deleteExpense(String id) async {
    await _collection.doc(id).delete();
  }

  Stream<List<Expense>> getExpensesStream() {
    return _collection
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  Future<List<Expense>> getExpensesByMonth(int month, int year) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _collection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return snapshot.docs
        .map((doc) => Expense.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<double> getTotalExpensesForMonth(int month, int year) async {
    final expenses = await getExpensesByMonth(month, year);
    return expenses.fold(0.0, (sum, e) => sum + e.amount);
  }
}
