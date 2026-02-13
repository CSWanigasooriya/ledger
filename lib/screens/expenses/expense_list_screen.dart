import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/expense_provider.dart';
import 'package:go_router/go_router.dart';

class ExpenseListScreen extends StatelessWidget {
  const ExpenseListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          FilledButton.icon(
            onPressed: () => context.go('/expenses/new'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Expense'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, _) {
          final expenses = provider.expenses;

          if (expenses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.money_off_rounded,
                    size: 64,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No expenses recorded',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => context.go('/expenses/new'),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Expense'),
                  ),
                ],
              ),
            );
          }

          // Group by month
          final totalAmount = expenses.fold(0.0, (sum, e) => sum + e.amount);

          return Column(
            children: [
              // Total summary
              Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.errorContainer,
                      colorScheme.errorContainer.withValues(alpha: 0.6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.onErrorContainer,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Expenses',
                          style: TextStyle(
                            color: colorScheme.onErrorContainer.withValues(
                              alpha: 0.7,
                            ),
                          ),
                        ),
                        Text(
                          totalAmount.toStringAsFixed(2),
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: expenses.length,
                  itemBuilder: (context, index) {
                    final expense = expenses[index];
                    return Dismissible(
                      key: Key(expense.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.delete_rounded,
                          color: colorScheme.onError,
                        ),
                      ),
                      onDismissed: (_) => provider.deleteExpense(expense.id),
                      child: Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _getExpenseColor(
                                expense.type,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _getExpenseIcon(expense.type),
                              color: _getExpenseColor(expense.type),
                            ),
                          ),
                          title: Text(
                            expense.type,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (expense.description.isNotEmpty)
                                Text(expense.description),
                              Text(
                                DateFormat('dd MMM yyyy').format(expense.date),
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            expense.amount.toStringAsFixed(2),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.error,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _getExpenseIcon(String type) {
    switch (type) {
      case 'Staff':
        return Icons.people_rounded;
      case 'Cleaning':
        return Icons.cleaning_services_rounded;
      case 'Food':
        return Icons.restaurant_rounded;
      case 'Utilities':
        return Icons.electrical_services_rounded;
      case 'Supplies':
        return Icons.inventory_rounded;
      case 'Maintenance':
        return Icons.build_rounded;
      default:
        return Icons.receipt_rounded;
    }
  }

  Color _getExpenseColor(String type) {
    switch (type) {
      case 'Staff':
        return Colors.blue;
      case 'Cleaning':
        return Colors.teal;
      case 'Food':
        return Colors.orange;
      case 'Utilities':
        return Colors.purple;
      case 'Supplies':
        return Colors.indigo;
      case 'Maintenance':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }
}
