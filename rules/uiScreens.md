# UI Screens

## Rule
Screens are `StatefulWidget`s that load in a post-frame callback, read state
from `Core`, and show `LoadStateBody` / `PagedListView` instead of hand-rolled
loading and empty states.

## List screen

```dart
class PartyListScreen extends StatefulWidget {
  const PartyListScreen({super.key});
  @override
  State<PartyListScreen> createState() => _PartyListScreenState();
}

class _PartyListScreenState extends State<PartyListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<Core>().party.fetchParties(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final core = context.watch<Core>();
    final parties = core.party;
    scheduleReload(parties.list.needsReload, () => parties.fetchParties(refresh: true));

    return Scaffold(
      appBar: AppBar(title: Text('tab_parties'.tr())),
      floatingActionButton: FloatingActionButton.extended(...),
      body: PagedListView<Party>(
        items: parties.list.items,
        isLoading: parties.list.isLoading,
        isLoadingMore: parties.list.isLoadingMore,
        hasMore: parties.list.data.hasMore,
        error: parties.list.error,
        onRefresh: () => parties.fetchParties(refresh: true),
        onLoadMore: parties.loadMore,
        itemBuilder: (context, party) => PartyTile(party: party),
        emptyState: EmptyState(...),
      ),
    );
  }
}
```

## Detail screen

Load with `getX(id, refresh: true)`, render with
`LoadStateBody<T>(state: …, onRetry: …, builder: …)`, and keep the `AppBar`
outside it so actions show while loading. Call
`scheduleReload(state.needsReload, _refresh)` in `build` so a change made
elsewhere (a payment, a cancellation) refreshes the screen.

## Form screen

- `Form` + `GlobalKey<FormState>`, controllers created with `late final`.
- `FormSection` groups fields; `SelectField` / `DateField` / `SwitchRow` /
  `ChoiceChipsField` for anything that is not free text.
- Validate with `Validators.*`; restrict typing with `DecimalInputFormatter`
  and `UpperCaseTextFormatter`.
- Build a snake_case map, call the module, and on `null` show
  `showErrorToast(module.error ?? 'error_generic'.tr())`.
- Save button sits in `bottomNavigationBar` with `isSaving` from
  `context.select`.
- Pop the saved object so the caller can use it (pickers rely on this).

## Navigation

```dart
Navigator.of(context).push(getPageRoute(PartyDetailScreen(partyId: id)));
Navigator.of(context).pushAndRemoveUntil(getPageRoute(const HomeScreen()), (_) => false);
```

`openAfterSignIn(context)` decides between onboarding, the business list and
the home shell after sign-in. Tabs are switched with
`HomeScreenState.of(context)?.setTab(1)`.

## DO
- Grab `Navigator` / module references before an `await`, and check `mounted`
  after it
- Gate destructive or restricted actions with `core.can(MemberRole.x)`
- Confirm cancellations with `showReasonDialog` (the reason goes to the server)

## DON'T
- Rebuild loading, empty or error UI by hand
- Keep server-derived numbers in `setState` — read them from the module
- Use named routes or `Provider.of`
