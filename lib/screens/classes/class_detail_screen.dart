import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/student_provider.dart';
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
              const SizedBox(width: 8),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
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
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

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
                                student.firstName.isNotEmpty
                                    ? student.firstName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(student.fullName),
                            subtitle: Text(
                              student.email.isNotEmpty
                                  ? student.email
                                  : student.mobileNo,
                            ),
                            trailing: IconButton(
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
        .where((s) => !enrolledIds.contains(s.id))
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
                          student.firstName.isNotEmpty
                              ? student.firstName[0].toUpperCase()
                              : '?',
                        ),
                      ),
                      title: Text(student.fullName),
                      subtitle: Text(student.email),
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
        content: const Text('Are you sure you want to delete this class?'),
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
}
