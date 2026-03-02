import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/student.dart';

class ClassDetailScreen extends StatefulWidget {
  final String classId;
  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  List<Student> _enrolledStudents = [];
  bool _loadingStudents = false;

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final classProv = context.read<ClassProvider>();
    final studentProv = context.read<StudentProvider>();
    final cls = classProv.getClassById(widget.classId);
    if (cls != null && cls.studentIds.isNotEmpty) {
      setState(() => _loadingStudents = true);
      final students = await studentProv.getStudentsByIds(cls.studentIds);
      if (mounted) {
        setState(() {
          _enrolledStudents = students;
          _loadingStudents = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final isSuperAdmin = authProvider.isSuperAdmin;

    return Consumer3<ClassProvider, TeacherProvider, StudentProvider>(
      builder: (context, classProv, teacherProv, studentProv, _) {
        final cls = classProv.getClassById(widget.classId);

        if (cls == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Class')),
            body: const Center(child: Text('Class not found')),
          );
        }

        final teacher = teacherProv.getTeacherById(cls.teacherId);

        return Scaffold(
          appBar: AppBar(
            title: Text(cls.className),
            actions: [
              if (!cls.isDeleted) ...[
                IconButton(
                  icon: const Icon(Icons.edit_rounded),
                  onPressed: () => context.go('/classes/${cls.id}/edit'),
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: colorScheme.error,
                  ),
                  onPressed: () => _confirmDelete(context, classProv),
                ),
              ] else if (isSuperAdmin)
                FilledButton.icon(
                  onPressed: () => _confirmRestore(context, classProv),
                  icon: const Icon(Icons.restore_rounded, size: 18),
                  label: const Text('Restore'),
                ),
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: cls.isDeleted
              ? null
              : FloatingActionButton.extended(
                  onPressed: () => _showEnrollDialog(
                    context,
                    classProv,
                    studentProv,
                    cls.id,
                    cls.studentIds,
                  ),
                  icon: const Icon(Icons.person_add_rounded),
                  label: const Text('Enroll Student'),
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
                    if (cls.isDeleted)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.delete_rounded,
                                color: colorScheme.onErrorContainer),
                            const SizedBox(width: 8),
                            Text(
                              'This class has been deleted',
                              style: TextStyle(
                                color: colorScheme.onErrorContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Class Info Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Icon(
                                    Icons.class_rounded,
                                    color: colorScheme.onTertiaryContainer,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        cls.className,
                                        style: theme.textTheme.headlineSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        teacher != null
                                            ? 'Teacher: ${teacher.name}'
                                            : 'No teacher assigned',
                                        style: TextStyle(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                _buildStatChip(
                                  context,
                                  'Students',
                                  '${cls.studentIds.length}',
                                  Icons.people_rounded,
                                ),
                                const SizedBox(width: 12),
                                _buildStatChip(
                                  context,
                                  'Fees',
                                  cls.classFees.toStringAsFixed(2),
                                  Icons.payments_rounded,
                                ),
                                const SizedBox(width: 12),
                                _buildStatChip(
                                  context,
                                  'Commission',
                                  '${cls.teacherCommissionRate}%',
                                  Icons.percent_rounded,
                                ),
                                const SizedBox(width: 12),
                                _buildStatChip(
                                  context,
                                  'Weeks',
                                  '${cls.numberOfWeeks}',
                                  Icons.calendar_view_week,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Audit Log (for superAdmin)
                    if (isSuperAdmin && cls.auditLog.isNotEmpty) ...[
                      Text(
                        'Audit Trail',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: cls.auditLog
                                .take(10)
                                .map(
                                  (entry) => Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(
                                          Icons.history_rounded,
                                          size: 16,
                                          color:
                                              colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${entry.field}: "${entry.oldValue}" → "${entry.newValue}"',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight:
                                                      FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${entry.changedBy} • ${DateFormat('dd MMM yyyy HH:mm').format(entry.changedAt)}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Enrolled Students
                    Row(
                      children: [
                        Text(
                          'Enrolled Students (${cls.studentIds.length})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        if (_loadingStudents)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_enrolledStudents.isEmpty && !_loadingStudents)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.people_outline_rounded,
                                  size: 40,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No students enrolled',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      ..._enrolledStudents.map(
                        (student) => Card(
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                student.studentId.isNotEmpty
                                    ? student.studentId[0].toUpperCase()
                                    : student.firstName.isNotEmpty
                                        ? student.firstName[0].toUpperCase()
                                        : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Row(
                              children: [
                                if (student.studentId.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      student.studentId,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Expanded(child: Text(student.fullName)),
                                if (student.isFreeCard)
                                  Icon(
                                    Icons.card_giftcard,
                                    size: 16,
                                    color: Colors.orange.shade700,
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              student.email.isNotEmpty
                                  ? student.email
                                  : student.mobileNo,
                            ),
                            trailing: cls.isDeleted
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.remove_circle_outline,
                                      color: colorScheme.error,
                                    ),
                                    tooltip: 'Remove from class',
                                    onPressed: () async {
                                      await classProv.removeStudent(
                                        cls.id,
                                        student.id,
                                      );
                                      _loadStudents();
                                    },
                                  ),
                            onTap: () => context.go('/students/${student.id}'),
                          ),
                        ),
                      ),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatChip(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnrollDialog(
    BuildContext context,
    ClassProvider classProv,
    StudentProvider studentProv,
    String classId,
    List<String> enrolledIds,
  ) {
    final available = studentProv.students
        .where((s) => !enrolledIds.contains(s.id) && !s.isDeleted)
        .toList();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enroll Student'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: available.isEmpty
              ? const Center(child: Text('All students are already enrolled'))
              : ListView.builder(
                  itemCount: available.length,
                  itemBuilder: (context, index) {
                    final student = available[index];
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          student.studentId.isNotEmpty
                              ? student.studentId[0].toUpperCase()
                              : student.firstName.isNotEmpty
                                  ? student.firstName[0].toUpperCase()
                                  : '?',
                        ),
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(
                        student.studentId.isNotEmpty
                            ? student.studentId
                            : student.email,
                      ),
                      onTap: () async {
                        Navigator.pop(ctx);
                        await classProv.enrollStudent(classId, student.id);
                        _loadStudents();
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ClassProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Class'),
        content: const Text(
          'Are you sure you want to delete this class? It can be restored later by a super admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteClass(widget.classId);
              if (context.mounted) context.go('/classes');
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

  void _confirmRestore(BuildContext context, ClassProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Class'),
        content: const Text('Do you want to restore this deleted class?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Restore via service directly (update isDeleted = false)
              await provider.updateClass(
                provider.getClassById(widget.classId)!.copyWith(isDeleted: false),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Class restored')),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }
}
