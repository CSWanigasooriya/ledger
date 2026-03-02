import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/teacher.dart';

class TeacherDetailScreen extends StatelessWidget {
  final String teacherId;
  const TeacherDetailScreen({super.key, required this.teacherId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProv = context.watch<AuthProvider>();

    return Consumer2<TeacherProvider, ClassProvider>(
      builder: (context, teacherProv, classProv, _) {
        final teacher =
            teacherProv.teachers.where((t) => t.id == teacherId).firstOrNull;

        if (teacher == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Teacher')),
            body: const Center(child: Text('Teacher not found')),
          );
        }

        final assignedClasses = classProv.getClassesByTeacher(teacher.id);

        return Scaffold(
          appBar: AppBar(
            title: Text(teacher.name),
            actions: [
              if (!teacher.isDeleted) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => context.go('/teachers/${teacher.id}/edit'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  onPressed: () =>
                      _confirmSoftDelete(context, teacherProv, teacher),
                ),
              ] else if (authProv.isSuperAdmin) ...[
                IconButton(
                  icon: const Icon(Icons.restore_rounded, color: Colors.green),
                  tooltip: 'Restore',
                  onPressed: () async {
                    await teacherProv.restoreTeacher(teacher.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Teacher restored')),
                      );
                    }
                  },
                ),
              ],
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Deleted banner
                    if (teacher.isDeleted)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                color: colorScheme.error),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'This teacher has been deleted',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ),
                            if (authProv.isSuperAdmin)
                              TextButton(
                                onPressed: () =>
                                    teacherProv.restoreTeacher(teacher.id),
                                child: const Text('Restore'),
                              ),
                          ],
                        ),
                      ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: colorScheme.secondaryContainer,
                              child: Text(
                                teacher.name.isNotEmpty
                                    ? teacher.name[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    teacher.name,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  if (teacher.nic.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'NIC: ${teacher.nic}',
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: teacher.status ==
                                                  TeacherStatus.active
                                              ? Colors.green
                                                  .withValues(alpha: 0.15)
                                              : Colors.orange
                                                  .withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          teacher.status.displayName,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: teacher.status ==
                                                    TeacherStatus.active
                                                ? Colors.green
                                                : Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoCard(theme, 'Contact Information', [
                      _InfoItem(
                        Icons.email_outlined,
                        'Email',
                        teacher.email.isNotEmpty ? teacher.email : '—',
                      ),
                      _InfoItem(
                        Icons.phone_outlined,
                        'Contact',
                        teacher.contactNo.isNotEmpty ? teacher.contactNo : '—',
                      ),
                      _InfoItem(
                        Icons.location_on_outlined,
                        'Address',
                        teacher.address.isNotEmpty ? teacher.address : '—',
                      ),
                    ]),
                    const SizedBox(height: 16),
                    _buildInfoCard(theme, 'Bank Details', [
                      _InfoItem(
                        Icons.account_balance_outlined,
                        'Bank',
                        teacher.bankDetails.bankName.isNotEmpty
                            ? teacher.bankDetails.bankName
                            : '—',
                      ),
                      _InfoItem(
                        Icons.numbers_outlined,
                        'Account Number',
                        teacher.bankDetails.accountNo.isNotEmpty
                            ? teacher.bankDetails.accountNo
                            : '—',
                      ),
                      _InfoItem(
                        Icons.location_city_outlined,
                        'Branch',
                        teacher.bankDetails.branch.isNotEmpty
                            ? teacher.bankDetails.branch
                            : '—',
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Text(
                      'Assigned Classes (${assignedClasses.length})',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (assignedClasses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'No classes assigned',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ...assignedClasses.map(
                        (cls) => Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.class_rounded,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                            title: Text(cls.className),
                            subtitle: Text(
                              'Commission: ${cls.teacherCommissionRate}% • ${cls.studentIds.length} students',
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => context.go('/classes/${cls.id}'),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(ThemeData theme, String title, List<_InfoItem> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      item.icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 90,
                      child: Text(
                        item.label,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item.value,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSoftDelete(
    BuildContext context,
    TeacherProvider provider,
    Teacher teacher,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Teacher'),
        content: Text(
            'Are you sure you want to delete ${teacher.name}? This can be restored by a super admin.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteTeacher(teacher.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${teacher.name} deleted')),
                );
                context.go('/teachers');
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem(this.icon, this.label, this.value);
}
