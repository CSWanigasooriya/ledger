import 'package:flutter/material.dart';
import '../models/attendance.dart';
import '../services/attendance_service.dart';

class AttendanceProvider extends ChangeNotifier {
  final AttendanceService _service = AttendanceService();

  List<Attendance> _records = [];
  bool _isLoading = false;
  String? _error;

  List<Attendance> get records => _records;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAttendance(String classId, DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _service.getAttendanceByClassAndDate(classId, date);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load attendance: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> saveAttendance(List<Attendance> records) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.batchMarkAttendance(records);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to save attendance: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark single student attendance (for manual mark by reg no / name).
  Future<Attendance?> markSingleAttendance(Attendance attendance) async {
    try {
      // Check for duplicate
      final exists = await _service.hasAttendance(
        attendance.studentId,
        attendance.classId,
        attendance.date,
      );
      if (exists) {
        _error = 'Attendance already marked for this student today';
        notifyListeners();
        return null;
      }
      final result = await _service.markAttendance(attendance);
      _records.add(result);
      notifyListeners();
      return result;
    } catch (e) {
      _error = 'Failed to mark attendance: $e';
      notifyListeners();
      return null;
    }
  }

  Future<List<Attendance>> getMonthlyAttendance(
    String classId,
    int month,
    int year,
  ) async {
    return await _service.getAttendanceByClassAndMonth(classId, month, year);
  }

  Future<List<Attendance>> getWeeklyAttendance(
    String classId,
    int month,
    int year,
    int weekNumber,
  ) async {
    return await _service.getAttendanceByClassMonthWeek(
      classId,
      month,
      year,
      weekNumber,
    );
  }

  Future<void> deleteAndReplace(
    String classId,
    DateTime date,
    List<Attendance> records,
  ) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _service.deleteAttendanceForClassAndDate(classId, date);
      await _service.batchMarkAttendance(records);
      _records = records;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to update attendance: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
