import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/types/expense.dart';
import 'package:vyaparsetu/core/Core.dart';
import 'package:vyaparsetu/helpers/errorHandler.dart';

class ExpenseModule {
  final Core core;
  ExpenseModule(this.core);

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  bool _hasFetched = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<List<Expense>> fetchExpenses(
    String businessId, {
    String? expenseCategory,
    String? fromDate,
    String? toDate,
    String? search,
    bool forceRefresh = false,
  }) async {
    final isFiltered =
        expenseCategory != null ||
        fromDate != null ||
        toDate != null ||
        search != null;

    if (!isFiltered) {
      if (_hasFetched && !forceRefresh) {
        return _expenses;
      }

      _isLoading = true;
      _error = null;
      core.notify();

      try {
        final list = await Api.instance.expense.list(businessId);
        _expenses = list.map((e) => Expense.fromJson(e)).toList();
        _hasFetched = true;
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return _expenses;
    } else {
      _isLoading = true;
      _error = null;
      core.notify();

      List<Expense> results = [];
      try {
        final list = await Api.instance.expense.list(
          businessId,
          expenseCategory: expenseCategory,
          fromDate: fromDate,
          toDate: toDate,
          search: search,
        );
        results = list.map((e) => Expense.fromJson(e)).toList();
      } catch (e) {
        _error = extractErrorMessage(e);
      }

      _isLoading = false;
      core.notify();
      return results;
    }
  }

  Future<bool> createExpense(
    String businessId,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      final response = await Api.instance.expense.create(businessId, data);
      final newExpense = Expense.fromJson(response);
      _expenses.insert(0, newExpense);
      _expenses = List.from(_expenses);
      _isLoading = false;
      core.notify();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<bool> updateExpense(
    String businessId,
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.expense.update(businessId, expenseId, data);

      final idx = _expenses.indexWhere((e) => e.id == expenseId);
      if (idx != -1) {
        final oldExpense = _expenses[idx];
        final existingMap = oldExpense.toJson();
        data.forEach((key, value) {
          existingMap[key] = value;
        });
        _expenses[idx] = Expense.fromJson(existingMap);
        _expenses = List.from(_expenses);
      }

      _isLoading = false;
      core.notify();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  Future<bool> deleteExpense(String businessId, String expenseId) async {
    _isLoading = true;
    _error = null;
    core.notify();

    try {
      await Api.instance.expense.delete(businessId, expenseId);
      _expenses.removeWhere((e) => e.id == expenseId);
      _expenses = List.from(_expenses);
      _isLoading = false;
      core.notify();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notify();
    return false;
  }

  void clearAll() {
    _expenses = [];
    _isLoading = false;
    _error = null;
    _hasFetched = false;
    core.notify();
  }
}
