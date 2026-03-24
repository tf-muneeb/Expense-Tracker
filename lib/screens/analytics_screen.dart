import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/constants.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _touchedPieIndex = -1;
  String _barMode = 'weekly';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final categoryTotals = provider.categoryTotalsAllTime;
    final totalSpent = categoryTotals.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: provider.allExpenses.isEmpty
          ? _buildEmptyState(context)
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [

          _buildMonthBanner(context, provider),
          const SizedBox(height: 20),

          _buildSectionTitle(context, 'Spending by Category'),
          const SizedBox(height: 12),
          _buildPieChart(context, provider, categoryTotals, totalSpent),
          const SizedBox(height: 20),

          _buildCategoryLegend(context, categoryTotals, totalSpent),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Spending Trend'),
          const SizedBox(height: 4),
          _buildBarToggle(context),
          const SizedBox(height: 12),
          _buildBarChart(context, provider),
          const SizedBox(height: 24),

          _buildSectionTitle(context, 'Top 5 Expenses'),
          const SizedBox(height: 12),
          _buildTopExpenses(context, provider),
        ],
      ),
    );
  }

  Widget _buildMonthBanner(
      BuildContext context, ExpenseProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final monthExpenses = provider.thisMonthExpenses;
    final total = provider.thisMonthTotal;
    final count = monthExpenses.length;
    final avg = count == 0 ? 0.0 : total / count;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs ${NumberFormat('#,##0.00').format(total)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _BannerStat(
                  label: 'Transactions',
                  value: '$count',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _BannerStat(
                  label: 'Avg / expense',
                  value: 'Rs ${NumberFormat('#,##0').format(avg)}',
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
              ),
              Expanded(
                child: _BannerStat(
                  label: 'Categories',
                  value: '${provider.categoryTotals.keys.length}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(
      BuildContext context,
      ExpenseProvider provider,
      Map<String, double> totals,
      double totalSpent,
      ) {
    if (totals.isEmpty) {
      return const SizedBox.shrink();
    }

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: entries.asMap().entries.map((e) {
                      final index = e.key;
                      final entry = e.value;
                      final color =
                      AppCategories.getColor(entry.key);
                      final isTouched = index == _touchedPieIndex;
                      final radius = isTouched ? 90.0 : 78.0;
                      final percentage =
                      (entry.value / totalSpent * 100);

                      return PieChartSectionData(
                        color: color,
                        value: entry.value,
                        title: percentage >= 8
                            ? '${percentage.toStringAsFixed(0)}%'
                            : '',
                        radius: radius,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        badgeWidget: isTouched
                            ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius:
                            BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color:
                                color.withOpacity(0.4),
                                blurRadius: 6,
                              )
                            ],
                          ),
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        )
                            : null,
                        badgePositionPercentageOffset: 1.3,
                      );
                    }).toList(),
                    pieTouchData: PieTouchData(
                      touchCallback:
                          (FlTouchEvent event, pieTouchResponse) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              pieTouchResponse == null ||
                              pieTouchResponse.touchedSection ==
                                  null) {
                            _touchedPieIndex = -1;
                            return;
                          }
                          _touchedPieIndex = pieTouchResponse
                              .touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    sectionsSpace: 3,
                    centerSpaceRadius: 50,
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                    Text(
                      'Rs ${NumberFormat('#,##0').format(totalSpent)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryLegend(BuildContext context,
      Map<String, double> totals, double totalSpent) {
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: entries.map((entry) {
          final color = AppCategories.getColor(entry.key);
          final percentage = totalSpent == 0
              ? 0.0
              : entry.value / totalSpent;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      AppCategories.getIcon(entry.key),
                      size: 16,
                      color: color,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        entry.key,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      'Rs ${NumberFormat('#,##0').format(entry.value)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(percentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: color.withOpacity(0.12),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 5,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarToggle(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        _ToggleBtn(
          label: 'Last 7 Days',
          isSelected: _barMode == 'weekly',
          onTap: () => setState(() => _barMode = 'weekly'),
        ),
        const SizedBox(width: 8),
        _ToggleBtn(
          label: 'Last 6 Months',
          isSelected: _barMode == 'monthly',
          onTap: () => setState(() => _barMode = 'monthly'),
        ),
      ],
    );
  }

  Widget _buildBarChart(
      BuildContext context, ExpenseProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final isWeekly = _barMode == 'weekly';
    final data = isWeekly
        ? provider.last7DaysSpending
        : _getLast6MonthsSpending(provider);

    final entries = data.entries.toList();
    final maxVal = entries.isEmpty
        ? 100.0
        : entries
        .map((e) => e.value)
        .reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: maxVal == 0 ? 100 : maxVal * 1.25,
            barGroups: entries.asMap().entries.map((e) {
              final index = e.key;
              final value = e.value.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: value == maxVal && maxVal > 0
                        ? scheme.primary
                        : scheme.primary.withOpacity(0.45),
                    width: isWeekly ? 28 : 22,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= entries.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        entries[index].key,
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurface.withOpacity(0.5),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxVal == 0 ? 25 : maxVal / 4,
              getDrawingHorizontalLine: (value) => FlLine(
                color: scheme.onSurface.withOpacity(0.06),
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => scheme.primary,
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    'Rs ${NumberFormat('#,##0').format(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopExpenses(
      BuildContext context, ExpenseProvider provider) {
    final sorted = [...provider.allExpenses]
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final top5 = sorted.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: top5.asMap().entries.map((entry) {
          final index = entry.key;
          final expense = entry.value;
          final color = AppCategories.getColor(expense.category);
          final isLast = index == top5.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    // Rank
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: index == 0
                            ? const Color(0xFFFFD700).withOpacity(0.2)
                            : index == 1
                            ? const Color(0xFFC0C0C0)
                            .withOpacity(0.2)
                            : index == 2
                            ? const Color(0xFFCD7F32)
                            .withOpacity(0.2)
                            : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.06),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: index == 0
                                ? const Color(0xFFB8860B)
                                : index == 1
                                ? Colors.grey.shade600
                                : index == 2
                                ? const Color(0xFF8B4513)
                                : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Icon
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        AppCategories.getIcon(expense.category),
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expense.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('d MMM yyyy')
                                .format(expense.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs ${NumberFormat('#,##0.00').format(expense.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.06),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Map<String, double> _getLast6MonthsSpending(
      ExpenseProvider provider) {
    final Map<String, double> monthly = {};
    final now = DateTime.now();
    for (int i = 5; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM').format(month);
      monthly[key] = 0;
    }
    for (var e in provider.allExpenses) {
      final key = DateFormat('MMM').format(e.date);
      if (monthly.containsKey(key)) {
        monthly[key] = (monthly[key] ?? 0) + e.amount;
      }
    }
    return monthly;
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.chart,
            size: 64,
            color: Theme.of(context)
                .colorScheme
                .primary
                .withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No data to analyze',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add some expenses to see your analytics',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerStat extends StatelessWidget {
  final String label;
  final String value;
  const _BannerStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(
                color: Colors.white60, fontSize: 11)),
      ],
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleBtn(
      {required this.label,
        required this.isSelected,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : scheme.primary,
          ),
        ),
      ),
    );
  }
}