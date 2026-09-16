# State Management

## Rule
One `Core` ChangeNotifier owns every module. The **server is the source of
truth**: modules never recalculate balances, stock or totals — after a change
they mark data stale so it reloads.

## Architecture

```
Core (ChangeNotifier)
├── auth      → AuthModule        ├── account  → AccountModule
├── business  → BusinessModule    ├── invoice  → InvoiceModule
├── member    → MemberModule      ├── payment  → PaymentModule
├── party     → PartyModule       ├── expense  → ExpenseModule
├── item      → ItemModule        ├── stock    → StockModule
├── master    → MasterModule      ├── report   → ReportModule
└── settings  → SettingsModule
```

`core.resetBusinessData()` clears everything when the business changes or the
user signs out. `core.markBooksChanged()` marks parties, items, accounts,
documents and reports stale after money or stock moves.

## CoreModule base (`core/components/moduleBase.dart`)

Every module extends `CoreModule` and gets:

| Member | Purpose |
|---|---|
| `runSave(action)` | Runs a create/update/cancel; returns `null` and sets `error` on failure, toggles `isSaving` |
| `loadPage(state, fetch:, parse:, refresh:, more:)` | Fills a `PagedState<T>`; drops responses that a newer request has superseded |
| `loadValue(state, fetch, refresh:)` | Fills a `LoadState<T>`, reusing the value unless missing, stale or refreshed |

`PagedState<T>` holds `data`, `isLoading`, `isLoadingMore`, `error`, `loaded`,
`stale`, `isFetching`; `LoadState<T>` holds `value` and the same flags. Both
expose `needsReload` — stale, nothing in flight, no error.

## Screens

```dart
// one-off reads: initState, callbacks
context.read<Core>().party.fetchParties();

// a single value in build
final isSaving = context.select<Core, bool>((c) => c.item.isSaving);

// a screen that shows several module values
final core = context.watch<Core>();

// reload data that changed elsewhere
scheduleReload(core.invoice.list.needsReload, () => core.invoice.fetchInvoices(refresh: true));
```

Role checks come from `core/components/getters.dart`:
`core.can(MemberRole.accountant)`, `core.role`, `core.businessId`.

## Module pattern

```dart
class PartyModule extends CoreModule {
  PartyModule(super.core);

  final PagedState<Party> list = PagedState();
  final Map<String, LoadState<Party>> _details = {};

  LoadState<Party> detail(String id) => _details.putIfAbsent(id, LoadState.new);

  Future<void> fetchParties({bool refresh = false, bool more = false}) => loadPage(
    list,
    fetch: (offset) => Api.instance.party.list(core.businessId, offset: offset),
    parse: Party.fromJson,
    refresh: refresh,
    more: more,
  );

  Future<Party?> createParty(Map<String, dynamic> data) async {
    final json = await runSave(() => Api.instance.party.create(core.businessId, data));
    return json == null ? null : _saved(Party.fromJson(json));
  }
}
```

Screens pass plain `Map<String, dynamic>` payloads with snake_case keys; the
module hands them to the API untouched.

## DO
- Extend `CoreModule`; use `runSave` / `loadPage` / `loadValue`
- Show `module.error` in a toast when a save returns null
- Mark stale and refetch instead of patching local state after a write

## DON'T
- Compute balances, stock or invoice totals in the app
- Call `Api.instance` from a screen
- Create `ChangeNotifier`s outside Core
