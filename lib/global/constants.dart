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
        return 'Retailer';
      case BusinessType.wholesaler:
        return 'Wholesaler';
      case BusinessType.service:
        return 'Service Business';
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
        return 'Customer';
      case PartyType.supplier:
        return 'Supplier';
      case PartyType.both:
        return 'Both (Customer & Supplier)';
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
        return 'Product';
      case ItemType.service:
        return 'Service';
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
        return 'Sale';
      case InvoiceType.purchase:
        return 'Purchase';
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
        return 'Paid';
      case PaymentStatus.unpaid:
        return 'Unpaid';
      case PaymentStatus.partially_paid:
        return 'Partially Paid';
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
        return 'Cash';
      case PaymentMode.bank:
        return 'Bank';
      case PaymentMode.upi:
        return 'UPI';
      case PaymentMode.credit:
        return 'Credit';
      case PaymentMode.multiple:
        return 'Multiple Modes';
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
        return 'Payment In';
      case PaymentType.payment_out:
        return 'Payment Out';
    }
  }
}

enum WorkerType {
  producer_molder,
  kiln_worker,
  truck_worker;

  String get value => name;

  static WorkerType fromString(String val) {
    final normalized = val
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return WorkerType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => WorkerType.producer_molder,
    );
  }

  String get displayName {
    switch (this) {
      case WorkerType.producer_molder:
        return 'factory.producer_molder'.tr();
      case WorkerType.kiln_worker:
        return 'factory.kiln_worker'.tr();
      case WorkerType.truck_worker:
        return 'factory.truck_worker'.tr();
    }
  }
}

enum TransactionType {
  handoff,
  direct,
  truck_dist,
  money_given;

  String get value => name;

  static TransactionType fromString(String val) {
    final normalized = val
        .toLowerCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    return TransactionType.values.firstWhere(
      (e) => e.name.toLowerCase() == normalized,
      orElse: () => TransactionType.handoff,
    );
  }

  String get displayName {
    switch (this) {
      case TransactionType.handoff:
        return 'factory.handoff'.tr();
      case TransactionType.direct:
        return 'factory.direct'.tr();
      case TransactionType.truck_dist:
        return 'factory.truck_distribution'.tr();
      case TransactionType.money_given:
        return 'factory.money_given'.tr();
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
        return 'GST Invoice';
      case BillType.normal:
        return 'Normal Invoice';
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
        return 'Classic';
      case BillDesign.gstModern1:
        return 'Modern Minimal';
      case BillDesign.gstModern2:
        return 'Professional Slate';
      case BillDesign.normalSimple:
        return 'Simple Receipt';
      case BillDesign.normalDetailed:
        return 'Detailed Retail';
    }
  }

  bool get isGst => this == BillDesign.gstClassic || this == BillDesign.gstModern1 || this == BillDesign.gstModern2;
}

class AppConstants {
  static const String appName = 'Vyapar Setu';

  // Default base URL for local development.
  // In iOS simulator / Web: localhost
  // In Android Emulator: 10.0.2.2
  static const String apiBaseUrl = 'https://vyaparsetubackend.onrender.com/v1/';
}
