import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../models/student.dart';
import '../../providers/student_provider.dart';
import '../../providers/class_provider.dart';

class StudentDetailScreen extends StatelessWidget {
  final String studentId;
  const StudentDetailScreen({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer2<StudentProvider, ClassProvider>(
      builder: (context, studentProv, classProv, _) {
        final student = studentProv.students
            .where((s) => s.id == studentId)
            .firstOrNull;

        if (student == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Student')),
            body: const Center(child: Text('Student not found')),
          );
        }

        final enrolledClasses = classProv.classes
            .where((c) => student.classIds.contains(c.id))
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: Text(student.fullName),
            actions: [
              IconButton(
                icon: const Icon(Icons.qr_code_rounded),
                tooltip: 'Print QR',
                onPressed: () => context.go('/students/${student.id}/qr'),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit',
                onPressed: () => context.go('/students/${student.id}/edit'),
              ),
              IconButton(
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: colorScheme.error,
                ),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, studentProv, student),
              ),
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
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 36,
                              backgroundColor: colorScheme.primaryContainer,
                              child: Text(
                                student.firstName.isNotEmpty
                                    ? student.firstName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: colorScheme.onPrimaryContainer,
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
                                    student.fullName,
                                    style: theme.textTheme.headlineSmall
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${student.qrCode}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            QrImageView(
                              data: student.qrCode,
                              version: QrVersions.auto,
                              size: 80,
                              eyeStyle: QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: colorScheme.onSurface,
                              ),
                              dataModuleStyle: QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Info
                    _SectionCard(
                      title: 'Contact Information',
                      items: [
                        _InfoRow(
                          Icons.email_outlined,
                          'Email',
                          student.email.isNotEmpty ? student.email : '—',
                        ),
                        _InfoRow(
                          Icons.phone_outlined,
                          'Mobile',
                          student.mobileNo.isNotEmpty ? student.mobileNo : '—',
                        ),
                        _InfoRow(
                          Icons.location_on_outlined,
                          'Address',
                          student.address.isNotEmpty ? student.address : '—',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Guardian Info
                    _SectionCard(
                      title: 'Guardian Information',
                      items: [
                        _InfoRow(
                          Icons.family_restroom_outlined,
                          'Name',
                          student.guardianName.isNotEmpty
                              ? student.guardianName
                              : '—',
                        ),
                        _InfoRow(
                          Icons.phone_outlined,
                          'Mobile',
                          student.guardianMobileNo.isNotEmpty
                              ? student.guardianMobileNo
                              : '—',
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Enrolled Classes
                    Text(
                      'Enrolled Classes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (enrolledClasses.isEmpty)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: Text(
                              'Not enrolled in any classes',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      ...enrolledClasses.map(
                        (cls) => Card(
                          child: ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.class_rounded,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: Text(cls.className),
                            subtitle: Text(
                              'Fee: ${cls.classFees.toStringAsFixed(2)}',
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

  void _confirmDelete(
    BuildContext context,
    StudentProvider provider,
    Student student,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.deleteStudent(student.id);
              if (context.mounted) context.go('/students');
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

class _SectionCard extends StatelessWidget {
  final String title;
  final List<_InfoRow> items;

  const _SectionCard({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                      width: 80,
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
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(this.icon, this.label, this.value);
}
