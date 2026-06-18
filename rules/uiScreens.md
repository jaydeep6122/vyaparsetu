# UI Screens

## Rule
Every screen is a `StatefulWidget` that loads data in `initState` via a post-frame callback. State is read through `context.select<Core, T>()` or `Selector<Core, T>`.

## Screen Structure

```dart
class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});
  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final businessId = context.read<Core>().business.selectedBusiness?.id;
    if (businessId != null) {
      context.read<Core>().invoice.fetchInvoices(businessId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final businessId = context.select<Core, String?>(
      (c) => c.business.selectedBusiness?.id,
    );

    return Scaffold(
      body: Selector<Core, List<Invoice>>(
        selector: (context, core) => core.invoice.invoices,
        builder: (context, invoices, child) {
          if (invoices.isEmpty) {
            return const LoadingIndicator();
          }
          return RefreshIndicator(
            onRefresh: () async {
              if (businessId != null) {
                await context.read<Core>().invoice.fetchInvoices(businessId);
              }
            },
            child: ListView.builder(
              itemCount: invoices.length,
              itemBuilder: (context, index) => Text(invoices[index].name),
            ),
          );
        },
      ),
    );
  }
}
```

## Data Loading Patterns

| When | How |
|---|---|
| Screen opens | `initState` → `addPostFrameCallback` → `context.read<Core>()` |
| Pull-to-refresh | `RefreshIndicator.onRefresh` → `context.read<Core>()` (or `Selector` builder) |
| After mutation (navigate back) | `.then((_) { if (mounted) _loadData(); })` after `Navigator.push` |
| Button tap / event | Direct `context.read<Core>().module.method()` |

## Navigation

```dart
// Push new screen
Navigator.of(context).push(getPageRoute(const InvoiceDetailScreen(invoice: inv)));

// Push and reload on return
Navigator.of(context).push(getPageRoute(const InvoiceFormScreen())).then((_) {
  if (mounted) _loadData();
});

// Replace current screen
Navigator.of(context).pushReplacement(getPageRoute(const HomeScreen()));

// Clear stack and push (after login/logout)
navigatorKey.currentState?.pushAndRemoveUntil(
  getPageRoute(const LoginScreen()),
  (route) => false,
);
```

## DO
- Use `context.read<Core>()` in `initState`, callbacks, and event handlers
- Use `context.select<Core, T>()` in `build()` for granular rebuilds
- Use `Selector<Core, T>(selector:builder:)` when the build method watches a specific Core value
- Check `mounted` before `setState` or `Navigator` calls after `async` operations
- Use `try/catch` around `context.read<Core>().module.method()` calls in event handlers
- Use `getPageRoute()` from `helpers/navigation.dart` for consistent transitions

## DON'T
- Use `context.watch<Core>()` — always use `context.select` or `Selector`
- Use `Consumer<Core>()` — use `Selector<Core, T>()` or `context.select<Core, T>()` instead
- Call `Api.instance` directly from screens
- Use named routes — always use imperative `Navigator.push(getPageRoute(...))`
- Use `Provider.of<XxxProvider>` — always go through `Core`
- Forget to check `mounted` after async work
