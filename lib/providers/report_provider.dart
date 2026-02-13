import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  ReportData? _reportData;
  Map<String, double> _revenueByClass = {};
  Map<String, double> _expensesByType = {};
  bool _isLoading = false;
  String? _error;

  ReportData? get reportData => _reportData;
  Map<String, double> get revenueByClass => _revenueByClass;
  Map<String, double> get expensesByType => _expensesByType;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadMonthlyReport(int month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reportData = await _service.getMonthlyReport(month, year);
      _revenueByClass = await _service.getRevenueByClass(month, year);
      _expensesByType = await _service.getExpensesByType(month, year);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load report: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getAttendanceStats(
    String classId,
    int month,
    int year,
  ) async {
    return await _service.getAttendanceStats(classId, month, year);
  }
}
