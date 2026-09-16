import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/address.dart';

class Party {
  final String id;
  final String name;
  final PartyType partyType;
  final String? phone;
  final String? email;
  final PartyGstType gstType;
  final String? gstin;
  final String? stateCode;
  final Address? billingAddress;
  final Address? shippingAddress;
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
    this.billingAddress,
    this.shippingAddress,
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
      billingAddress: Address.fromJson(json['billing_address']),
      shippingAddress: Address.fromJson(json['shipping_address']),
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
}
