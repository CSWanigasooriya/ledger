import 'dart:async';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider extends ChangeNotifier {
  final ExpenseService _service = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _subscription;

  void init() {
    _subscription?.cancel();
    _subscription = _service.getExpensesStream().listen((expenses) {
      _expenses = expenses;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Expense?> createExpense(Expense expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createExpense(expense);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create expense: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteExpense(String id) async {
    try {
      await _service.deleteExpense(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete expense: $e';
      notifyListeners();
      return false;
    }
  }
}
