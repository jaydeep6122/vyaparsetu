import 'package:vyaparsetu/api/api.dart';
import 'package:vyaparsetu/core/components/getters.dart';
import 'package:vyaparsetu/core/components/moduleBase.dart';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/party.dart';
import 'package:vyaparsetu/types/reports.dart';

class PartyModule extends CoreModule {
  PartyModule(super.core);

  final PagedState<Party> list = PagedState();
  String _search = '';
  PartyType? _typeFilter;

  String get search => _search;
  PartyType? get typeFilter => _typeFilter;

  final Map<String, LoadState<Party>> _details = {};
  final Map<String, LoadState<Ledger>> _ledgers = {};

  LoadState<Party> detail(String partyId) =>
      _details.putIfAbsent(partyId, LoadState.new);

  LoadState<Ledger> ledger(String partyId) =>
      _ledgers.putIfAbsent(partyId, LoadState.new);

  Future<void> fetchParties({bool refresh = false, bool more = false}) {
    final businessId = core.businessId;
    return loadPage(
      list,
      fetch: (offset) => Api.instance.party.list(
        businessId,
        search: _search,
        partyType: _typeFilter?.value,
        limit: AppConstants.pageSize,
        offset: offset,
      ),
      parse: Party.fromJson,
      refresh: refresh,
      more: more,
    );
  }

  Future<void> loadMore() => fetchParties(more: true);

  /// `customer` and `supplier` filters include parties marked `both`.
  Future<void> setFilters({String? search, PartyType? type, bool clearType = false}) {
    _search = search ?? _search;
    _typeFilter = clearType ? null : (type ?? _typeFilter);
    return fetchParties(refresh: true);
  }

  Future<Party?> getParty(String partyId, {bool refresh = false}) {
    final businessId = core.businessId;
    return loadValue(
      detail(partyId),
      () async => Party.fromJson(await Api.instance.party.get(businessId, partyId)),
      refresh: refresh,
    );
  }

  Future<Ledger?> fetchLedger(
    String partyId, {
    DateTime? from,
    DateTime? to,
    bool refresh = false,
  }) {
    final businessId = core.businessId;
    return loadValue(
      ledger(partyId),
      () async => Ledger.partyFromJson(
        await Api.instance.party.ledger(
          businessId,
          partyId,
          from: from == null ? null : apiDate(from),
          to: to == null ? null : apiDate(to),
        ),
      ),
      refresh: refresh,
    );
  }

  /// Quick lookup for pickers, without touching the main list.
  Future<List<Party>> searchParties(String query, {PartyType? type}) async {
    try {
      final page = await Api.instance.party.list(
        core.businessId,
        search: query,
        partyType: type?.value,
        limit: 30,
      );
      return page.items.map(Party.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Party?> createParty(Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.party.create(core.businessId, data),
    );
    return json == null ? null : _saved(Party.fromJson(json));
  }

  /// Only the fields sent are changed; null clears a field.
  Future<Party?> updateParty(String partyId, Map<String, dynamic> data) async {
    final json = await runSave(
      () => Api.instance.party.update(core.businessId, partyId, data),
    );
    return json == null ? null : _saved(Party.fromJson(json));
  }

  Future<Party?> setArchived(String partyId, {required bool archived}) async {
    final json = await runSave(
      () => Api.instance.party.setArchived(
        core.businessId,
        partyId,
        archived: archived,
      ),
    );
    return json == null ? null : _saved(Party.fromJson(json));
  }

  Party _saved(Party party) {
    detail(party.id)
      ..value = party
      ..stale = false;
    ledger(party.id).stale = true;
    list.stale = true;
    fetchParties();
    core.report.markStale();
    return party;
  }

  void markStale() {
    list.stale = true;
    for (final state in _details.values) {
      state.stale = true;
    }
    for (final state in _ledgers.values) {
      state.stale = true;
    }
  }

  void clear() {
    list.reset();
    _details.clear();
    _ledgers.clear();
    _search = '';
    _typeFilter = null;
  }
}
