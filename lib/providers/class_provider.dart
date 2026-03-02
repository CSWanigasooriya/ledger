import 'dart:async';
import 'package:flutter/material.dart';
import '../models/class_model.dart';
import '../services/class_service.dart';
import '../services/student_service.dart';
import '../services/class_schedule_service.dart';

class ClassProvider extends ChangeNotifier {
  final ClassService _classService = ClassService();
  final StudentService _studentService = StudentService();
  final ClassScheduleService _scheduleService = ClassScheduleService();

  List<ClassModel> _classes = [];
  bool _isLoading = false;
  String? _error;

  List<ClassModel> get classes => _classes;
  bool get isLoading => _isLoading;
  String? get error => _error;

  StreamSubscription? _subscription;

  void init() {
    _subscription?.cancel();
    _subscription = _classService.getClassesStream().listen((classes) {
      _classes = classes;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<ClassModel?> createClass(ClassModel classModel) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _classService.createClass(classModel);
      _isLoading = false;
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to create class: $e';
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  Future<bool> updateClass(ClassModel classModel,
      {String changedBy = ''}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _classService.updateClass(classModel, changedBy: changedBy);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update class: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteClass(String id) async {
    try {
      await _classService.deleteClass(id);
      return true;
    } catch (e) {
      _error = 'Failed to delete class: $e';
      notifyListeners();
      return false;
    }
  }

  ClassModel? getClassById(String id) {
    try {
      return _classes.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<bool> enrollStudent(String classId, String studentId) async {
    try {
      await _classService.enrollStudent(classId, studentId);
      await _studentService.assignToClass(studentId, classId);
      return true;
    } catch (e) {
      _error = 'Failed to enroll student: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeStudent(String classId, String studentId) async {
    try {
      await _classService.removeStudent(classId, studentId);
      await _studentService.removeFromClass(studentId, classId);
      return true;
    } catch (e) {
      _error = 'Failed to remove student: $e';
      notifyListeners();
      return false;
    }
  }

  List<ClassModel> getClassesByTeacher(String teacherId) {
    return _classes.where((c) => c.teacherId == teacherId).toList();
  }

  /// Save monthly schedule for a class.
  Future<bool> saveSchedule(
    String classId,
    int year,
    int month,
    List<ClassSchedule> weeks,
  ) async {
    try {
      await _scheduleService.saveSchedule(classId, year, month, weeks);
      return true;
    } catch (e) {
      _error = 'Failed to save schedule: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get monthly schedule for a class.
  Future<MonthlySchedule?> getSchedule(
    String classId,
    int year,
    int month,
  ) async {
    return await _scheduleService.getSchedule(classId, year, month);
  }

  /// Get classes that have a session on a specific date.
  Future<List<ClassModel>> getClassesForDate(DateTime date) async {
    final classIds = await _scheduleService.getClassesForDate(date);
    return _classes.where((c) => classIds.contains(c.id)).toList();
  }
}
