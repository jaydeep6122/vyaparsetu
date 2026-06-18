# State Management

## Rule
A single `Core` ChangeNotifier owns all application state through 9 module properties. No individual providers.

## Architecture

```
Core (ChangeNotifier)
├── auth        → AuthModule
├── business    → BusinessModule
├── party       → PartyModule
├── item        → ItemModule
├── invoice     → InvoiceModule
├── payment     → PaymentModule
├── expense     → ExpenseModule
├── dashboard   → DashboardModule
└── settings    → SettingsModule
```

Each module stores its own state (`_items`, `_isLoading`, `_error`, etc.) and calls `core.notifyListeners()` after every mutation to trigger UI rebuilds.

## Access from Screens

### Reading once (callbacks, initState, event handlers)
```dart
final core = context.read<Core>();
await core.auth.login(email, password);

// Or inline:
context.read<Core>().business.fetchBusinesses();
```

### Watching specific values (build method, granular rebuilds)
```dart
// Only rebuilds when selectedBusiness changes
final businessId = context.select<Core, String?>(
  (c) => c.business.selectedBusiness?.id,
);

// Only rebuilds when invoice list changes
final invoices = context.select<Core, List<Invoice>>(
  (c) => c.invoice.invoices,
);
```

### Multiple watches in one build (use Selector)
```dart
Selector<Core, List<Invoice>>(
  selector: (context, core) => core.invoice.invoices,
  builder: (context, invoices, child) {
    if (invoices.isEmpty) return const EmptyState(...);
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, index) => Text(invoices[index].name),
    );
  },
)
```

For multiple independent dependencies, use separate `context.select` calls:
```dart
final invoices = context.select<Core, List<Invoice>>((c) => c.invoice.invoices);
final isLoading = context.select<Core, bool>((c) => c.invoice.isLoading);
final error = context.select<Core, String?>((c) => c.invoice.error);
```

### Loading data on screen init
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    context.read<Core>().item.fetchItems(businessId);
  });
}
```

## Module Pattern

```dart
class BusinessModule {
  final Core core;
  BusinessModule(this.core);

  List<Business> _businesses = [];
  bool _isLoading = false;
  String? _error;
  Business? _selectedBusiness;

  List<Business> get businesses => _businesses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Business? get selectedBusiness => _selectedBusiness;

  Future<void> fetchBusinesses() async {
    _isLoading = true;
    _error = null;
    core.notifyListeners();
    try {
      _businesses = await Api.instance.business.getBusinesses();
      _isLoading = false;
      core.notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      core.notifyListeners();
    }
  }
}
```

## DO
- Use `context.read<Core>()` in `initState`, callbacks, and event handlers
- Use `context.select<Core, T>()` in `build()` to subscribe to specific state
- Use `Selector<Core, T>(selector:builder:)` when rebuilding multiple widgets from a Core value
- Use multiple `context.select<Core, T>()` calls for independent watches in `build()`
- Call `core.notifyListeners()` after every state mutation in modules
- Load data inside Core modules via `Api.instance`

## DON'T
- Use `context.watch<Core>()` — use `context.select<Core, T>()` instead
- Use `Consumer<Core>()` — use `Selector<Core, T>()` or `context.select<Core, T>()` instead
- Use `Provider.of<XxxProvider>(context)` — old pattern, removed
- Call `Api.instance` directly from screens — always go through Core modules
- Create new `ChangeNotifier` classes outside of Core modules
