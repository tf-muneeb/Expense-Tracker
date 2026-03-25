import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final expenseProvider = context.watch<ExpenseProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          _buildStatsCard(context, expenseProvider),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Appearance'),
          const SizedBox(height: 8),
          _buildCard(context, [
            _SettingsTile(
              icon: themeProvider.isDarkMode ? Iconsax.sun : Iconsax.moon,
              iconColor: themeProvider.isDarkMode
                  ? const Color(0xFFFFA726)
                  : const Color(0xFF5C6BC0),
              title: 'Dark Mode',
              subtitle: themeProvider.isDarkMode ? 'On' : 'Off',
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (_) => themeProvider.toggleTheme(),
                activeColor: scheme.primary,
              ),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Data'),
          const SizedBox(height: 8),
          _ExpandableDataCard(provider: expenseProvider),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Categories Overview'),
          const SizedBox(height: 8),
          _buildCategoriesOverview(context, expenseProvider),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Danger Zone'),
          const SizedBox(height: 8),
          _buildCard(context, [
            _SettingsTile(
              icon: Iconsax.trash,
              iconColor: Colors.red,
              title: 'Clear All Data',
              subtitle: 'Permanently delete all expenses',
              trailing: Icon(
                Iconsax.arrow_right,
                size: 16,
                color: scheme.onSurface.withOpacity(0.3),
              ),
              onTap: () => _confirmClearAll(context, expenseProvider),
            ),
          ]),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'About'),
          const SizedBox(height: 8),
          _buildCard(context, [
            _SettingsTile(
              icon: Iconsax.info_circle,
              iconColor: const Color(0xFF7B1FA2),
              title: 'App Version',
              subtitle: '1.0.0',
              trailing: const SizedBox.shrink(),
            ),
            _buildDivider(context),
            _SettingsTile(
              icon: Iconsax.mobile,
              iconColor: const Color(0xFF2E7D32),
              title: 'Built With Flutter',
              subtitle: 'Provider • Hive • fl_chart',
              trailing: const SizedBox.shrink(),
            ),
          ]),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Expense Tracker v1.0.0\nBuilt by Muneeb Mustafa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: scheme.onSurface.withOpacity(0.5),
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, ExpenseProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final monthName = DateFormat('MMMM').format(now);

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
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.wallet, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Expense Tracker',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$monthName · ${provider.allExpenses.length} total expenses',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesOverview(
      BuildContext context, ExpenseProvider provider) {
    final totals = provider.categoryTotalsAllTime;
    if (totals.isEmpty) {
      return _buildCard(context, [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No data yet',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ),
      ]);
    }

    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildCard(
      context,
      sorted.asMap().entries.map((entry) {
        final index = entry.key;
        final e = entry.value;
        final color = AppCategories.getColor(e.key);
        final isLast = index == sorted.length - 1;
        return Column(
          children: [
            _SettingsTile(
              icon: AppCategories.getIcon(e.key),
              iconColor: color,
              title: e.key,
              subtitle: 'Rs ${NumberFormat('#,##0.00').format(e.value)}',
              trailing: Text(
                '${(e.value / provider.totalAllTime * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            if (!isLast) _buildDivider(context),
          ],
        );
      }).toList(),
    );
  }

  void _confirmClearAll(BuildContext context, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear All Data'),
        content: const Text(
            'This will permanently delete ALL your expenses. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              for (var expense in [...provider.allExpenses]) {
                await provider.deleteExpense(expense.id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('All data cleared'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      indent: 56,
      endIndent: 16,
      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    subtitle,
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
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _ExpandableDataCard extends StatefulWidget {
  final ExpenseProvider provider;
  const _ExpandableDataCard({required this.provider});

  @override
  State<_ExpandableDataCard> createState() => _ExpandableDataCardState();
}

class _ExpandableDataCardState extends State<_ExpandableDataCard> {
  bool _totalExpanded = false;
  bool _allTimeExpanded = false;
  bool _monthExpanded = false;

  @override
  Widget build(BuildContext context) {
    final expenseProvider = widget.provider;

    return Column(
      children: [
        _buildExpandableItem(
          context: context,
          icon: Iconsax.chart_2,
          iconColor: const Color(0xFF26A69A),
          title: 'Total Expenses',
          subtitle: '${expenseProvider.allExpenses.length} records',
          isExpanded: _totalExpanded,
          onTap: () => setState(() => _totalExpanded = !_totalExpanded),
          expandedContent: expenseProvider.allExpenses.isEmpty
              ? _emptyChip(context, 'No expenses added yet')
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                context,
                'This Month',
                '${expenseProvider.thisMonthExpenses.length} expenses',
                const Color(0xFF26A69A),
              ),
              _infoChip(
                context,
                'All Time',
                '${expenseProvider.allExpenses.length} expenses',
                const Color(0xFF26A69A),
              ),
              _infoChip(
                context,
                'Categories Used',
                '${expenseProvider.categoryTotalsAllTime.keys.length} of 7',
                const Color(0xFF26A69A),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        _buildExpandableItem(
          context: context,
          icon: Iconsax.money,
          iconColor: const Color(0xFF2E7D32),
          title: 'Total Spent (All Time)',
          subtitle:
          'Rs ${NumberFormat('#,##0.00').format(expenseProvider.totalAllTime)}',
          isExpanded: _allTimeExpanded,
          onTap: () => setState(() => _allTimeExpanded = !_allTimeExpanded),
          expandedContent: expenseProvider.allExpenses.isEmpty
              ? _emptyChip(context, 'No data yet')
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: expenseProvider.categoryTotalsAllTime.entries
                .map((e) => _infoChip(
              context,
              e.key,
              'Rs ${NumberFormat('#,##0').format(e.value)}',
              AppCategories.getColor(e.key),
            ))
                .toList(),
          ),
        ),

        const SizedBox(height: 8),

        _buildExpandableItem(
          context: context,
          icon: Iconsax.calendar_1,
          iconColor: const Color(0xFF1976D2),
          title: 'This Month',
          subtitle:
          'Rs ${NumberFormat('#,##0.00').format(expenseProvider.thisMonthTotal)}',
          isExpanded: _monthExpanded,
          onTap: () => setState(() => _monthExpanded = !_monthExpanded),
          expandedContent: expenseProvider.thisMonthExpenses.isEmpty
              ? _emptyChip(context, 'No expenses this month')
              : Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _infoChip(
                context,
                'Transactions',
                '${expenseProvider.thisMonthExpenses.length}',
                const Color(0xFF1976D2),
              ),
              _infoChip(
                context,
                'Daily Average',
                'Rs ${NumberFormat('#,##0').format(expenseProvider.thisMonthTotal / DateTime.now().day)}',
                const Color(0xFF1976D2),
              ),
              _infoChip(
                context,
                'Highest',
                expenseProvider.thisMonthExpenses.isEmpty
                    ? 'N/A'
                    : 'Rs ${NumberFormat('#,##0').format(expenseProvider.thisMonthExpenses.map((e) => e.amount).reduce((a, b) => a > b ? a : b))}',
                const Color(0xFF1976D2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget expandedContent,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Iconsax.arrow_right,
                      size: 16,
                      color: isExpanded
                          ? iconColor
                          : scheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    color: scheme.onSurface.withOpacity(0.08),
                  ),
                  const SizedBox(height: 12),
                  expandedContent,
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoChip(
      BuildContext context, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyChip(BuildContext context, String message) {
    return Text(
      message,
      style: TextStyle(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
      ),
    );
  }
}