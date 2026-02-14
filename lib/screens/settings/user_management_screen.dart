import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/user_service.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: StreamBuilder<List<AppUser>>(
        stream: _userService.getAllUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                  const SizedBox(height: 12),
                  Text('Error loading users: ${snapshot.error}'),
                ],
              ),
            );
          }

          final users = snapshot.data ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              return _UserCard(
                user: user,
                onRoleChanged: (newRole) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await _userService.updateRole(user.uid, newRole);
                  if (mounted) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          '${user.displayName} is now ${newRole.displayName}',
                        ),
                      ),
                    );
                  }
                },
                onDelete: () => _confirmDelete(user),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(AppUser user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove User Access'),
        content: Text(
          'Are you sure you want to revoke access for ${user.displayName} (${user.email})?\n\nThey will need to be re-added to regain access.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              final messenger = ScaffoldMessenger.of(this.context);
              await _userService.deleteUser(user.uid);
              if (mounted) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Access revoked for ${user.displayName}'),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final AppUser user;
  final ValueChanged<UserRole> onRoleChanged;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.onRoleChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 22,
              backgroundColor: user.isPending
                  ? colorScheme.errorContainer
                  : user.isAdmin
                      ? colorScheme.primaryContainer
                      : colorScheme.tertiaryContainer,
              child: Icon(
                user.isPending
                    ? Icons.hourglass_top_rounded
                    : user.isAdmin
                        ? Icons.admin_panel_settings_rounded
                        : user.isTeacher
                            ? Icons.school_rounded
                            : Icons.qr_code_scanner_rounded,
                color: user.isPending
                    ? colorScheme.onErrorContainer
                    : user.isAdmin
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onTertiaryContainer,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isNotEmpty ? user.displayName : 'No Name',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Role dropdown — only show assignable roles (not pending)
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<UserRole>(
                initialValue: user.isPending ? null : user.role,
                hint: Text(
                  'Assign Role',
                  style: TextStyle(
                      color: colorScheme.error, fontWeight: FontWeight.w600),
                ),
                borderRadius: BorderRadius.circular(12),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: UserRole.values
                    .where((r) => r != UserRole.pending)
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.displayName,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (role) {
                  if (role != null && role != user.role) {
                    onRoleChanged(role);
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            // Delete button
            IconButton(
              icon: Icon(
                Icons.person_remove_rounded,
                color: colorScheme.error,
                size: 20,
              ),
              tooltip: 'Remove access',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}
