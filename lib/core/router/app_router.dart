import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/app_shell.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/students/student_list_screen.dart';
import '../../screens/students/student_form_screen.dart';
import '../../screens/students/student_detail_screen.dart';
import '../../screens/students/qr_print_screen.dart';
import '../../screens/teachers/teacher_list_screen.dart';
import '../../screens/teachers/teacher_form_screen.dart';
import '../../screens/teachers/teacher_detail_screen.dart';
import '../../screens/classes/class_list_screen.dart';
import '../../screens/classes/class_form_screen.dart';
import '../../screens/classes/class_detail_screen.dart';
import '../../screens/attendance/attendance_screen.dart';
import '../../screens/payments/class_payment_screen.dart';
import '../../screens/payments/teacher_payment_screen.dart';
import '../../screens/expenses/expense_list_screen.dart';
import '../../screens/expenses/expense_form_screen.dart';
import '../../screens/reports/report_screen.dart';

class AppRouter {
  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isLoginRoute = state.matchedLocation == '/login';

        if (!isAuthenticated && !isLoginRoute) return '/login';
        if (isAuthenticated && isLoginRoute) return '/dashboard';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              AppShell(navigationShell: navigationShell),
          branches: [
            // Dashboard
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/dashboard',
                  builder: (context, state) => const DashboardScreen(),
                ),
              ],
            ),
            // Students
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/students',
                  builder: (context, state) => const StudentListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const StudentFormScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => StudentDetailScreen(
                        studentId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => StudentFormScreen(
                            studentId: state.pathParameters['id'],
                          ),
                        ),
                        GoRoute(
                          path: 'qr',
                          builder: (context, state) => QrPrintScreen(
                            studentId: state.pathParameters['id']!,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Teachers
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/teachers',
                  builder: (context, state) => const TeacherListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const TeacherFormScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => TeacherDetailScreen(
                        teacherId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => TeacherFormScreen(
                            teacherId: state.pathParameters['id'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Classes
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/classes',
                  builder: (context, state) => const ClassListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const ClassFormScreen(),
                    ),
                    GoRoute(
                      path: ':id',
                      builder: (context, state) => ClassDetailScreen(
                        classId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'edit',
                          builder: (context, state) => ClassFormScreen(
                            classId: state.pathParameters['id'],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // Attendance
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/attendance',
                  builder: (context, state) => const AttendanceScreen(),
                ),
              ],
            ),
            // Payments
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/payments',
                  builder: (context, state) => const ClassPaymentScreen(),
                  routes: [
                    GoRoute(
                      path: 'teacher',
                      builder: (context, state) => const TeacherPaymentScreen(),
                    ),
                  ],
                ),
              ],
            ),
            // Expenses
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/expenses',
                  builder: (context, state) => const ExpenseListScreen(),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const ExpenseFormScreen(),
                    ),
                  ],
                ),
              ],
            ),
            // Reports
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/reports',
                  builder: (context, state) => const ReportScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
