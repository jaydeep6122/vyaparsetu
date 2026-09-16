import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/address.dart';

class BusinessSettings {
  final bool roundOffInvoices;
  final String? invoiceTerms;

  const BusinessSettings({this.roundOffInvoices = true, this.invoiceTerms});

  factory BusinessSettings.fromJson(Map<String, dynamic> json) {
    return BusinessSettings(
      roundOffInvoices: asBool(json['round_off_invoices'], true),
      invoiceTerms: json['invoice_terms'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'round_off_invoices': roundOffInvoices,
    'invoice_terms': invoiceTerms,
  };
}

class Business {
  final String id;
  final String name;
  final String? legalName;
  final GstRegistrationType gstRegistrationType;
  final String? gstin;
  final String? pan;

  /// 2-digit GST state code, e.g. '24' for Gujarat.
  final String stateCode;
  final Address? address;
  final String? phone;
  final String? email;

  /// Web URL or inline `data:image/...;base64,` image.
  final String? logoUrl;
  final String? signatureUrl;
  final int fyStartMonth;
  final BusinessSettings settings;

  /// The signed-in user's role in this business.
  final MemberRole role;
  final DateTime? createdAt;

  const Business({
    required this.id,
    required this.name,
    this.legalName,
    required this.gstRegistrationType,
    this.gstin,
    this.pan,
    required this.stateCode,
    this.address,
    this.phone,
    this.email,
    this.logoUrl,
    this.signatureUrl,
    required this.fyStartMonth,
    required this.settings,
    required this.role,
    this.createdAt,
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: asString(json['name']),
      legalName: json['legal_name'] as String?,
      gstRegistrationType: GstRegistrationType.fromString(
        json['gst_registration_type'] as String?,
      ),
      gstin: json['gstin'] as String?,
      pan: json['pan'] as String?,
      stateCode: asString(json['state_code']),
      address: Address.fromJson(json['address']),
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      logoUrl: json['logo_url'] as String?,
      signatureUrl: json['signature_url'] as String?,
      fyStartMonth: asInt(json['fy_start_month'], 4),
      settings: BusinessSettings.fromJson(asMap(json['settings'])),
      role: MemberRole.fromString(json['role'] as String?),
      createdAt: asDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'legal_name': legalName,
    'gst_registration_type': gstRegistrationType.value,
    'gstin': gstin,
    'pan': pan,
    'state_code': stateCode,
    'address': address?.toJson(),
    'phone': phone,
    'email': email,
    'logo_url': logoUrl,
    'signature_url': signatureUrl,
    'fy_start_month': fyStartMonth,
    'settings': settings.toJson(),
    'role': role.value,
    'created_at': createdAt?.toUtc().toIso8601String(),
  };

  /// Only regular GST registrations issue tax invoices.
  bool get canIssueGstInvoices =>
      gstRegistrationType == GstRegistrationType.regular;

  TaxMode get defaultTaxMode => canIssueGstInvoices ? TaxMode.gst : TaxMode.nonGst;
}
