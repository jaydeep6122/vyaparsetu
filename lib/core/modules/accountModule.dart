import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/account.dart';
import 'package:vyaparsetu/types/reports.dart';

/// Cash and bank accounts, their books, and transfers between them.
class AccountModule extends CoreModule {
  AccountModule(super.core);

  /// Includes archived accounts.
  final LoadState<List<Account>> accounts = LoadState();
  final PagedState<Transfer> transfers = PagedState();
  final Map<String, LoadState<Ledger>> _books = {};

  LoadState<Ledger> book(String accountId) =>
      _books.putIfAbsent(accountId, LoadState.new);

  List<Account> get activeAccounts =>
      (accounts.value ?? []).where((account) => !account.isArchived).toList();

  /// Where "paid now" money goes by default: the default cash account.
  Account? get defaultAccount {
    final active = activeAccounts;
    return active
            .where((a) => a.accountType == AccountType.cash && a.isDefault)
            .firstOrNull ??
        active.firstOrNull;
  }

  Future<List<Account>?> fetchAccounts({bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      accounts,
      () async => (await Api.instance.account.list(
        businessId,
        includeArchived: true,
      ))
          .map(Account.fromJson)
          .toList(),
      refresh: refresh,
    );
  }

  Future<Ledger?> fetchBook(
    String accountId, {
    DateTime? from,
    DateTime? to,
    bool refresh = false,
  }) {
    final businessId = core.businessId;
    return loadValue(
      book(accountId),
      () async => Ledger.accountFromJson(
        await Api.instance.account.book(
          businessId,
          accountId,
          from: from == null ? null : apiDate(from),
          to: to == null ? null : apiDate(to),
        ),
      ),
      refresh: refresh,
    );
  }

  Future<Account?> createAccount(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.account.create(core.businessId, data),
    );
    return json == null ? null : _saved(Account.fromJson(json));
  }

  Future<Account?> updateAccount(
    String accountId,
    Map<String, dynamic> data,
  ) async {
    final json = await runSave(
      () => Api.instance.account.update(core.businessId, accountId, data),
    );
    return json == null ? null : _saved(Account.fromJson(json));
  }

  Future<Account?> setArchived(String accountId, {required bool archived}) async {
    final json = await runSave(
      () => Api.instance.account.setArchived(
        core.businessId,
        accountId,
        archived: archived,
      ),
    );
    return json == null ? null : _saved(Account.fromJson(json));
  }

  Account _saved(Account account) {
    book(account.id).stale = true;
    fetchAccounts(refresh: true);
    core.report.markStale();
    return account;
  }

  Future<void> fetchTransfers({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      transfers,
      fetch: (offset) => Api.instance.transfer.list(
        businessId,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Transfer.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<Transfer?> createTransfer(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.transfer.create(core.businessId, data),
    );
    if (json == null) return null;
    core.markBooksChanged();
    fetchAccounts();
    return Transfer.fromJson(json);
  }

  Future<bool> cancelTransfer(String transferId, {String? reason}) async {
    final json = await runSave(
      () => Api.instance.transfer.cancel(
        core.businessId,
        transferId,
        reason: reason,
      ),
    );
    if (json == null) return false;
    core.markBooksChanged();
    fetchTransfers();
    fetchAccounts();
    return true;
  }

  void markStale() {
    accounts.stale = true;
    transfers.stale = true;
    for (final state in _books.values) {
      state.stale = true;
    }
  }

  void clear() {
    accounts.reset();
    transfers.reset();
    _books.clear();
  }
}
