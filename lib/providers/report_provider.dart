import 'package:flutter/material.dart';
import '../services/report_service.dart';

class ReportProvider extends ChangeNotifier {
  final ReportService _service = ReportService();

  ReportData? _reportData;
  Map<String, double> _revenueByClass = {};
  Map<String, double> _expensesByType = {};
  bool _isLoading = false;
  String? _error;

  // Date range support
  DateTime? _startDate;
  DateTime? _endDate;

  ReportData? get reportData => _reportData;
  Map<String, double> get revenueByClass => _revenueByClass;
  Map<String, double> get expensesByType => _expensesByType;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

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

  /// Load report by date range.
  Future<void> loadReportByDateRange(DateTime start, DateTime end) async {
    _isLoading = true;
    _error = null;
    _startDate = start;
    _endDate = end;
    notifyListeners();

    try {
      _reportData = await _service.getReportByDateRange(start, end);
      // Revenue by class and expenses by type are already available from monthly
      // For date-range mode, clear them (could be enhanced later)
      _revenueByClass = {};
      _expensesByType = {};
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
