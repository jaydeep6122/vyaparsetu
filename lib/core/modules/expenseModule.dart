import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/expense.dart';

class ExpenseModule extends CoreModule {
  ExpenseModule(super.core);

  final PagedState<Expense> list = PagedState();
  String _search = '';
  String? _categoryId;

  String get search => _search;
  String? get categoryId => _categoryId;

  final Map<String, LoadState<Expense>> _details = {};

  LoadState<Expense> detail(String expenseId) =>
      _details.putIfAbsent(expenseId, LoadState.new);

  Future<void> fetchExpenses({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.expense.list(
        businessId,
        search: _search,
        categoryId: _categoryId,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Expense.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchExpenses(more: true);

  Future<void> setFilters({
    String? search,
    String? categoryId,
    bool clearCategory = false,
  }) {
    _search = search ?? _search;
    _categoryId = clearCategory ? null : (categoryId ?? _categoryId);
    return fetchExpenses(refresh: true);
  }

  Future<Expense?> getExpense(String expenseId, {bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      detail(expenseId),
      () async => Expense.fromJson(
        await Api.instance.expense.get(businessId, expenseId),
      ),
      refresh: refresh,
    );
  }

  Future<Expense?> createExpense(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.expense.create(core.businessId, data),
    );
    return json == null ? null : _saved(Expense.fromJson(json));
  }

  /// Replaces the whole expense.
  Future<Expense?> updateExpense(
    String expenseId,
    Map<String, dynamic> data,
  ) async {
    final json = await runSave(
      () => Api.instance.expense.update(core.businessId, expenseId, data),
    );
    return json == null ? null : _saved(Expense.fromJson(json));
  }

  Future<Expense?> cancelExpense(String expenseId, {String? reason}) async {
    final json = await runSave(
      () => Api.instance.expense.cancel(
        core.businessId,
        expenseId,
        reason: reason,
      ),
    );
    return json == null ? null : _saved(Expense.fromJson(json));
  }

  Expense _saved(Expense expense) {
    core.markBooksChanged();
    detail(expense.id)
      ..value = expense
      ..stale = false;
    fetchExpenses(refresh: true);
    return expense;
  }

  void markStale() {
    list.stale = true;
    for (final state in _details.values) {
      state.stale = true;
    }
  }

  void clear() {
    list.reset();
    _details.clear();
    _search = '';
    _categoryId = null;
  }
}
