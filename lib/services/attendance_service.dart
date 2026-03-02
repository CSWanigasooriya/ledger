import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../models/attendance.dart';

class AttendanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  CollectionReference get _collection =>
      _firestore.collection(AppConstants.attendanceCollection);

  Future<Attendance> markAttendance(Attendance attendance) async {
    final id = _uuid.v4();
    final record = attendance.copyWith(id: id);
    await _collection.doc(id).set(record.toMap());
    return record;
  }

  Future<void> batchMarkAttendance(List<Attendance> records) async {
    final batch = _firestore.batch();
    for (final record in records) {
      final id = record.id.isEmpty ? _uuid.v4() : record.id;
      final doc = _collection.doc(id);
      batch.set(doc, record.copyWith(id: id).toMap());
    }
    await batch.commit();
  }

  Future<List<Attendance>> getAttendanceByClassAndDate(
    String classId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    return snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> getAttendanceByClassAndMonth(
    String classId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _collection
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  /// Get attendance for a specific class, month, and week number.
  Future<List<Attendance>> getAttendanceByClassMonthWeek(
    String classId,
    int month,
    int year,
    int weekNumber,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _collection
        .where('classId', isEqualTo: classId)
        .where('weekNumber', isEqualTo: weekNumber)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Future<List<Attendance>> getAttendanceByStudent(
    String studentId,
    int month,
    int year,
  ) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 1);

    final snapshot = await _collection
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    return snapshot.docs
        .map((doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
  }

  Stream<List<Attendance>> getAttendanceStream(String classId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _collection
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => Attendance.fromMap(doc.data() as Map<String, dynamic>),
              )
              .toList(),
        );
  }

  /// Check if a specific student already has attendance for a class on a date.
  Future<bool> hasAttendance(
    String studentId,
    String classId,
    DateTime date,
  ) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _collection
        .where('studentId', isEqualTo: studentId)
        .where('classId', isEqualTo: classId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> deleteAttendanceForClassAndDate(
    String classId,
    DateTime date,
  ) async {
    final records = await getAttendanceByClassAndDate(classId, date);
    final batch = _firestore.batch();
    for (final record in records) {
      batch.delete(_collection.doc(record.id));
    }
    await batch.commit();
  }

  /// Get attendance count by student for a class across a month (for reports).
  Future<Map<String, int>> getAttendanceCountByStudent(
    String classId,
    int month,
    int year,
  ) async {
    final records = await getAttendanceByClassAndMonth(classId, month, year);
    final counts = <String, int>{};
    for (final r in records) {
      if (r.isPresent) {
        counts[r.studentId] = (counts[r.studentId] ?? 0) + 1;
      }
    }
    return counts;
  }
}
