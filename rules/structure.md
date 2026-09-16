# Structure

## Rule
Every file and directory in `lib/` has a designated purpose. No new top-level
directories without adding them here.

## Directory layout

```
lib/
  api/                   # HTTP layer
    api.dart             # Api singleton — one property per module
    dio.dart             # DioInstance — base URL, auth header, token refresh
    response.dart        # dataOf / listOf / PageJson / queryOf / businessPath
    modules/             # auth business member party item master account
                         # invoice payment expense transfer stock report

  components/            # Reusable widgets (see rules/uiComponents.md)

  core/                  # State
    Core.dart            # Single ChangeNotifier owning every module
    components/
      moduleBase.dart    # CoreModule, PagedState, LoadState
      getters.dart       # businessId, role, can(...)
    modules/             # authModule businessModule memberModule partyModule
                         # itemModule masterModule accountModule invoiceModule
                         # paymentModule expenseModule stockModule reportModule
                         # settingsModule

  extensions/            # dateExtensions.dart, stringExtensions.dart

  global/
    constants.dart       # API enums with value/fromString/displayName + AppConstants
    themes.dart          # AppColors theme extension, AppTheme, context.colors

  helpers/
    errorHandler.dart userFriendlyErrors.dart   # server errors → readable text
    json.dart            # asDouble/asInt/asDate/apiDate parsing helpers
    formatters.dart validators.dart inputFormatters.dart
    gst.dart             # state codes, place of supply
    imageData.dart       # picked image → data URI
    datePicker.dart navigation.dart toastNotifications.dart
    crashReporting.dart logger.dart

  screens/               # One directory per feature
    accounts/            # list.dart, form.dart, book.dart, transfers.dart
    auth/                # login.dart, signup.dart, forgotPassword.dart,
                         # authLayout.dart, sessionRouter.dart
    business/            # list.dart, form.dart, team.dart, documentSeries.dart,
                         # joinBusiness.dart
    common/              # pickers.dart, ledgerView.dart
    dashboard/           # dashboard.dart
    expenses/ invoices/ items/ parties/ payments/   # list/form/detail (+ widgets.dart)
    masters/             # taxRates.dart, categories.dart
    more/                # more.dart, profile.dart, changePassword.dart
    reports/             # reportCenter, outstanding, profitLoss, gstSummary,
                         # dayBook, stockSummary
    stock/               # list.dart, form.dart, detail.dart
    home/ splash/

  services/
    invoicePdfService.dart

  storage/
    hive.dart            # openAllBoxes(), clearBoxes()
    hive/                # cache.dart, preferences.dart, user.dart
    secure_storage.dart  # tokens

  types/                 # address business user member party item account
                         # invoice payment expense stockAdjustment reports paged

  main.dart
```

Screen-only widgets live in a `widgets.dart` next to the screen
(`screens/invoices/widgets.dart` → `InvoiceTile`). Anything used by two
features moves to `components/` or `screens/common/`.

## DO
- Put a new screen in its feature directory as `list/form/detail.dart`
- Keep API calls in `core/modules`, parsing in `types/`
- Add shared pickers to `screens/common/pickers.dart`

## DON'T
- Add a top-level directory without updating this file
- Call `Api.instance` from a screen
- Create provider classes outside `Core`
