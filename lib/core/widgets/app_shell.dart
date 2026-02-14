import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import '../../models/app_user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/expense_provider.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  /// All navigation items with their branch indices and allowed roles.
  static const _allDestinations = [
    _NavItem(
        icon: Icons.dashboard_rounded,
        label: 'Dashboard',
        branchIndex: 0,
        roles: {UserRole.admin}),
    _NavItem(
        icon: Icons.school_rounded,
        label: 'Students',
        branchIndex: 1,
        roles: {UserRole.admin}),
    _NavItem(
        icon: Icons.person_rounded,
        label: 'Teachers',
        branchIndex: 2,
        roles: {UserRole.admin}),
    _NavItem(
        icon: Icons.class_rounded,
        label: 'Classes',
        branchIndex: 3,
        roles: {UserRole.admin, UserRole.teacher}),
    _NavItem(
        icon: Icons.fact_check_rounded,
        label: 'Attendance',
        branchIndex: 4,
        roles: {UserRole.admin, UserRole.marker}),
    _NavItem(
        icon: Icons.receipt_long_rounded,
        label: 'Payments',
        branchIndex: 5,
        roles: {UserRole.admin, UserRole.teacher, UserRole.marker}),
    _NavItem(
        icon: Icons.money_off_rounded,
        label: 'Expenses',
        branchIndex: 6,
        roles: {UserRole.admin}),
    _NavItem(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        branchIndex: 7,
        roles: {UserRole.admin}),
  ];

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    // Initialize data providers when the shell (authenticated view) is loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().init();
      context.read<TeacherProvider>().init();
      context.read<ClassProvider>().init();
      context.read<ExpenseProvider>().init();
    });
  }

  List<_NavItem> _getVisibleDestinations(UserRole? role) {
    if (role == null) return AppShell._allDestinations;
    return AppShell._allDestinations
        .where((d) => d.roles.contains(role))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isAdmin = authProvider.isAdmin;
    final destinations = _getVisibleDestinations(authProvider.role);
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 600 && width < 1100;

    if (isDesktop) {
      return _DesktopLayout(
        navigationShell: widget.navigationShell,
        destinations: destinations,
        isAdmin: isAdmin,
      );
    } else if (isTablet) {
      return _TabletLayout(
        navigationShell: widget.navigationShell,
        destinations: destinations,
      );
    } else {
      return _MobileLayout(
        navigationShell: widget.navigationShell,
        destinations: destinations,
        isAdmin: isAdmin,
      );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int branchIndex;
  final Set<UserRole> roles;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.branchIndex,
    required this.roles,
  });
}

/// Find the visual index for the current branch
int _visualIndexForBranch(List<_NavItem> destinations, int branchIndex) {
  for (int i = 0; i < destinations.length; i++) {
    if (destinations[i].branchIndex == branchIndex) return i;
  }
  return 0;
}

// ─── Desktop: Full sidebar ─────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> destinations;
  final bool isAdmin;

  const _DesktopLayout({
    required this.navigationShell,
    required this.destinations,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentVisualIndex = _visualIndexForBranch(
      destinations,
      navigationShell.currentIndex,
    );

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 260,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                right: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: colorScheme.onPrimaryContainer,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Ledger',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Divider(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                  indent: 20,
                  endIndent: 20,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final isSelected = currentVisualIndex == index;
                      final item = destinations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => navigationShell.goBranch(
                              item.branchIndex,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 22,
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    item.label,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                // Bottom section: Settings + Sign Out
                _SidebarFooter(isAdmin: isAdmin),
              ],
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Sidebar footer with settings and sign out ─────────────────────
class _SidebarFooter extends StatelessWidget {
  final bool isAdmin;

  const _SidebarFooter({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.appUser;

    return Column(
      children: [
        Divider(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          indent: 20,
          endIndent: 20,
        ),
        if (isAdmin)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/settings/users'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_rounded,
                        size: 22,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Manage Users',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => authProvider.signOut(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      size: 22,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sign Out',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (user != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primaryContainer,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.role.displayName,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

// ─── Tablet: Navigation Rail ───────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> destinations;

  const _TabletLayout({
    required this.navigationShell,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final currentVisualIndex = _visualIndexForBranch(
      destinations,
      navigationShell.currentIndex,
    );

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: currentVisualIndex,
            onDestinationSelected: (index) {
              navigationShell.goBranch(destinations[index].branchIndex);
            },
            leading: Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 8),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.auto_stories_rounded,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
            ),
            destinations: destinations
                .map(
                  (d) => NavigationRailDestination(
                    icon: Icon(d.icon),
                    label: Text(d.label),
                  ),
                )
                .toList(),
          ),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}

// ─── Mobile: Bottom Navigation ─────────────────────────────────────
class _MobileLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> destinations;
  final bool isAdmin;

  const _MobileLayout({
    required this.navigationShell,
    required this.destinations,
    required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final currentVisualIndex = _visualIndexForBranch(
      destinations,
      navigationShell.currentIndex,
    );

    // For markers with <= 4 items, show all in bottom nav
    // For admins, show first 4 + "More"
    if (destinations.length <= 4) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: currentVisualIndex,
          onDestinationSelected: (index) {
            navigationShell.goBranch(destinations[index].branchIndex);
          },
          destinations: destinations
              .map(
                (d) => NavigationDestination(
                  icon: Icon(d.icon),
                  label: d.label,
                ),
              )
              .toList(),
        ),
      );
    }

    // Admin with many items: first 4 in bottom nav + drawer for all
    final bottomItems = destinations.take(4).toList();
    final bottomIndex = currentVisualIndex < 4 ? currentVisualIndex : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomIndex,
        onDestinationSelected: (index) {
          if (index < 4) {
            navigationShell.goBranch(bottomItems[index].branchIndex);
          }
        },
        destinations: [
          ...bottomItems.take(3).map(
                (d) =>
                    NavigationDestination(icon: Icon(d.icon), label: d.label),
              ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.auto_stories_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimaryContainer,
                    size: 36,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ledger',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            ...destinations.map((d) {
              final isSelected = d.branchIndex == navigationShell.currentIndex;
              return ListTile(
                leading: Icon(d.icon),
                title: Text(d.label),
                selected: isSelected,
                onTap: () {
                  Navigator.pop(context);
                  navigationShell.goBranch(d.branchIndex);
                },
              );
            }),
            if (isAdmin) ...[
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people_rounded),
                title: const Text('Manage Users'),
                onTap: () {
                  Navigator.pop(context);
                  context.push('/settings/users');
                },
              ),
            ],
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.logout_rounded,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Sign Out',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                context.read<AuthProvider>().signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
