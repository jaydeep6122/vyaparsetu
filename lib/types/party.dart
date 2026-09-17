import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/address.dart';

/// One of a party's saved billing or shipping addresses.
class PartyAddress {
  /// Null until the address has been saved.
  final String? id;
  final AddressKind kind;

  /// A name to tell addresses apart: "Head office", "Warehouse".
  final String? label;
  final Address address;

  /// Picked automatically on a new bill.
  final bool isDefault;

  const PartyAddress({
    this.id,
    required this.kind,
    this.label,
    required this.address,
    this.isDefault = false,
  });

  factory PartyAddress.fromJson(Map<String, dynamic> json) {
    return PartyAddress(
      id: json['id'] as String?,
      kind: AddressKind.fromString(json['kind'] as String?),
      label: json['label'] as String?,
      address: Address.fromJson(json['address']) ?? const Address(),
      isDefault: asBool(json['is_default']),
    );
  }

  /// The shape the party endpoints accept in `addresses`.
  Map<String, dynamic> toJson() => {
    'id': ?id,
    'kind': kind.value,
    'label': label,
    'is_default': isDefault,
    'address': address.toJson(),
  };

  PartyAddress copyWith({bool? isDefault}) => PartyAddress(
    id: id,
    kind: kind,
    label: label,
    address: address,
    isDefault: isDefault ?? this.isDefault,
  );

  /// The label, or "Billing" / "Shipping" when it has none.
  String get title => label?.trim().isNotEmpty == true ? label!.trim() : kind.displayName;
}

class Party {
  final String id;
  final String name;
  final PartyType partyType;
  final String? phone;
  final String? email;
  final PartyGstType gstType;
  final String? gstin;
  final String? stateCode;

  /// Defaults first, then in the order they were saved.
  final List<PartyAddress> addresses;
  final double? creditLimit;
  final int? creditDays;
  final String? notes;
  final DateTime? archivedAt;

  /// Positive: the party owes the business. Negative: the business owes them.
  final double balance;
  final double openingBalance;
  final BalanceType openingBalanceType;
  final DateTime? openingBalanceDate;
  final DateTime? createdAt;

  const Party({
    required this.id,
    required this.name,
    required this.partyType,
    this.phone,
    this.email,
    required this.gstType,
    this.gstin,
    this.stateCode,
    this.addresses = const [],
    this.creditLimit,
    this.creditDays,
    this.notes,
    this.archivedAt,
    required this.balance,
    required this.openingBalance,
    required this.openingBalanceType,
    this.openingBalanceDate,
    this.createdAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'] as String,
      name: asString(json['name']),
      partyType: PartyType.fromString(json['party_type'] as String?),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gstType: PartyGstType.fromString(json['gst_type'] as String?),
      gstin: json['gstin'] as String?,
      stateCode: json['state_code'] as String?,
      addresses: asMapList(json['addresses']).map(PartyAddress.fromJson).toList(),
      creditLimit: asDoubleOrNull(json['credit_limit']),
      creditDays: asIntOrNull(json['credit_days']),
      notes: json['notes'] as String?,
      archivedAt: asDate(json['archived_at']),
      balance: asDouble(json['balance']),
      openingBalance: asDouble(json['opening_balance']),
      openingBalanceType: BalanceType.fromString(
        json['opening_balance_type'] as String?,
      ),
      openingBalanceDate: asDate(json['opening_balance_date']),
      createdAt: asDate(json['created_at']),
    );
  }

  bool get isArchived => archivedAt != null;
  bool get isSettled => balance.abs() < 0.005;
  BalanceType get balanceType =>
      balance < 0 ? BalanceType.payable : BalanceType.receivable;

  List<PartyAddress> addressesOf(AddressKind kind) =>
      addresses.where((address) => address.kind == kind).toList();

  /// The default address of [kind], or its first one.
  PartyAddress? defaultAddress(AddressKind kind) {
    final ofKind = addressesOf(kind);
    return ofKind.where((address) => address.isDefault).firstOrNull ?? ofKind.firstOrNull;
  }

  Address? get billingAddress => defaultAddress(AddressKind.billing)?.address;
  Address? get shippingAddress => defaultAddress(AddressKind.shipping)?.address;
}
