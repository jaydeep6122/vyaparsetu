import 'package:vyaparsetu/global/constants.dart';

class Business {
  final String id;
  final String userId;
  final String name;
  final String? email;
  final String? phone;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String? gstin;
  final String? panNumber;
  final BusinessType businessType;
  final String invoicePrefix;
  final int invoiceCounter;
  final String financialYear;
  final String? logoUrl;
  final String? signatureUrl;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? upiId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.id,
    required this.userId,
    required this.name,
    this.email,
    this.phone,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    this.gstin,
    this.panNumber,
    required this.businessType,
    required this.invoicePrefix,
    required this.invoiceCounter,
    required this.financialYear,
    this.logoUrl,
    this.signatureUrl,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.upiId,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      gstin: json['gstin'] as String?,
      panNumber: json['pan_number'] as String?,
      businessType: BusinessType.fromString(json['business_type'] as String? ?? 'retailer'),
      invoicePrefix: json['invoice_prefix'] as String? ?? 'INV',
      invoiceCounter: (json['invoice_counter'] as num? ?? 1).toInt(),
      financialYear: json['financial_year'] as String? ?? '2026-2027',
      logoUrl: json['logo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      upiId: json['upi_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
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
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'pincode': pincode,
      'gstin': gstin,
      'pan_number': panNumber,
      'business_type': businessType.value,
      'invoice_prefix': invoicePrefix,
      'invoice_counter': invoiceCounter,
      'financial_year': financialYear,
      'logo_url': logoUrl,
      'signature_url': signatureUrl,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'upi_id': upiId,
      'is_active': isActive,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Business copyWith({
    String? id,
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? gstin,
    String? panNumber,
    BusinessType? businessType,
    String? invoicePrefix,
    int? invoiceCounter,
    String? financialYear,
    String? logoUrl,
    String? signatureUrl,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      gstin: gstin ?? this.gstin,
      panNumber: panNumber ?? this.panNumber,
      businessType: businessType ?? this.businessType,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      invoiceCounter: invoiceCounter ?? this.invoiceCounter,
      financialYear: financialYear ?? this.financialYear,
      logoUrl: logoUrl ?? this.logoUrl,
      signatureUrl: signatureUrl ?? this.signatureUrl,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
