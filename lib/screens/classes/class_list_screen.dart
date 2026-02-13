import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/class_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../core/widgets/search_field.dart';
import '../../core/widgets/empty_state.dart';

class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classes'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/classes/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Class'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: SearchField(
              hintText: 'Search classes...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
          Expanded(
            child: Consumer2<ClassProvider, TeacherProvider>(
              builder: (context, classProv, teacherProv, _) {
                var classes = classProv.classes;
                if (_searchQuery.isNotEmpty) {
                  final lq = _searchQuery.toLowerCase();
                  classes = classes
                      .where((c) => c.className.toLowerCase().contains(lq))
                      .toList();
                }

                if (classes.isEmpty && classProv.classes.isEmpty) {
                  return EmptyState(
                    icon: Icons.class_rounded,
                    title: 'No classes yet',
                    subtitle: 'Create your first class to get started',
                    action: FilledButton.icon(
                      onPressed: () => context.go('/classes/new'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create Class'),
                    ),
                  );
                }

                if (classes.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No results found',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: classes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final cls = classes[index];
                    final teacher = teacherProv.getTeacherById(cls.teacherId);

                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colorScheme.tertiaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.class_rounded,
                            color: colorScheme.onTertiaryContainer,
                          ),
                        ),
                        title: Text(
                          cls.className,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              teacher != null
                                  ? 'Teacher: ${teacher.name}'
                                  : 'No teacher assigned',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildChip(
                                  context,
                                  '${cls.studentIds.length} students',
                                  colorScheme.primaryContainer,
                                  colorScheme.onPrimaryContainer,
                                ),
                                const SizedBox(width: 8),
                                _buildChip(
                                  context,
                                  'Fee: ${cls.classFees.toStringAsFixed(0)}',
                                  colorScheme.secondaryContainer,
                                  colorScheme.onSecondaryContainer,
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        onTap: () => context.go('/classes/${cls.id}'),
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

  Widget _buildChip(BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
