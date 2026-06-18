import 'package:vyaparsetu/global/constants.dart';

class Payment {
  final String id;
  final String businessId;
  final String partyId;
  final String? partyName;
  final String? invoiceId;
  final PaymentType paymentType;
  final String? referenceNumber;
  final DateTime paymentDate;
  final double amount;
  final PaymentMode paymentMode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    required this.businessId,
    required this.partyId,
    this.partyName,
    this.invoiceId,
    required this.paymentType,
    this.referenceNumber,
    required this.paymentDate,
    required this.amount,
    required this.paymentMode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      partyId: json['party_id'] as String? ?? '',
      partyName: json['party_name'] as String?,
      invoiceId: json['invoice_id'] as String?,
      paymentType: PaymentType.fromString(json['payment_type'] as String? ?? 'payment_in'),
      referenceNumber: json['reference_number'] as String?,
      paymentDate: json['payment_date'] != null
          ? DateTime.parse(json['payment_date'] as String).toLocal()
          : DateTime.now(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      paymentMode: PaymentMode.fromString(json['payment_mode'] as String? ?? 'cash'),
      description: json['description'] as String?,
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
      'party_id': partyId,
      if (partyName != null) 'party_name': partyName,
      if (invoiceId != null) 'invoice_id': invoiceId,
      'payment_type': paymentType.value,
      'reference_number': referenceNumber,
      'payment_date': paymentDate.toUtc().toIso8601String(),
      'amount': amount,
      'payment_mode': paymentMode.value,
      'description': description,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? businessId,
    String? partyId,
    String? partyName,
    String? invoiceId,
    PaymentType? paymentType,
    String? referenceNumber,
    DateTime? paymentDate,
    double? amount,
    PaymentMode? paymentMode,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      invoiceId: invoiceId ?? this.invoiceId,
      paymentType: paymentType ?? this.paymentType,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      paymentDate: paymentDate ?? this.paymentDate,
      amount: amount ?? this.amount,
      paymentMode: paymentMode ?? this.paymentMode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
