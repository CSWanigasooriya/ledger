import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/teacher_provider.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/empty_state.dart';

class TeacherListScreen extends StatefulWidget {
  const TeacherListScreen({super.key});

  @override
  State<TeacherListScreen> createState() => _TeacherListScreenState();
}

class _TeacherListScreenState extends State<TeacherListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teachers'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/teachers/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Teacher'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SearchField(
              hintText: 'Search teachers...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: Consumer<TeacherProvider>(
              builder: (context, provider, _) {
                final teachers = provider.search(_searchQuery);

                if (teachers.isEmpty && provider.teachers.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_rounded,
                    title: 'No teachers yet',
                    subtitle: 'Add your first teacher to get started',
                    action: FilledButton.icon(
                      onPressed: () => context.go('/teachers/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Teacher'),
                    ),
                  );
                }

                if (teachers.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: teachers.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final teacher = teachers[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.secondaryContainer,
                          child: Text(
                            teacher.name.isNotEmpty
                                ? teacher.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          teacher.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          teacher.email.isNotEmpty
                              ? teacher.email
                              : teacher.contactNo,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () => context.go('/teachers/${teacher.id}'),
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
