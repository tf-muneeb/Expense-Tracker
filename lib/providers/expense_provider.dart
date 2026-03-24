import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/expense_model.dart';

class ExpenseProvider extends ChangeNotifier {
  static const String _boxName = 'expenses';
  late Box<Expense> _box;

  List<Expense> _expenses = [];
  String _selectedCategory = 'All';
  DateTimeRange? _dateRange;
  String _searchQuery = '';

  List<Expense> get allExpenses => _expenses;
  String get selectedCategory => _selectedCategory;
  DateTimeRange? get dateRange => _dateRange;
  String get searchQuery => _searchQuery;

  List<Expense> get filteredExpenses {
    return _expenses.where((e) {
      final matchesCategory =
          _selectedCategory == 'All' || e.category == _selectedCategory;
      final matchesDate = _dateRange == null ||
          (e.date.isAfter(
              _dateRange!.start.subtract(const Duration(days: 1))) &&
              e.date
                  .isBefore(_dateRange!.end.add(const Duration(days: 1))));
      final matchesSearch = _searchQuery.isEmpty ||
          e.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesDate && matchesSearch;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<Expense> get thisMonthExpenses {
    final now = DateTime.now();
    return _expenses
        .where((e) => e.date.month == now.month && e.date.year == now.year)
        .toList();
  }

  double get thisMonthTotal =>
      thisMonthExpenses.fold(0, (sum, e) => sum + e.amount);

  double get totalAllTime => _expenses.fold(0, (sum, e) => sum + e.amount);

  Map<String, double> get categoryTotals {
    final Map<String, double> totals = {};
    for (var e in thisMonthExpenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, double> get categoryTotalsAllTime {
    final Map<String, double> totals = {};
    for (var e in _expenses) {
      totals[e.category] = (totals[e.category] ?? 0) + e.amount;
    }
    return totals;
  }

  Map<String, double> get last7DaysSpending {
    final Map<String, double> daily = {};
    final now = DateTime.now();
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final key =
          '${day.day}/${day.month}';
      daily[key] = 0;
    }
    for (var e in _expenses) {
      final diff = now.difference(e.date).inDays;
      if (diff <= 6) {
        final key = '${e.date.day}/${e.date.month}';
        daily[key] = (daily[key] ?? 0) + e.amount;
      }
    }
    return daily;
  }

  Future<void> init() async {
    _box = await Hive.openBox<Expense>(_boxName);
    _loadExpenses();
  }

  void _loadExpenses() {
    _expenses = _box.values.toList();
    notifyListeners();
  }

  Future<void> addExpense({
    required String title,
    required double amount,
    required String category,
    required DateTime date,
    String? note,
  }) async {
    final expense = Expense(
      id: const Uuid().v4(),
      title: title,
      amount: amount,
      category: category,
      date: date,
      note: note,
    );
    await _box.put(expense.id, expense);
    _loadExpenses();
  }

  Future<void> updateExpense(Expense expense) async {
    await _box.put(expense.id, expense);
    _loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _box.delete(id);
    _loadExpenses();
  }

  void setCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  void setDateRange(DateTimeRange? range) {
    _dateRange = range;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategory = 'All';
    _dateRange = null;
    _searchQuery = '';
    notifyListeners();
  }
}