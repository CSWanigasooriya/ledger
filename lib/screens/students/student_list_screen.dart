import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/student_provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/empty_state.dart';

class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Students'),
        actions: [
          if (authProvider.isSuperAdmin)
            Consumer<StudentProvider>(
              builder: (context, provider, _) => FilterChip(
                label: Text(provider.showDeleted ? 'Hide Deleted' : 'Show Deleted'),
                selected: provider.showDeleted,
                onSelected: (_) => provider.toggleShowDeleted(),
              ),
            ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => context.go('/students/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Student'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SearchField(
              hintText: 'Search by name, email, mobile, or student ID...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, _) {
                final students = provider.search(_searchQuery);

                if (students.isEmpty && provider.students.isEmpty) {
                  return EmptyState(
                    icon: Icons.school_rounded,
                    title: 'No students yet',
                    subtitle: 'Add your first student to get started',
                    action: FilledButton.icon(
                      onPressed: () => context.go('/students/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Student'),
                    ),
                  );
                }

                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                    subtitle: 'Try a different search term',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: students.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isDeleted = student.isDeleted;

                    return Opacity(
                      opacity: isDeleted ? 0.5 : 1.0,
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isDeleted
                                ? colorScheme.errorContainer
                                : colorScheme.primaryContainer,
                            child: Text(
                              student.studentId.isNotEmpty
                                  ? student.studentId.substring(0, 1)
                                  : student.firstName.isNotEmpty
                                      ? student.firstName[0].toUpperCase()
                                      : '?',
                              style: TextStyle(
                                color: isDeleted
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          title: Row(
                            children: [
                              if (student.studentId.isNotEmpty)
                                Container(
                                  margin: const EdgeInsets.only(right: 8),
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
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  student.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                            student.email.isNotEmpty
                                ? student.email
                                : student.mobileNo.isNotEmpty
                                    ? student.mobileNo
                                    : 'No contact info',
                            style:
                                TextStyle(color: colorScheme.onSurfaceVariant),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (student.isFreeCard)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Tooltip(
                                    message: 'Free Card',
                                    child: Icon(
                                      Icons.card_giftcard,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ),
                              if (isDeleted)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Tooltip(
                                    message: 'Deleted',
                                    child: Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                      color: colorScheme.error,
                                    ),
                                  ),
                                ),
                              if (student.classIds.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${student.classIds.length} classes',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          onTap: () => context.go('/students/${student.id}'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
