import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/class_model.dart';

class ClassScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.classSchedulesCollection);

  /// Document ID is "{classId}_{year}_{month}"
  String _docId(String classId, int year, int month) =>
      '${classId}_${year}_$month';

  /// Save/update a monthly schedule for a class.
  Future<void> saveSchedule(
    String classId,
    int year,
    int month,
    List<ClassSchedule> weeks,
  ) async {
    final docId = _docId(classId, year, month);
    final schedule = MonthlySchedule(month: month, year: year, weeks: weeks);
    await _collection.doc(docId).set({
      'classId': classId,
      ...schedule.toMap(),
    });
  }

  /// Get the schedule for a specific class, month, and year.
  Future<MonthlySchedule?> getSchedule(
    String classId,
    int year,
    int month,
  ) async {
    final docId = _docId(classId, year, month);
    final doc = await _collection.doc(docId).get();
    if (doc.exists) {
      return MonthlySchedule.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  /// Get all classes scheduled for a specific date.
  Future<List<String>> getClassesForDate(DateTime date) async {
    final month = date.month;
    final year = date.year;
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    final classIds = <String>[];
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final classId = data['classId'] as String?;
      final weeks = (data['weeks'] as List<dynamic>?)
              ?.map((w) => ClassSchedule.fromMap(Map<String, dynamic>.from(w)))
              .toList() ??
          [];
      // Check if any week's date falls on this day
      for (final week in weeks) {
        final scheduleDate = DateTime(week.date.year, week.date.month, week.date.day);
        if (!scheduleDate.isBefore(dayStart) && scheduleDate.isBefore(dayEnd)) {
          if (classId != null) classIds.add(classId);
          break;
        }
      }
    }
    return classIds;
  }

  /// Get the week number for a class on a specific date.
  Future<int?> getWeekNumberForDate(String classId, DateTime date) async {
    final schedule = await getSchedule(classId, date.year, date.month);
    if (schedule == null) return null;

    final dayStart = DateTime(date.year, date.month, date.day);
    for (final week in schedule.weeks) {
      final scheduleDate = DateTime(week.date.year, week.date.month, week.date.day);
      if (scheduleDate == dayStart) {
        return week.weekNumber;
      }
    }
    return null;
  }

  /// Get all schedules for a class.
  Stream<List<MonthlySchedule>> getSchedulesStream(String classId) {
    return _collection
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) =>
                  MonthlySchedule.fromMap(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }
}
