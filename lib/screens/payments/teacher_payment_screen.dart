import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/teacher_payment.dart';
import '../../providers/teacher_provider.dart';
import '../../providers/class_provider.dart';
import '../../services/teacher_payment_service.dart';
import '../../services/payment_service.dart';

class TeacherPaymentScreen extends StatefulWidget {
  const TeacherPaymentScreen({super.key});

  @override
  State<TeacherPaymentScreen> createState() => _TeacherPaymentScreenState();
}

class _TeacherPaymentScreenState extends State<TeacherPaymentScreen> {
  final TeacherPaymentService _teacherPaymentService = TeacherPaymentService();
  final PaymentService _paymentService = PaymentService();

  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<TeacherPayment> _teacherPayments = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _loading = true);
    try {
      final payments = await _teacherPaymentService.getPaymentsByMonth(
        _selectedMonth,
        _selectedYear,
      );
      if (mounted) {
        setState(() {
          _teacherPayments = payments;
          _loading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load payments: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _makePayment() async {
    final teacherProv = context.read<TeacherProvider>();
    final classProv = context.read<ClassProvider>();

    String? selectedTeacherId;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    double salesAmount = 0;
    double commissionAmount = 0;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Make Teacher Payment'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedTeacherId,
                    decoration: const InputDecoration(
                      labelText: 'Select Teacher',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: teacherProv.teachers
                        .map(
                          (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) async {
                      setDialogState(() => selectedTeacherId = v);
                      if (v != null) {
                        // Calculate sales and commission
                        final classes = classProv.getClassesByTeacher(v);
                        double totalSales = 0;
                        double totalCommission = 0;
                        for (final cls in classes) {
                          final payments = await _paymentService
                              .getPaymentsByClassAndMonth(
                                cls.id,
                                _selectedMonth,
                                _selectedYear,
                              );
                          final classSales = payments.fold(
                            0.0,
                            (total, p) => total + p.amount,
                          );
                          totalSales += classSales;
                          totalCommission +=
                              classSales * cls.teacherCommissionRate / 100;
                        }
                        setDialogState(() {
                          salesAmount = totalSales;
                          commissionAmount = totalCommission;
                          amountController.text = commissionAmount
                              .toStringAsFixed(2);
                        });
                      }
                    },
                  ),
                  if (selectedTeacherId != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          _infoRow(
                            'Total Sales',
                            salesAmount.toStringAsFixed(2),
                          ),
                          _infoRow(
                            'Commission',
                            commissionAmount.toStringAsFixed(2),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Payment Amount',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      prefixIcon: Icon(Icons.notes_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: selectedTeacherId == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              child: const Text('Make Payment'),
            ),
          ],
        ),
      ),
    );

    if (result == true && selectedTeacherId != null) {
      await _teacherPaymentService.createPayment(
        TeacherPayment(
          id: '',
          teacherId: selectedTeacherId!,
          amount: double.tryParse(amountController.text) ?? 0,
          month: _selectedMonth,
          year: _selectedYear,
          salesAmount: salesAmount,
          commissionAmount: commissionAmount,
          notes: notesController.text,
        ),
      );
      _loadPayments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Teacher payment recorded')),
        );
      }
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Payments')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _makePayment,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Make Payment'),
      ),
      body: Column(
        children: [
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
            child: Row(
              children: [
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
                      _loadPayments();
                    },
                  ),
                ),
                const SizedBox(width: 16),
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
                      _loadPayments();
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Something went wrong',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: TextStyle(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _loadPayments,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _teacherPayments.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_rounded,
                          size: 64,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No teacher payments for this month',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : Consumer<TeacherProvider>(
                    builder: (context, teacherProv, _) {
                      return ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _teacherPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _teacherPayments[index];
                          final teacher = teacherProv.getTeacherById(
                            payment.teacherId,
                          );

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            colorScheme.secondaryContainer,
                                        child: Text(
                                          teacher?.name.isNotEmpty == true
                                              ? teacher!.name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: colorScheme
                                                .onSecondaryContainer,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              teacher?.name ?? 'Unknown',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            Text(
                                              DateFormat(
                                                'dd MMM yyyy',
                                              ).format(payment.date),
                                              style: TextStyle(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        payment.amount.toStringAsFixed(2),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.green,
                                            ),
                                      ),
                                    ],
                                  ),
                                  if (payment.notes.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      payment.notes,
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _miniLabel(
                                        'Sales',
                                        payment.salesAmount.toStringAsFixed(2),
                                      ),
                                      const SizedBox(width: 12),
                                      _miniLabel(
                                        'Commission',
                                        payment.commissionAmount
                                            .toStringAsFixed(2),
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _miniLabel(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
