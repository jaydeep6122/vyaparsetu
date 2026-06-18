import 'dart:convert';
import 'package:vyaparsetu/global/constants.dart';

class Party {
  final String id;
  final String businessId;
  final String name;
  final String? phone;
  final String? email;
  final String? gstin;
  final String? billingAddress;
  final String? shippingAddress;
  final PartyType partyType;
  final double openingBalance;
  final OpeningBalanceType openingBalanceType;
  final double currentBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  Party({
    required this.id,
    required this.businessId,
    required this.name,
    this.phone,
    this.email,
    this.gstin,
    this.billingAddress,
    this.shippingAddress,
    required this.partyType,
    required this.openingBalance,
    required this.openingBalanceType,
    required this.currentBalance,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Party.fromJson(Map<String, dynamic> json) {
    return Party(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      name: json['name'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      gstin: json['gstin'] as String?,
      billingAddress: json['billing_address'] as String?,
      shippingAddress: json['shipping_address'] as String?,
      partyType: PartyType.fromString(json['party_type'] as String? ?? 'customer'),
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      openingBalanceType: OpeningBalanceType.fromString(json['opening_balance_type'] as String? ?? 'receive'),
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      'name': name,
      'phone': phone,
      'email': email,
      'gstin': gstin,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      'party_type': partyType.value,
      'opening_balance': openingBalance,
      'opening_balance_type': openingBalanceType.value,
      'current_balance': currentBalance,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Party copyWith({
    String? id,
    String? businessId,
    String? name,
    String? phone,
    String? email,
    String? gstin,
    String? billingAddress,
    String? shippingAddress,
    PartyType? partyType,
    double? openingBalance,
    OpeningBalanceType? openingBalanceType,
    double? currentBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Party(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      partyType: partyType ?? this.partyType,
      openingBalance: openingBalance ?? this.openingBalance,
      openingBalanceType: openingBalanceType ?? this.openingBalanceType,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  List<String> get billingAddresses {
    if (billingAddress == null || billingAddress!.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(billingAddress!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [billingAddress!];
  }

  List<String> get shippingAddresses {
    if (shippingAddress == null || shippingAddress!.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(shippingAddress!);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {}
    return [shippingAddress!];
  }
}
