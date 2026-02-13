import '../services/attendance_service.dart';
import '../services/payment_service.dart';
import '../services/expense_service.dart';
import '../services/teacher_payment_service.dart';

class ReportData {
  final double totalRevenue;
  final double totalExpenses;
  final double totalTeacherPayments;
  final double netIncome;
  final int totalAttendanceRecords;
  final int presentCount;
  final double attendanceRate;

  ReportData({
    required this.totalRevenue,
    required this.totalExpenses,
    required this.totalTeacherPayments,
    required this.netIncome,
    required this.totalAttendanceRecords,
    required this.presentCount,
    required this.attendanceRate,
  });
}

class ReportService {
  final PaymentService _paymentService = PaymentService();
  final ExpenseService _expenseService = ExpenseService();
  final TeacherPaymentService _teacherPaymentService = TeacherPaymentService();
  final AttendanceService _attendanceService = AttendanceService();

  Future<ReportData> getMonthlyReport(int month, int year) async {
    final payments = await _paymentService.getPaymentsByMonth(month, year);
    final expenses = await _expenseService.getExpensesByMonth(month, year);
    final teacherPayments = await _teacherPaymentService.getPaymentsByMonth(
      month,
      year,
    );

    final totalRevenue = payments.fold(0.0, (sum, p) => sum + p.amount);
    final totalExpenses = expenses.fold(0.0, (sum, e) => sum + e.amount);
    final totalTeacherPay = teacherPayments.fold(
      0.0,
      (sum, tp) => sum + tp.amount,
    );
    final netIncome = totalRevenue - totalExpenses - totalTeacherPay;

    return ReportData(
      totalRevenue: totalRevenue,
      totalExpenses: totalExpenses,
      totalTeacherPayments: totalTeacherPay,
      netIncome: netIncome,
      totalAttendanceRecords: 0,
      presentCount: 0,
      attendanceRate: 0,
    );
  }

  Future<Map<String, double>> getRevenueByClass(int month, int year) async {
    final payments = await _paymentService.getPaymentsByMonth(month, year);
    final Map<String, double> revenueByClass = {};
    for (final p in payments) {
      revenueByClass[p.classId] = (revenueByClass[p.classId] ?? 0) + p.amount;
    }
    return revenueByClass;
  }

  Future<Map<String, double>> getExpensesByType(int month, int year) async {
    final expenses = await _expenseService.getExpensesByMonth(month, year);
    final Map<String, double> expensesByType = {};
    for (final e in expenses) {
      expensesByType[e.type] = (expensesByType[e.type] ?? 0) + e.amount;
    }
    return expensesByType;
  }

  Future<Map<String, dynamic>> getAttendanceStats(
    String classId,
    int month,
    int year,
  ) async {
    final records = await _attendanceService.getAttendanceByClassAndMonth(
      classId,
      month,
      year,
    );
    final total = records.length;
    final present = records.where((r) => r.isPresent).length;
    final rate = total > 0 ? (present / total) * 100 : 0.0;

    // Group by date to count class days
    final dates = records
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet();

    return {
      'totalRecords': total,
      'presentCount': present,
      'absentCount': total - present,
      'attendanceRate': rate,
      'classDays': dates.length,
    };
  }
}
