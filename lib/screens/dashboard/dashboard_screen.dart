import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/student_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/stat_card.dart';
import '../../core/theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Education Management Platform',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () {
              context.read<AuthProvider>().signOut();
              context.go('/login');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Grid
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 4
                    : constraints.maxWidth > 600
                        ? 2
                        : 2;
                return _buildStatsGrid(context, crossAxisCount);
              },
            ),

            const SizedBox(height: 32),

            // Quick Actions
            Text(
              'Quick Actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildQuickActions(context),

            const SizedBox(height: 32),

            // Recent Activity placeholder
            Text(
              'Overview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _buildOverviewCards(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, int crossAxisCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer3<StudentProvider, TeacherProvider, ClassProvider>(
      builder: (context, studentProv, teacherProv, classProv, _) {
        final stats = [
          StatCard(
            title: 'Total Students',
            value: '${studentProv.students.length}',
            icon: Icons.school_rounded,
            iconColor: colorScheme.primary,
            onTap: () => context.go('/students'),
          ),
          StatCard(
            title: 'Total Teachers',
            value: '${teacherProv.teachers.length}',
            icon: Icons.person_rounded,
            iconColor: AppTheme.successColor,
            onTap: () => context.go('/teachers'),
          ),
          StatCard(
            title: 'Active Classes',
            value: '${classProv.classes.length}',
            icon: Icons.class_rounded,
            iconColor: AppTheme.warningColor,
            onTap: () => context.go('/classes'),
          ),
          StatCard(
            title: 'Total Enrolled',
            value:
                '${classProv.classes.fold<int>(0, (sum, c) => sum + c.studentIds.length)}',
            icon: Icons.group_rounded,
            iconColor: AppTheme.infoColor,
          ),
        ];

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: crossAxisCount >= 4 ? 2.6 : 1.4,
          children: stats,
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final actions = [
      _QuickAction(
        icon: Icons.person_add_rounded,
        label: 'Add Student',
        color: colorScheme.primary,
        onTap: () => context.go('/students/new'),
      ),
      _QuickAction(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add Teacher',
        color: AppTheme.successColor,
        onTap: () => context.go('/teachers/new'),
      ),
      _QuickAction(
        icon: Icons.add_circle_outline_rounded,
        label: 'Add Class',
        color: AppTheme.warningColor,
        onTap: () => context.go('/classes/new'),
      ),
      _QuickAction(
        icon: Icons.fact_check_rounded,
        label: 'Mark Attendance',
        color: AppTheme.infoColor,
        onTap: () => context.go('/attendance'),
      ),
      _QuickAction(
        icon: Icons.payments_rounded,
        label: 'Record Payment',
        color: colorScheme.tertiary,
        onTap: () => context.go('/payments'),
      ),
      _QuickAction(
        icon: Icons.bar_chart_rounded,
        label: 'View Reports',
        color: colorScheme.error,
        onTap: () => context.go('/reports'),
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions.map((a) => _buildQuickActionChip(context, a)).toList(),
    );
  }

  Widget _buildQuickActionChip(BuildContext context, _QuickAction action) {
    return ActionChip(
      avatar: Icon(action.icon, size: 18, color: action.color),
      label: Text(action.label),
      onPressed: action.onTap,
      side: BorderSide(color: action.color.withValues(alpha: 0.3)),
      backgroundColor: action.color.withValues(alpha: 0.05),
    );
  }

  Widget _buildOverviewCards(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ClassProvider>(
      builder: (context, classProv, _) {
        if (classProv.classes.isEmpty) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No classes created yet',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.tonal(
                      onPressed: () => context.go('/classes/new'),
                      child: const Text('Create your first class'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Column(
          children: classProv.classes.take(5).map((cls) {
            return Card(
              child: ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.class_rounded,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  cls.className,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${cls.studentIds.length} students enrolled'),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onTap: () => context.go('/classes/${cls.id}'),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
