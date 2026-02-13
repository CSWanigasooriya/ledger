import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/report_provider.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _month = DateTime.now().month;
  int _year = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    final p = context.read<ReportProvider>();
    await p.loadMonthlyReport(_month, _year);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Consumer<ReportProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Month/Year selector
                    Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.end,
                      children: [
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<int>(
                            initialValue: _month,
                            decoration: const InputDecoration(
                              labelText: 'Month',
                              isDense: true,
                            ),
                            items: List.generate(
                              12,
                              (i) => DropdownMenuItem(
                                value: i + 1,
                                child: Text(
                                  DateFormat(
                                    'MMMM',
                                  ).format(DateTime(2000, i + 1)),
                                ),
                              ),
                            ),
                            onChanged: (v) {
                              setState(() => _month = v!);
                              _loadReport();
                            },
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: DropdownButtonFormField<int>(
                            initialValue: _year,
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
                              setState(() => _year = v!);
                              _loadReport();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (provider.isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else ...[
                      // Financial Summary
                      Text(
                        'Financial Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildFinCard(
                            cs,
                            'Revenue',
                            provider.reportData?.totalRevenue.toStringAsFixed(
                                  2,
                                ) ??
                                '0.00',
                            Colors.green,
                            Icons.trending_up_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildFinCard(
                            cs,
                            'Expenses',
                            provider.reportData?.totalExpenses.toStringAsFixed(
                                  2,
                                ) ??
                                '0.00',
                            Colors.red,
                            Icons.trending_down_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildFinCard(
                            cs,
                            'Teacher Pay',
                            provider.reportData?.totalTeacherPayments
                                    .toStringAsFixed(2) ??
                                '0.00',
                            Colors.orange,
                            Icons.payments_rounded,
                          ),
                          const SizedBox(width: 12),
                          _buildFinCard(
                            cs,
                            'Net Income',
                            provider.reportData?.netIncome.toStringAsFixed(2) ??
                                '0.00',
                            Colors.blue,
                            Icons.account_balance_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Revenue by Class
                      if (provider.revenueByClass.isNotEmpty) ...[
                        Text(
                          'Revenue by Class',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxRevenue(provider.revenueByClass) * 1.2,
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (v, _) {
                                      final keys = provider.revenueByClass.keys
                                          .toList();
                                      if (v.toInt() < keys.length) {
                                        final k = keys[v.toInt()];
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            k.length > 8
                                                ? '${k.substring(0, 8)}...'
                                                : k,
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                        );
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: _buildBarGroups(
                                provider.revenueByClass,
                                cs,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Expenses by Type
                      if (provider.expensesByType.isNotEmpty) ...[
                        Text(
                          'Expenses by Type',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 2,
                                    centerSpaceRadius: 40,
                                    sections: _buildPieSections(
                                      provider.expensesByType,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _buildLegend(provider.expensesByType),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFinCard(
    ColorScheme cs,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  double _maxRevenue(Map<String, double> data) {
    if (data.isEmpty) return 100;
    return data.values.reduce((a, b) => a > b ? a : b);
  }

  List<BarChartGroupData> _buildBarGroups(
    Map<String, double> data,
    ColorScheme cs,
  ) {
    final keys = data.keys.toList();
    return List.generate(
      keys.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: data[keys[i]] ?? 0,
            color: cs.primary,
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      ),
    );
  }

  final _pieColors = [
    Colors.blue,
    Colors.orange,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.red,
    Colors.indigo,
  ];

  List<PieChartSectionData> _buildPieSections(Map<String, double> data) {
    final total = data.values.fold(0.0, (a, b) => a + b);
    final keys = data.keys.toList();
    return List.generate(keys.length, (i) {
      final pct = total > 0 ? (data[keys[i]]! / total * 100) : 0.0;
      return PieChartSectionData(
        color: _pieColors[i % _pieColors.length],
        value: data[keys[i]] ?? 0,
        title: '${pct.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    });
  }

  List<Widget> _buildLegend(Map<String, double> data) {
    final keys = data.keys.toList();
    return List.generate(
      keys.length,
      (i) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _pieColors[i % _pieColors.length],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(width: 6),
            Text(keys[i], style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
