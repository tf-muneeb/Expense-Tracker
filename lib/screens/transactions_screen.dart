import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../utils/constants.dart';
import '../widgets/expense_tile.dart';
import 'add_edit_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final scheme = Theme.of(context).colorScheme;
    final filtered = provider.filteredExpenses;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        title: _showSearch
            ? TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search expenses...',
            border: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: provider.setSearchQuery,
        )
            : const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Iconsax.close_circle : Iconsax.search_normal),
            onPressed: () {
              setState(() => _showSearch = !_showSearch);
              if (!_showSearch) {
                _searchController.clear();
                provider.setSearchQuery('');
              }
            },
          ),
          IconButton(
            icon: Stack(
              children: [
                const Icon(Iconsax.filter),
                if (provider.selectedCategory != 'All' ||
                    provider.dateRange != null)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterSheet(context, provider),
          ),
        ],
      ),
      body: Column(
        children: [
          if (provider.selectedCategory != 'All' ||
              provider.dateRange != null)
            _buildActiveFilters(context, provider),

          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${filtered.length} expense${filtered.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: scheme.onSurface.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (filtered.isNotEmpty)
                  Text(
                    'Total: Rs ${NumberFormat('#,##0.00').format(filtered.fold(0.0, (s, e) => s + e.amount))}',
                    style: TextStyle(
                      fontSize: 13,
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, provider)
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final expense = filtered[index];
                final showDateHeader = index == 0 ||
                    !_isSameDay(
                        filtered[index - 1].date, expense.date);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showDateHeader)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                            4, 16, 4, 8),
                        child: Text(
                          _formatDateHeader(expense.date),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: scheme.onSurface
                                .withOpacity(0.45),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ExpenseTile(expense: expense),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddEditScreen()),
        ),
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Iconsax.add),
      ),
    );
  }
  Widget _buildActiveFilters(
      BuildContext context, ExpenseProvider provider) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          if (provider.selectedCategory != 'All')
            _FilterChip(
              label: provider.selectedCategory,
              color: AppCategories.getColor(provider.selectedCategory),
              onRemove: () => provider.setCategory('All'),
            ),
          if (provider.dateRange != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: _FilterChip(
                label:
                '${DateFormat('d MMM').format(provider.dateRange!.start)} - ${DateFormat('d MMM').format(provider.dateRange!.end)}',
                color: scheme.primary,
                onRemove: () => provider.setDateRange(null),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: provider.clearFilters,
            child: const Text('Clear all'),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ExpenseProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _FilterSheet(provider: provider),
    );
  }

  Widget _buildEmptyState(BuildContext context, ExpenseProvider provider) {
    final hasFilters = provider.selectedCategory != 'All' ||
        provider.dateRange != null ||
        provider.searchQuery.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Iconsax.search_normal : Iconsax.receipt_item,
            size: 56,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters ? 'No results found' : 'No transactions yet',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          if (hasFilters) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: provider.clearFilters,
              child: const Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    if (_isSameDay(date, now)) return 'TODAY';
    if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      return 'YESTERDAY';
    }
    return DateFormat('EEEE, d MMMM').format(date).toUpperCase();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.color,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final ExpenseProvider provider;
  const _FilterSheet({required this.provider});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _category;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _category = widget.provider.selectedCategory;
    _dateRange = widget.provider.dateRange;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'Filter Expenses',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 20),

          Text('Category',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              'All',
              ...AppCategories.names,
            ].map((cat) {
              final isSelected = cat == _category;
              final color = cat == 'All'
                  ? scheme.primary
                  : AppCategories.getColor(cat);
              return GestureDetector(
                onTap: () => setState(() => _category = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                    isSelected ? color : color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? color
                          : color.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : color,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          Text('Date Range',
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.6))),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                initialDateRange: _dateRange,
              );
              if (picked != null) setState(() => _dateRange = picked);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: scheme.brightness == Brightness.light
                    ? const Color(0xFFF5F5F5)
                    : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Iconsax.calendar,
                      size: 18,
                      color: scheme.onSurface.withOpacity(0.5)),
                  const SizedBox(width: 10),
                  Text(
                    _dateRange == null
                        ? 'Select date range'
                        : '${DateFormat('d MMM yyyy').format(_dateRange!.start)}  →  ${DateFormat('d MMM yyyy').format(_dateRange!.end)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _dateRange == null
                          ? scheme.onSurface.withOpacity(0.4)
                          : scheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (_dateRange != null)
                    GestureDetector(
                      onTap: () => setState(() => _dateRange = null),
                      child: Icon(Icons.close,
                          size: 16,
                          color: scheme.onSurface.withOpacity(0.4)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                widget.provider.setCategory(_category);
                widget.provider.setDateRange(_dateRange);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters'),
            ),
          ),
        ],
      ),
    );
  }
}