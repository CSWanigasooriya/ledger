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
}
