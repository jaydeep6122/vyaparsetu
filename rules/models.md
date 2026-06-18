# Models

## Rule
All data models are immutable classes with `fromJson`/`toJson`/`copyWith`. JSON keys use `snake_case` to match the API.

## Model Pattern

```dart
class Invoice {
  final String id;
  final InvoiceType invoiceType;
  final String invoiceNumber;
  final String? partyId;
  final String? partyName;
  final List<InvoiceItem> items;
  final double subtotal;
  final double discount;
  final double taxAmount;
  final double total;
  final PaymentStatus paymentStatus;
  final DateTime createdAt;

  const Invoice({
    required this.id,
    required this.invoiceType,
    required this.invoiceNumber,
    this.partyId,
    this.partyName,
    required this.items,
    required this.subtotal,
    required this.discount,
    required this.taxAmount,
    required this.total,
    required this.paymentStatus,
    required this.createdAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      invoiceType: InvoiceType.fromString(json['invoice_type'] as String),
      invoiceNumber: json['invoice_number'] as String,
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String?,
      items: (json['items'] as List)
          .map((e) => InvoiceItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num).toDouble(),
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'invoice_type': invoiceType.value,
    'invoice_number': invoiceNumber,
    'party_id': partyId,
    'party_name': partyName,
    'items': items.map((e) => e.toJson()).toList(),
    'subtotal': subtotal,
    'discount': discount,
    'tax_amount': taxAmount,
    'total': total,
    'payment_status': paymentStatus.value,
    'created_at': createdAt.toIso8601String(),
  };

  Invoice copyWith({
    String? id,
    InvoiceType? invoiceType,
    String? invoiceNumber,
    String? partyId,
    String? partyName,
    List<InvoiceItem>? items,
    double? subtotal,
    double? discount,
    double? taxAmount,
    double? total,
    PaymentStatus? paymentStatus,
    DateTime? createdAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceType: invoiceType ?? this.invoiceType,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
```

## Enums

Defined in `lib/global/constants.dart`:

| Enum | Values |
|---|---|
| `BusinessType` | `retailer`, `wholesaler`, `service` |
| `PartyType` | `customer`, `supplier`, `both` |
| `OpeningBalanceType` | `receive`, `pay` |
| `ItemType` | `product`, `service` |
| `InvoiceType` | `sale`, `purchase` |
| `PaymentStatus` | `paid`, `unpaid`, `partially_paid` |
| `PaymentMode` | `cash`, `bank`, `upi`, `credit`, `multiple` |
| `PaymentType` | `payment_in`, `payment_out` |
| `SupportedLocale` | `en`, `hi`, `gu` |

Each enum has:
- `String get value` — the API wire value
- `factory fromString(String)` — safe deserialization
- `String get displayName` — human-readable label

## DO
- Make all fields `final`
- Use `required` named constructor parameters
- Use safe parsing with `as Type`, `tryParse`, fallback defaults
- Use `snake_case` keys in `toJson()` matching the API
- Define enums in `global/constants.dart`, not in model files
- Use the `.value` getter for serialization, `fromString` for deserialization

## DON'T
- Use mutable fields
- Use positional constructor parameters
- Use `camelCase` JSON keys — API expects `snake_case`
- Parse enums as raw strings — always use the enum's `fromString`
- Use `dynamic` types — cast to concrete types in `fromJson`
