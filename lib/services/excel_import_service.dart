import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import '../models/student.dart';
import '../models/teacher.dart';
import '../models/class_model.dart';
import '../services/student_service.dart';
import '../services/teacher_service.dart';
import '../services/class_service.dart';

/// Supported import types.
enum ImportType { students, teachers, classes }

/// Result of a single import batch.
class ImportResult {
  final int total;
  final int succeeded;
  final int failed;
  final List<String> errors;

  ImportResult({
    required this.total,
    required this.succeeded,
    required this.failed,
    required this.errors,
  });
}

class ExcelImportService {
  final StudentService _studentService = StudentService();
  final TeacherService _teacherService = TeacherService();
  final ClassService _classService = ClassService();

  /// Lets user pick an Excel file and returns parsed bytes, or null if cancelled.
  Future<List<int>?> pickExcelFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;
    final file = result.files.first;
    if (file.bytes != null) return file.bytes!.toList();
    if (file.path != null) return File(file.path!).readAsBytesSync().toList();
    return null;
  }

  /// Returns header row from the first sheet of the given Excel bytes.
  List<String> getHeaders(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.rows.isEmpty) return [];
    return sheet.rows.first
        .map((cell) => cell?.value?.toString().trim() ?? '')
        .toList();
  }

  /// Returns all data rows (excluding header) from the first sheet.
  List<List<String>> getDataRows(List<int> bytes) {
    final excel = Excel.decodeBytes(bytes);
    final sheet = excel.tables[excel.tables.keys.first]!;
    if (sheet.rows.length <= 1) return [];
    return sheet.rows.skip(1).map((row) {
      return row.map((cell) => cell?.value?.toString().trim() ?? '').toList();
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Students import
  // ---------------------------------------------------------------------------

  /// Expected columns (case-insensitive): firstName, lastName, grade, mobileNo,
  /// address, email, guardianName, guardianMobileNo, isFreeCard
  Future<ImportResult> importStudents(
    List<int> bytes,
    Map<String, int> columnMapping,
  ) async {
    final rows = getDataRows(bytes);
    int succeeded = 0;
    int failed = 0;
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        String val(String key) {
          final idx = columnMapping[key];
          if (idx == null || idx >= row.length) return '';
          return row[idx];
        }

        final firstName = val('firstName');
        final lastName = val('lastName');
        if (firstName.isEmpty && lastName.isEmpty) {
          errors.add('Row ${i + 2}: Missing name — skipped');
          failed++;
          continue;
        }

        final student = Student(
          id: '', // will be generated
          firstName: firstName,
          lastName: lastName,
          grade: val('grade'),
          mobileNo: val('mobileNo'),
          address: val('address'),
          email: val('email'),
          guardianName: val('guardianName'),
          guardianMobileNo: val('guardianMobileNo'),
          isFreeCard:
              val('isFreeCard').toLowerCase() == 'true' ||
              val('isFreeCard') == '1' ||
              val('isFreeCard').toLowerCase() == 'yes',
        );
        await _studentService.createStudent(student);
        succeeded++;
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
        failed++;
      }
    }

    return ImportResult(
      total: rows.length,
      succeeded: succeeded,
      failed: failed,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Teachers import
  // ---------------------------------------------------------------------------

  /// Expected columns: name, email, contactNo, address, nic,
  /// bankName, accountNo, branch
  Future<ImportResult> importTeachers(
    List<int> bytes,
    Map<String, int> columnMapping,
  ) async {
    final rows = getDataRows(bytes);
    int succeeded = 0;
    int failed = 0;
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        String val(String key) {
          final idx = columnMapping[key];
          if (idx == null || idx >= row.length) return '';
          return row[idx];
        }

        final name = val('name');
        if (name.isEmpty) {
          errors.add('Row ${i + 2}: Missing name — skipped');
          failed++;
          continue;
        }

        final teacher = Teacher(
          id: '',
          name: name,
          email: val('email'),
          contactNo: val('contactNo'),
          address: val('address'),
          nic: val('nic'),
          bankDetails: BankDetails(
            bankName: val('bankName'),
            accountNo: val('accountNo'),
            branch: val('branch'),
          ),
        );
        await _teacherService.createTeacher(teacher);
        succeeded++;
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
        failed++;
      }
    }

    return ImportResult(
      total: rows.length,
      succeeded: succeeded,
      failed: failed,
      errors: errors,
    );
  }

  // ---------------------------------------------------------------------------
  // Classes import
  // ---------------------------------------------------------------------------

  /// Expected columns: className, classFees, teacherCommissionRate, numberOfWeeks
  Future<ImportResult> importClasses(
    List<int> bytes,
    Map<String, int> columnMapping,
  ) async {
    final rows = getDataRows(bytes);
    int succeeded = 0;
    int failed = 0;
    final errors = <String>[];

    for (var i = 0; i < rows.length; i++) {
      try {
        final row = rows[i];
        String val(String key) {
          final idx = columnMapping[key];
          if (idx == null || idx >= row.length) return '';
          return row[idx];
        }

        final className = val('className');
        if (className.isEmpty) {
          errors.add('Row ${i + 2}: Missing className — skipped');
          failed++;
          continue;
        }

        final cls = ClassModel(
          id: '',
          className: className,
          classFees: double.tryParse(val('classFees')) ?? 0.0,
          teacherCommissionRate:
              double.tryParse(val('teacherCommissionRate')) ?? 0.0,
          numberOfWeeks: int.tryParse(val('numberOfWeeks')) ?? 4,
        );
        await _classService.createClass(cls);
        succeeded++;
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
        failed++;
      }
    }

    return ImportResult(
      total: rows.length,
      succeeded: succeeded,
      failed: failed,
      errors: errors,
    );
  }
}
