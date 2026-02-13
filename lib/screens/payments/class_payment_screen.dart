import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../models/payment.dart';
import '../../models/student.dart';
import '../../providers/class_provider.dart';
import '../../providers/student_provider.dart';
import '../../services/payment_service.dart';

class ClassPaymentScreen extends StatefulWidget {
  const ClassPaymentScreen({super.key});

  @override
  State<ClassPaymentScreen> createState() => _ClassPaymentScreenState();
}

class _ClassPaymentScreenState extends State<ClassPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  String? _selectedClassId;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<Student> _students = [];
  List<Payment> _payments = [];
  bool _loading = false;

  Future<void> _loadData() async {
    if (_selectedClassId == null) return;
    setState(() => _loading = true);

    final classProv = context.read<ClassProvider>();
    final studentProv = context.read<StudentProvider>();

    final cls = classProv.getClassById(_selectedClassId!);
    if (cls == null) return;

    final students = await studentProv.getStudentsByIds(cls.studentIds);
    final payments = await _paymentService.getPaymentsByClassAndMonth(
      _selectedClassId!,
      _selectedMonth,
      _selectedYear,
    );

    if (mounted) {
      setState(() {
        _students = students;
        _payments = payments;
        _loading = false;
      });
    }
  }

  bool _hasPaid(String studentId) {
    return _payments.any((p) => p.studentId == studentId);
  }

  double _paidAmount(String studentId) {
    return _payments
        .where((p) => p.studentId == studentId)
        .fold(0.0, (total, p) => total + p.amount);
  }

  Future<void> _markPayment(Student student, double classFees) async {
    final amountController = TextEditingController(
      text: classFees.toStringAsFixed(2),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Record Payment - ${student.fullName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Month: ${DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth))}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Record Payment'),
          ),
        ],
      ),
    );

    if (result == true) {
      final amount = double.tryParse(amountController.text) ?? classFees;
      await _paymentService.recordPayment(
        Payment(
          id: '',
          classId: _selectedClassId!,
          studentId: student.id,
          amount: amount,
          month: _selectedMonth,
          year: _selectedYear,
        ),
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment recorded for ${student.fullName}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payments'),
        actions: [
          OutlinedButton.icon(
            onPressed: () => context.go('/payments/teacher'),
            icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
            label: const Text('Teacher Payments'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.end,
              children: [
                SizedBox(
                  width: 260,
                  child: Consumer<ClassProvider>(
                    builder: (context, classProv, _) =>
                        DropdownButtonFormField<String>(
                          initialValue: _selectedClassId,
                          decoration: const InputDecoration(
                            labelText: 'Select Class',
                            prefixIcon: Icon(Icons.class_rounded),
                            isDense: true,
                          ),
                          items: classProv.classes
                              .map(
                                (c) => DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.className),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            setState(() => _selectedClassId = v);
                            _loadData();
                          },
                        ),
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedMonth,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      isDense: true,
                    ),
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          DateFormat('MMMM').format(DateTime(2000, i + 1)),
                        ),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _selectedMonth = v!);
                      _loadData();
                    },
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: DropdownButtonFormField<int>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      isDense: true,
                    ),
                    items: List.generate(
                      5,
                      (i) => DropdownMenuItem(
                        value: DateTime.now().year - i,
                        child: Text('${DateTime.now().year - i}'),
                      ),
                    ),
                    onChanged: (v) {
                      setState(() => _selectedYear = v!);
                      _loadData();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Students
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _selectedClassId == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.payments_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Select a class to manage payments',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : Consumer<ClassProvider>(
                    builder: (context, classProv, _) {
                      final cls = classProv.getClassById(_selectedClassId!);
                      final classFees = cls?.classFees ?? 0;
                      final totalPaid = _payments.fold(
                        0.0,
                        (total, p) => total + p.amount,
                      );
                      final paidCount = _students
                          .where((s) => _hasPaid(s.id))
                          .length;

                      return Column(
                        children: [
                          // Summary
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                _buildMiniStat(
                                  context,
                                  'Total Collected',
                                  totalPaid.toStringAsFixed(2),
                                  Colors.green,
                                ),
                                const SizedBox(width: 12),
                                _buildMiniStat(
                                  context,
                                  'Paid',
                                  '$paidCount/${_students.length}',
                                  colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                _buildMiniStat(
                                  context,
                                  'Pending',
                                  '${_students.length - paidCount}',
                                  Colors.orange,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              itemCount: _students.length,
                              itemBuilder: (context, index) {
                                final student = _students[index];
                                final paid = _hasPaid(student.id);
                                final paidAmt = _paidAmount(student.id);

                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: paid
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(
                                              alpha: 0.15,
                                            ),
                                      child: Icon(
                                        paid
                                            ? Icons.check_circle_rounded
                                            : Icons.pending_rounded,
                                        color: paid
                                            ? Colors.green
                                            : Colors.orange,
                                      ),
                                    ),
                                    title: Text(
                                      student.fullName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      paid
                                          ? 'Paid: ${paidAmt.toStringAsFixed(2)}'
                                          : 'Pending - Fee: ${classFees.toStringAsFixed(2)}',
                                    ),
                                    trailing: paid
                                        ? Chip(
                                            label: const Text('Paid'),
                                            backgroundColor: Colors.green
                                                .withValues(alpha: 0.1),
                                            side: BorderSide.none,
                                            labelStyle: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : FilledButton.tonal(
                                            onPressed: () => _markPayment(
                                              student,
                                              classFees,
                                            ),
                                            child: const Text('Mark Paid'),
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
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
    BuildContext context,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
