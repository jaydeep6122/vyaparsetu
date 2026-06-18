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

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchExpenses(
    String businessId, {
    String? expenseCategory,
    String? fromDate,
    String? toDate,
    String? search,
  }) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      final list = await Api.instance.expense.list(
        businessId,
        expenseCategory: expenseCategory,
        fromDate: fromDate,
        toDate: toDate,
        search: search,
      );
      _expenses = list.map((e) => Expense.fromJson(e)).toList();
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
  }

  Future<bool> createExpense(String businessId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.expense.create(businessId, data);
      await fetchExpenses(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  Future<bool> updateExpense(String businessId, String expenseId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.expense.update(businessId, expenseId, data);
      await fetchExpenses(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  Future<bool> deleteExpense(String businessId, String expenseId) async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();

    try {
      await Api.instance.expense.delete(businessId, expenseId);
      await fetchExpenses(businessId);
      _isLoading = false;
      core.notifyListeners();
      return true;
    } catch (e) {
      _error = extractErrorMessage(e);
    }

    _isLoading = false;
    core.notifyListeners();
    return false;
  }

  void clearAll() {
    _expenses = [];
    _isLoading = false;
    _error = null;
    core.notifyListeners();
  }
}
