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
import '../../screens/attendance/attendance_scanner_screen.dart';
import '../../screens/payments/class_payment_screen.dart';
import '../../screens/payments/teacher_payment_screen.dart';
import '../../screens/expenses/expense_list_screen.dart';
import '../../screens/expenses/expense_form_screen.dart';
import '../../screens/reports/report_screen.dart';
import '../../screens/settings/user_management_screen.dart';

class AppRouter {
  // Routes accessible by role
  static const _markerAllowedPrefixes = ['/attendance', '/payments'];
  static const _teacherAllowedPrefixes = [
    '/classes',
    '/attendance',
    '/payments'
  ];

  static GoRouter router(AuthProvider authProvider) {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: authProvider,
      redirect: (context, state) {
        // While auth is still initializing, don't redirect
        if (!authProvider.isInitialized) return null;

        final isAuthenticated = authProvider.isAuthenticated;
        final isUnauthorized = authProvider.isUnauthorized;
        final isLoginRoute = state.matchedLocation == '/login';

        // Not authenticated (or unauthorized) → go to login
        if ((!isAuthenticated || isUnauthorized) && !isLoginRoute) {
          return '/login';
        }

        // Authenticated + on login page → redirect to home based on role
        if (isAuthenticated && !isUnauthorized && isLoginRoute) {
          if (authProvider.isAdmin) return '/dashboard';
          if (authProvider.isTeacher) return '/classes';
          return '/attendance';
        }

        // Role-based route guard for markers
        if (isAuthenticated && authProvider.isMarker) {
          final location = state.matchedLocation;
          final isAllowed = _markerAllowedPrefixes.any(
            (prefix) => location.startsWith(prefix),
          );
          if (!isAllowed) return '/attendance';
        }

        // Role-based route guard for teachers
        if (isAuthenticated && authProvider.isTeacher) {
          final location = state.matchedLocation;
          final isAllowed = _teacherAllowedPrefixes.any(
            (prefix) => location.startsWith(prefix),
          );
          if (!isAllowed) return '/classes';
        }

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
                  routes: [
                    GoRoute(
                      path: 'scan/:classId',
                      builder: (context, state) => AttendanceScannerScreen(
                        classId: state.pathParameters['classId']!,
                      ),
                    ),
                  ],
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
        GoRoute(
          path: '/settings/users',
          builder: (context, state) => const UserManagementScreen(),
        ),
      ],
    );
  }
}
