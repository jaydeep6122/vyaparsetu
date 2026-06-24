import 'dart:convert';
import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/invoiceItem.dart';

class Invoice {
  final String id;
  final String businessId;
  final String? partyId;
  final String? partyName;
  final String invoiceNumber;
  final InvoiceType invoiceType;
  final String? chalanNo;
  final double transportCost;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final DateTime? deliveryDate;
  final double subTotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final double paidAmount;
  final PaymentStatus paymentStatus;
  final PaymentMode paymentMode;
  final String? notes;
  final String? billingAddress;
  final String? shippingAddress;
  final List<InvoiceItem>? items;
  final DateTime createdAt;
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.businessId,
    this.partyId,
    this.partyName,
    required this.invoiceNumber,
    required this.invoiceType,
    this.chalanNo,
    required this.transportCost,
    required this.invoiceDate,
    this.dueDate,
    this.deliveryDate,
    required this.subTotal,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentStatus,
    required this.paymentMode,
    this.notes,
    this.billingAddress,
    this.shippingAddress,
    this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String?,
      invoiceNumber: json['invoice_number'] as String? ?? '',
      invoiceType: InvoiceType.fromString(
        json['invoice_type'] as String? ?? 'sale',
      ),
      chalanNo: json['chalan_no'] as String?,
      transportCost:
          double.tryParse(json['transport_cost']?.toString() ?? '0') ?? 0.0,
      invoiceDate:
          json['invoice_date'] != null
              ? DateTime.parse(json['invoice_date'] as String).toLocal()
              : DateTime.now(),
      dueDate:
          json['due_date'] != null
              ? DateTime.parse(json['due_date'] as String).toLocal()
              : null,
      deliveryDate:
          json['delivery_date'] != null
              ? DateTime.parse(json['delivery_date'] as String).toLocal()
              : null,
      subTotal: double.tryParse(json['sub_total']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      discountAmount:
          double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount:
          double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      paymentStatus: PaymentStatus.fromString(
        json['payment_status'] as String? ?? 'unpaid',
      ),
      paymentMode: PaymentMode.fromString(
        json['payment_mode'] as String? ?? 'cash',
      ),
      notes: json['notes'] as String?,
      billingAddress:
          json['billing_address'] as String? ??
          _parseAddressFromNotes(json['notes'] as String?, 'billing'),
      shippingAddress:
          json['shipping_address'] as String? ??
          _parseAddressFromNotes(json['notes'] as String?, 'shipping'),
      items:
          json['items'] != null
              ? (json['items'] as List)
                  .map(
                    (e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e)),
                  )
                  .toList()
              : null,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'] as String).toLocal()
              : DateTime.now(),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'] as String).toLocal()
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'business_id': businessId,
      if (partyId != null) 'party_id': partyId,
      if (partyName != null) 'party_name': partyName,
      'invoice_number': invoiceNumber,
      'invoice_type': invoiceType.value,
      'chalan_no': chalanNo,
      'transport_cost': transportCost,
      'invoice_date': invoiceDate.toUtc().toIso8601String(),
      if (dueDate != null) 'due_date': dueDate?.toUtc().toIso8601String(),
      if (deliveryDate != null) 'delivery_date': deliveryDate?.toUtc().toIso8601String(),
      'sub_total': subTotal,
      'tax_amount': taxAmount,
      'discount_amount': discountAmount,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_status': paymentStatus.value,
      'payment_mode': paymentMode.value,
      'notes': notes,
      'billing_address': billingAddress,
      'shipping_address': shippingAddress,
      if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Invoice copyWith({
    String? id,
    String? businessId,
    String? partyId,
    String? partyName,
    String? invoiceNumber,
    InvoiceType? invoiceType,
    String? chalanNo,
    double? transportCost,
    DateTime? invoiceDate,
    DateTime? dueDate,
    DateTime? deliveryDate,
    double? subTotal,
    double? taxAmount,
    double? discountAmount,
    double? totalAmount,
    double? paidAmount,
    PaymentStatus? paymentStatus,
    PaymentMode? paymentMode,
    String? notes,
    String? billingAddress,
    String? shippingAddress,
    List<InvoiceItem>? items,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Invoice(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceType: invoiceType ?? this.invoiceType,
      chalanNo: chalanNo ?? this.chalanNo,
      transportCost: transportCost ?? this.transportCost,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      subTotal: subTotal ?? this.subTotal,
      taxAmount: taxAmount ?? this.taxAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMode: paymentMode ?? this.paymentMode,
      notes: notes ?? this.notes,
      billingAddress: billingAddress ?? this.billingAddress,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      items: items ?? this.items,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _parseAddressFromNotes(String? notes, String key) {
    if (notes == null) return null;
    final index = notes.indexOf('\n[Addresses:');
    if (index != -1) {
      try {
        final rawJson = notes.substring(index + 12, notes.length - 1);
        final data = jsonDecode(rawJson);
        return data[key] as String?;
      } catch (_) {}
    }
    final index2 = notes.indexOf('[Addresses:');
    if (index2 != -1) {
      try {
        final rawJson = notes.substring(index2 + 11, notes.length - 1);
        final data = jsonDecode(rawJson);
        return data[key] as String?;
      } catch (_) {}
    }
    return null;
  }

  String? get visibleNotes {
    if (notes == null) return null;
    String cleaned = notes!;
    // Strip bill_type marker
    cleaned = cleaned.replaceAll(RegExp(r'\[bill_type:\w+\]\s*'), '').trim();
    // Strip Addresses suffix
    final index = cleaned.indexOf('\n[Addresses:');
    if (index != -1) {
      return cleaned.substring(0, index).trim();
    }
    final index2 = cleaned.indexOf('[Addresses:');
    if (index2 != -1) {
      return cleaned.substring(0, index2).trim();
    }
    return cleaned;
  }
}
