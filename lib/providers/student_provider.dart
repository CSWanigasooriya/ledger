import 'package:flutter/material.dart';
import '../models/student.dart';
import '../services/student_service.dart';

class StudentProvider extends ChangeNotifier {
  final StudentService _service = StudentService();

  List<Student> _students = [];
  bool _isLoading = false;
  String? _error;

  List<Student> get students => _students;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void init() {
    _service.getStudentsStream().listen((students) {
      _students = students;
      notifyListeners();
    });
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
              s.mobileNo.contains(lowerQuery),
        )
        .toList();
  }
}
