import 'dart:async';
import 'package:flutter/material.dart';
import '../models/teacher.dart';
import '../services/teacher_service.dart';

class TeacherProvider extends ChangeNotifier {
  final TeacherService _service = TeacherService();

  List<Teacher> _teachers = [];
  bool _isLoading = false;
  String? _error;

  List<Teacher> get teachers => _teachers;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _subscription;

  void init() {
    _subscription?.cancel();
    _subscription = _service.getTeachersStream().listen((teachers) {
      _teachers = teachers;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Teacher?> createTeacher(Teacher teacher) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.createTeacher(teacher);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create teacher: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateTeacher(Teacher teacher) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateTeacher(teacher);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update teacher: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTeacher(String id) async {
    try {
      await _service.deleteTeacher(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete teacher: $e';
      notifyListeners();
      return false;
    }
  }

  Teacher? getTeacherById(String id) {
    try {
      return _teachers.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Teacher> search(String query) {
    if (query.isEmpty) return _teachers;
    final lowerQuery = query.toLowerCase();
    return _teachers
        .where(
          (t) =>
              t.name.toLowerCase().contains(lowerQuery) ||
              t.email.toLowerCase().contains(lowerQuery) ||
              t.contactNo.contains(lowerQuery),
        )
        .toList();
  }
}
