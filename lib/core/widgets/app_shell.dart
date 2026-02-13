import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:provider/provider.dart';
import '../../providers/student_provider.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/class_provider.dart';
import '../../providers/expense_provider.dart';

class AppShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  static const _destinations = [
    _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _NavItem(icon: Icons.school_rounded, label: 'Students'),
    _NavItem(icon: Icons.person_rounded, label: 'Teachers'),
    _NavItem(icon: Icons.class_rounded, label: 'Classes'),
    _NavItem(icon: Icons.fact_check_rounded, label: 'Attendance'),
    _NavItem(icon: Icons.receipt_long_rounded, label: 'Payments'),
    _NavItem(icon: Icons.money_off_rounded, label: 'Expenses'),
    _NavItem(icon: Icons.bar_chart_rounded, label: 'Reports'),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 1100;
    final isTablet = width >= 600 && width < 1100;

    if (isDesktop) {
      return _DesktopLayout(
        navigationShell: widget.navigationShell,
        destinations: AppShell._destinations,
      );
    } else if (isTablet) {
      return _TabletLayout(
        navigationShell: widget.navigationShell,
        destinations: AppShell._destinations,
      );
    } else {
      return _MobileLayout(
        navigationShell: widget.navigationShell,
        destinations: AppShell._destinations,
      );
    }
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ─── Desktop: Full sidebar ─────────────────────────────────────────
class _DesktopLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  final List<_NavItem> destinations;

  const _DesktopLayout({
    required this.navigationShell,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                      final isSelected = navigationShell.currentIndex == index;
                      final item = destinations[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => navigationShell.goBranch(index),
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
              ],
            ),
          ),
          Expanded(child: navigationShell),
        ],
      ),
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
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: (index) => navigationShell.goBranch(index),
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

  const _MobileLayout({
    required this.navigationShell,
    required this.destinations,
  });

  @override
  Widget build(BuildContext context) {
    // Show only first 5 items in bottom nav, use "More" for rest
    final bottomItems = destinations.take(5).toList();
    final currentIndex = navigationShell.currentIndex < 5
        ? navigationShell.currentIndex
        : 4;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (index < 5) {
            navigationShell.goBranch(index);
          }
        },
        destinations: [
          ...bottomItems
              .take(4)
              .map(
                (d) =>
                    NavigationDestination(icon: Icon(d.icon), label: d.label),
              ),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
      drawer: navigationShell.currentIndex >= 4
          ? null
          : Drawer(
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(destinations.length, (index) {
                    final d = destinations[index];
                    return ListTile(
                      leading: Icon(d.icon),
                      title: Text(d.label),
                      selected: navigationShell.currentIndex == index,
                      onTap: () {
                        Navigator.pop(context);
                        navigationShell.goBranch(index);
                      },
                    );
                  }),
                ],
              ),
            ),
    );
  }
}
