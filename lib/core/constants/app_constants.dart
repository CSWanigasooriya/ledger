class AppConstants {
  AppConstants._();

  static const String appName = 'Ledger';
  static const String appTagline = 'Education Management Platform';

  // Firestore Collections
  static const String studentsCollection = 'students';
  static const String teachersCollection = 'teachers';
  static const String classesCollection = 'classes';
  static const String attendanceCollection = 'attendance';
  static const String paymentsCollection = 'payments';
  static const String expensesCollection = 'expenses';
  static const String teacherPaymentsCollection = 'teacher_payments';
  static const String usersCollection = 'users';
  static const String countersCollection = 'counters';
  static const String classSchedulesCollection = 'class_schedules';
  static const String auditLogsCollection = 'audit_logs';

  // Counter document IDs
  static const String studentCounterDoc = 'student_id_counter';

  // Expense Types
  static const List<String> expenseTypes = [
    'Staff',
    'Cleaning',
    'Food',
    'Utilities',
    'Supplies',
    'Maintenance',
    'Other',
  ];

  // Student ID starts at 1001
  static const int studentIdStart = 1001;
}
