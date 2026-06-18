# Structure

## Rule
Every file and directory in `lib/` has a designated purpose. No new top-level directories without discussion.

## Directory Layout

```
lib/
  api/                   # HTTP layer
    api.dart             # Api singleton — aggregates all module APIs
    dio.dart             # DioInstance — base URL, interceptors, token refresh
    modules/             # One file per API module
      auth.dart business.dart dashboard.dart expense.dart
      invoice.dart item.dart party.dart payment.dart

  components/            # Reusable UI widgets
    amountDisplay.dart appButton.dart appTextField.dart
    confirmationDialog.dart emptyState.dart errorWidget.dart
    imagePickerWidget.dart loadingIndicator.dart premiumNavBar.dart
    searchBar.dart sectionHeader.dart signaturePadWidget.dart
    statusChip.dart summaryCard.dart

  core/                  # Central state management
    Core.dart            # Single ChangeNotifier — 9 module properties
    modules/             # One file per Core module
      authModule.dart businessModule.dart dashboardModule.dart
      expenseModule.dart invoiceModule.dart itemModule.dart
      partyModule.dart paymentModule.dart settingsModule.dart
    components/          # Core extensions
      computed.dart getters.dart

  extensions/            # Dart extension methods
    dateExtensions.dart stringExtensions.dart

  global/                # App-wide constants and theming
    constants.dart       # Enums (InvoiceType, PaymentMode, etc.) + AppConstants
    themes.dart          # AppTheme — light/dark ThemeData

  helpers/               # Utility functions
    errorHandler.dart formatters.dart logger.dart navigation.dart
    toastNotifications.dart validators.dart

  screens/               # One subdirectory per feature
    auth/                # login.dart, signup.dart
    business/            # list.dart, form.dart, detail.dart
    dashboard/           # dashboard.dart
    expenses/            # list.dart, form.dart, detail.dart
    home/                # home.dart
    invoices/            # list.dart, form.dart, detail.dart, pdfPreview.dart
    items/               # list.dart, form.dart, detail.dart
    parties/             # list.dart, form.dart, detail.dart
    payments/            # list.dart, form.dart
    reports/             # partyLedger.dart, profitLoss.dart
    settings/            # settings.dart
    splash/              # splash.dart

  services/              # Business logic services (e.g., PDF generation)
    invoicePdfService.dart

  storage/               # Local persistence
    hive.dart            # openAllBoxes(), clearBoxes()
    hive/                # One file per Hive box
      cache.dart preferences.dart user.dart
    secureStorage.dart   # flutter_secure_storage for tokens

  types/                 # Data models / types
    business.dart dashboardSummary.dart expense.dart invoice.dart
    invoiceItem.dart item.dart party.dart partyLedger.dart
    payment.dart profitLoss.dart user.dart

  main.dart              # App entry point
```

## DO
- Place screen files in the matching feature directory under `screens/`
- Add reusable widgets to `components/`
- Add helper/utility functions to `helpers/`
- Place business logic services in `services/`

## DON'T
- Create new top-level directories under `lib/` without adding them to this file
- Put API calls in screen files — always go through Core modules
- Create individual provider files — all state goes through `Core`
