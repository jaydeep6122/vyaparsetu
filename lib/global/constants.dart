import 'package:easy_localization/easy_localization.dart';

enum BusinessType {
  retailer,
  wholesaler,
  service;

  String get value => name;

  static BusinessType fromString(String val) {
    return BusinessType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BusinessType.retailer,
    );
  }

  String get displayName {
    switch (this) {
      case BusinessType.retailer:
        return 'retailer'.tr();
      case BusinessType.wholesaler:
        return 'wholesaler'.tr();
      case BusinessType.service:
        return 'service_business'.tr();
    }
  }
}

enum PartyType {
  customer,
  supplier,
  both;

  String get value => name;

  static PartyType fromString(String val) {
    return PartyType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PartyType.customer,
    );
  }

  String get displayName {
    switch (this) {
      case PartyType.customer:
        return 'customer'.tr();
      case PartyType.supplier:
        return 'supplier'.tr();
      case PartyType.both:
        return 'both'.tr();
    }
  }
}

enum OpeningBalanceType {
  receive,
  pay;

  String get value => name;

  static OpeningBalanceType fromString(String val) {
    return OpeningBalanceType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => OpeningBalanceType.receive,
    );
  }
}

enum ItemType {
  product,
  service;

  String get value => name;

  static ItemType fromString(String val) {
    return ItemType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => ItemType.product,
    );
  }

  String get displayName {
    switch (this) {
      case ItemType.product:
        return 'product'.tr();
      case ItemType.service:
        return 'service'.tr();
    }
  }
}

enum InvoiceType {
  sale,
  purchase;

  String get value => name;

  static InvoiceType fromString(String val) {
    final normalized = val.toLowerCase().replaceAll('-', '_');
    return InvoiceType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => InvoiceType.sale,
    );
  }

  String get displayName {
    switch (this) {
      case InvoiceType.sale:
        return 'sale'.tr();
      case InvoiceType.purchase:
        return 'purchase'.tr();
    }
  }
}

enum PaymentStatus {
  paid,
  unpaid,
  partially_paid;

  String get value => name;

  static PaymentStatus fromString(String val) {
    final normalized = val.toLowerCase().replaceAll('-', '_');
    return PaymentStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => PaymentStatus.unpaid,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentStatus.paid:
        return 'paid'.tr();
      case PaymentStatus.unpaid:
        return 'unpaid'.tr();
      case PaymentStatus.partially_paid:
        return 'partially_paid'.tr();
    }
  }
}

enum PaymentMode {
  cash,
  bank,
  upi,
  credit,
  multiple;

  String get value => name;

  static PaymentMode fromString(String val) {
    return PaymentMode.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => PaymentMode.cash,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentMode.cash:
        return 'cash'.tr();
      case PaymentMode.bank:
        return 'bank'.tr();
      case PaymentMode.upi:
        return 'upi'.tr();
      case PaymentMode.credit:
        return 'credit'.tr();
      case PaymentMode.multiple:
        return 'multiple_modes'.tr();
    }
  }
}

enum PaymentType {
  payment_in,
  payment_out;

  String get value => name;

  static PaymentType fromString(String val) {
    final normalized = val.toLowerCase().replaceAll('-', '_');
    return PaymentType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => PaymentType.payment_in,
    );
  }

  String get displayName {
    switch (this) {
      case PaymentType.payment_in:
        return 'payment_in'.tr();
      case PaymentType.payment_out:
        return 'payment_out'.tr();
    }
  }
}

enum SupportedLocale {
  en,
  hi,
  gu;

  String get code => name;
}

enum BillType {
  gst,
  normal;

  String get value => name;

  static BillType fromString(String val) {
    return BillType.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BillType.gst,
    );
  }

  String get displayName {
    switch (this) {
      case BillType.gst:
        return 'gst_invoice'.tr();
      case BillType.normal:
        return 'normal_invoice'.tr();
    }
  }
}

enum BillDesign {
  gstClassic,
  gstModern1,
  gstModern2,
  normalSimple,
  normalDetailed;

  String get value => name;

  static BillDesign fromString(String val) {
    return BillDesign.values.firstWhere(
      (e) => e.name.toLowerCase() == val.toLowerCase(),
      orElse: () => BillDesign.gstClassic,
    );
  }

  String get displayName {
    switch (this) {
      case BillDesign.gstClassic:
        return 'classic'.tr();
      case BillDesign.gstModern1:
        return 'modern_minimal'.tr();
      case BillDesign.gstModern2:
        return 'professional_slate'.tr();
      case BillDesign.normalSimple:
        return 'simple_receipt'.tr();
      case BillDesign.normalDetailed:
        return 'detailed_retail'.tr();
    }
  }

  bool get isGst =>
      this == BillDesign.gstClassic ||
      this == BillDesign.gstModern1 ||
      this == BillDesign.gstModern2;
}

class AppConstants {
  static const String appName = 'Vyapar Setu';

  // Default base URL for local development.
  // In iOS simulator / Web: localhost
  // In Android Emulator: 10.0.2.2
  // old
  // static const String apiBaseUrl = 'https://vyaparsetubackend.onrender.com/v1/';

  // new

  static const String apiBaseUrl =
      'https://vyaparsetubackendsingapore.onrender.com/v1/';
}
