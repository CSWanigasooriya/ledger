import 'dart:async';
import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _service = StudentService();

  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;
  bool _showDeleted = false;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get showDeleted => _showDeleted;

  StreamSubscription? _subscription;

  void init() {
    _subscription?.cancel();
    _subscription = _service.getStudentsStream().listen((students) {
      _students = students;
      notifyListeners();
    });
  }

  /// Toggle to show/hide soft-deleted students.
  void toggleShowDeleted() {
    _showDeleted = !_showDeleted;
    _subscription?.cancel();
    if (_showDeleted) {
      _subscription = _service.getAllStudentsStream().listen((students) {
        _students = students;
        notifyListeners();
      });
    } else {
      _subscription = _service.getStudentsStream().listen((students) {
        _students = students;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Student?> createStudent(Student student) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createStudent(student);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create student: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateStudent(Student student) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateStudent(student);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update student: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStudent(String id) async {
    try {
      await _service.deleteStudent(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete student: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> restoreStudent(String id) async {
    try {
      await _service.restoreStudent(id);
      return true;
    } catch (e) {
      _error = 'Failed to restore student: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> setFreeCard(String id, bool isFreeCard) async {
    try {
      await _service.setFreeCard(id, isFreeCard);
      return true;
    } catch (e) {
      _error = 'Failed to update free card: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Student?> findByStudentId(String studentId) async {
    try {
      return await _service.getStudentByStudentId(studentId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Student>> getStudentsByIds(List<String> ids) async {
    return await _service.getStudentsByIds(ids);
  }

  List<Student> search(String query) {
    if (query.isEmpty) return _students;
    final lowerQuery = query.toLowerCase();
    return _students
        .where(
          (s) =>
              s.firstName.toLowerCase().contains(lowerQuery) ||
              s.lastName.toLowerCase().contains(lowerQuery) ||
              s.email.toLowerCase().contains(lowerQuery) ||
              s.mobileNo.contains(lowerQuery) ||
              s.studentId.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }
}
