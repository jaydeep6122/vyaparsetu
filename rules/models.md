# Models

## Rule
Types in `lib/types/` are immutable and built from the API's snake_case JSON
with the helpers in `helpers/json.dart`. They carry no business logic beyond
small read-only getters.

## Model pattern

```dart
class Party {
  final String id;
  final String name;
  final PartyType partyType;
  final String? gstin;

  /// Positive: the party owes the business. Negative: the business owes them.
  final double balance;
  final DateTime? archivedAt;

  const Party({
    required this.id,
    required this.name,
    required this.partyType,
    this.gstin,
    required this.balance,
    this.archivedAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) => Party(
    id: json['id'] as String,
    name: asString(json['name']),
    partyType: PartyType.fromString(json['party_type'] as String?),
    gstin: json['gstin'] as String?,
    balance: asDouble(json['balance']),
    archivedAt: asDate(json['archived_at']),
  );

  bool get isArchived => archivedAt != null;
  bool get isSettled => balance.abs() < 0.005;
}
```

- `asDouble`, `asInt`, `asBool`, `asString`, `asDate`, `asMap`, `asMapList`
  accept numbers or strings, which is what the API sends for money.
- `toJson()` only exists where something is cached or sent back
  (`Business`, `User`, `Address`, `PaymentAllocation`).
- `copyWith` only where a screen actually needs it — most edits go to the
  server and come back fresh.
- `Paged<T>` (`types/paged.dart`) holds `items`, `total`, `hasMore`.

## Enums

All API enums live in `global/constants.dart` as enhanced enums with
`value` (wire string), `fromString` (falls back to a safe default) and
`displayName` (`'party_type_$value'.tr()`):

`GstRegistrationType`, `PartyType`, `PartyGstType`, `BalanceType`, `ItemType`,
`InvoiceType`, `TaxMode`, `InvoiceStatus`, `PaymentStatus`, `PaymentDirection`,
`PaymentMode`, `RecordStatus`, `AccountType`, `ChargeType`, `ChargeBillTo`,
`TransportMode`, `MemberRole`, `AdjustmentReason`, `LedgerSource`, plus the
app-side `CategoryKind`, `OutstandingType` and `BillDesign`.

Useful members: `InvoiceType.isSaleSide` / `isReturn` / `paymentDirection`,
`PartyType.canSell` / `canBuy`, `PartyGstType.needsGstin`,
`MemberRole.atLeast(...)`.

## DO
- Keep every field `final` and named
- Parse through `helpers/json.dart` instead of raw casts on numbers and dates
- Document sign conventions (party balance, account opening balance)
- Add a new enum value in `constants.dart` **and** its `en.json` key

## DON'T
- Compute totals, tax or balances in a model
- Use `camelCase` JSON keys
- Parse an enum as a raw string
