import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/address.dart';

class InvoiceLine {
  final String? id;
  final int lineNo;
  final String? itemId;
  final String description;
  final String? hsnSac;
  final double quantity;
  final String? unitCode;
  final double unitPrice;
  final double discountPct;
  final double discountAmount;
  final double taxableValue;
  final double taxRate;
  final double cessRate;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final double lineTotal;

  const InvoiceLine({
    this.id,
    required this.lineNo,
    this.itemId,
    required this.description,
    this.hsnSac,
    required this.quantity,
    this.unitCode,
    required this.unitPrice,
    required this.discountPct,
    required this.discountAmount,
    required this.taxableValue,
    required this.taxRate,
    required this.cessRate,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.lineTotal,
  });

  factory InvoiceLine.fromJson(Map<String, dynamic> json) {
    return InvoiceLine(
      id: json['id'] as String?,
      lineNo: asInt(json['line_no'], 1),
      itemId: json['item_id'] as String?,
      description: asString(json['description']),
      hsnSac: json['hsn_sac'] as String?,
      quantity: asDouble(json['quantity']),
      unitCode: json['unit_code'] as String?,
      unitPrice: asDouble(json['unit_price']),
      discountPct: asDouble(json['discount_pct']),
      discountAmount: asDouble(json['discount_amount']),
      taxableValue: asDouble(json['taxable_value']),
      taxRate: asDouble(json['tax_rate']),
      cessRate: asDouble(json['cess_rate']),
      cgstAmount: asDouble(json['cgst_amount']),
      sgstAmount: asDouble(json['sgst_amount']),
      igstAmount: asDouble(json['igst_amount']),
      cessAmount: asDouble(json['cess_amount']),
      lineTotal: asDouble(json['line_total']),
    );
  }

  double get taxAmount => cgstAmount + sgstAmount + igstAmount + cessAmount;
}

class InvoiceCharge {
  final String? id;
  final ChargeType chargeType;
  final String? description;
  final ChargeBillTo billTo;
  final String? payeePartyId;
  final String? payeeName;
  final String? vehicleNo;
  final double? qty;
  final double? rate;
  final double amount;
  final double taxRate;
  final double taxAmount;

  /// Paid so far to the payee.
  final double amountSettled;
  final double outstanding;

  const InvoiceCharge({
    this.id,
    required this.chargeType,
    this.description,
    required this.billTo,
    this.payeePartyId,
    this.payeeName,
    this.vehicleNo,
    this.qty,
    this.rate,
    required this.amount,
    required this.taxRate,
    required this.taxAmount,
    required this.amountSettled,
    required this.outstanding,
  });

  factory InvoiceCharge.fromJson(Map<String, dynamic> json) {
    return InvoiceCharge(
      id: json['id'] as String?,
      chargeType: ChargeType.fromString(json['charge_type'] as String?),
      description: json['description'] as String?,
      billTo: ChargeBillTo.fromString(json['bill_to'] as String?),
      payeePartyId: json['payee_party_id'] as String?,
      payeeName: json['payee_name'] as String?,
      vehicleNo: json['vehicle_no'] as String?,
      qty: asDoubleOrNull(json['qty']),
      rate: asDoubleOrNull(json['rate']),
      amount: asDouble(json['amount']),
      taxRate: asDouble(json['tax_rate']),
      taxAmount: asDouble(json['tax_amount']),
      amountSettled: asDouble(json['amount_settled']),
      outstanding: asDouble(json['outstanding']),
    );
  }

  double get total => amount + taxAmount;
}

/// A payment (or the part of one) applied to an invoice or one of its charges.
class InvoicePaymentLink {
  final String allocationId;
  final double amount;

  /// Set when the payment settles a charge (e.g. freight) instead of the bill.
  final String? invoiceChargeId;
  final String paymentId;
  final PaymentDirection paymentType;
  final String paymentNumber;
  final DateTime? paymentDate;
  final PaymentMode mode;

  const InvoicePaymentLink({
    required this.allocationId,
    required this.amount,
    this.invoiceChargeId,
    required this.paymentId,
    required this.paymentType,
    required this.paymentNumber,
    this.paymentDate,
    required this.mode,
  });

  factory InvoicePaymentLink.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentLink(
      allocationId: asString(json['allocation_id']),
      amount: asDouble(json['amount']),
      invoiceChargeId: json['invoice_charge_id'] as String?,
      paymentId: asString(json['payment_id']),
      paymentType: PaymentDirection.fromString(json['payment_type'] as String?),
      paymentNumber: asString(json['payment_number']),
      paymentDate: asDate(json['payment_date']),
      mode: PaymentMode.fromString(json['mode'] as String?),
    );
  }
}

class Invoice {
  final String id;
  final InvoiceType invoiceType;
  final TaxMode taxMode;
  final InvoiceStatus status;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final DateTime? dueDate;
  final String? supplierInvoiceNumber;
  final DateTime? supplierInvoiceDate;
  final String? partyId;
  final String partyName;
  final String? partyGstin;
  final String? partyStateCode;
  final Address? billingAddress;
  final Address? shippingAddress;
  final String? placeOfSupply;

  /// 'intra' (CGST + SGST) or 'inter' (IGST); null on non-GST bills.
  final String? supplyType;
  final bool isReverseCharge;
  final String? originalInvoiceId;
  final bool priceIncludesTax;

  final double taxableTotal;
  final double discountTotal;
  final double cgstTotal;
  final double sgstTotal;
  final double igstTotal;
  final double cessTotal;
  final double chargesTotal;
  final double roundOff;
  final double totalAmount;
  final double amountSettled;
  final PaymentStatus paymentStatus;
  final double outstanding;

  final String? vehicleNo;
  final String? driverName;
  final String? driverPhone;
  final TransportMode? transportMode;
  final String? lrNo;
  final DateTime? lrDate;
  final String? ewayBillNo;
  final DateTime? ewayBillDate;
  final String? chalanNo;
  final DateTime? deliveryDate;
  final Address? dispatchFrom;
  final Address? shipTo;

  final String? notes;
  final String? terms;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? createdAt;

  /// Empty in list responses; filled when loading one invoice.
  final List<InvoiceLine> lines;
  final List<InvoiceCharge> charges;
  final List<InvoicePaymentLink> payments;

  const Invoice({
    required this.id,
    required this.invoiceType,
    required this.taxMode,
    required this.status,
    required this.invoiceNumber,
    required this.invoiceDate,
    this.dueDate,
    this.supplierInvoiceNumber,
    this.supplierInvoiceDate,
    this.partyId,
    required this.partyName,
    this.partyGstin,
    this.partyStateCode,
    this.billingAddress,
    this.shippingAddress,
    this.placeOfSupply,
    this.supplyType,
    required this.isReverseCharge,
    this.originalInvoiceId,
    required this.priceIncludesTax,
    required this.taxableTotal,
    required this.discountTotal,
    required this.cgstTotal,
    required this.sgstTotal,
    required this.igstTotal,
    required this.cessTotal,
    required this.chargesTotal,
    required this.roundOff,
    required this.totalAmount,
    required this.amountSettled,
    required this.paymentStatus,
    required this.outstanding,
    this.vehicleNo,
    this.driverName,
    this.driverPhone,
    this.transportMode,
    this.lrNo,
    this.lrDate,
    this.ewayBillNo,
    this.ewayBillDate,
    this.chalanNo,
    this.deliveryDate,
    this.dispatchFrom,
    this.shipTo,
    this.notes,
    this.terms,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
    this.lines = const [],
    this.charges = const [],
    this.payments = const [],
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final total = asDouble(json['total_amount']);
    final settled = asDouble(json['amount_settled']);
    return Invoice(
      id: json['id'] as String,
      invoiceType: InvoiceType.fromString(json['invoice_type'] as String?),
      taxMode: TaxMode.fromString(json['tax_mode'] as String?),
      status: InvoiceStatus.fromString(json['status'] as String?),
      invoiceNumber: asString(json['invoice_number']),
      invoiceDate: asDate(json['invoice_date']) ?? DateTime.now(),
      dueDate: asDate(json['due_date']),
      supplierInvoiceNumber: json['supplier_invoice_number'] as String?,
      supplierInvoiceDate: asDate(json['supplier_invoice_date']),
      partyId: json['party_id'] as String?,
      partyName: asString(json['party_name']),
      partyGstin: json['party_gstin'] as String?,
      partyStateCode: json['party_state_code'] as String?,
      billingAddress: Address.fromJson(json['billing_address']),
      shippingAddress: Address.fromJson(json['shipping_address']),
      placeOfSupply: json['place_of_supply'] as String?,
      supplyType: json['supply_type'] as String?,
      isReverseCharge: asBool(json['is_reverse_charge']),
      originalInvoiceId: json['original_invoice_id'] as String?,
      priceIncludesTax: asBool(json['price_includes_tax']),
      taxableTotal: asDouble(json['taxable_total']),
      discountTotal: asDouble(json['discount_total']),
      cgstTotal: asDouble(json['cgst_total']),
      sgstTotal: asDouble(json['sgst_total']),
      igstTotal: asDouble(json['igst_total']),
      cessTotal: asDouble(json['cess_total']),
      chargesTotal: asDouble(json['charges_total']),
      roundOff: asDouble(json['round_off']),
      totalAmount: total,
      amountSettled: settled,
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String?),
      outstanding: asDouble(json['outstanding'], total - settled),
      vehicleNo: json['vehicle_no'] as String?,
      driverName: json['driver_name'] as String?,
      driverPhone: json['driver_phone'] as String?,
      transportMode: TransportMode.fromString(json['transport_mode'] as String?),
      lrNo: json['lr_no'] as String?,
      lrDate: asDate(json['lr_date']),
      ewayBillNo: json['eway_bill_no'] as String?,
      ewayBillDate: asDate(json['eway_bill_date']),
      chalanNo: json['chalan_no'] as String?,
      deliveryDate: asDate(json['delivery_date']),
      dispatchFrom: Address.fromJson(json['dispatch_from']),
      shipTo: Address.fromJson(json['ship_to']),
      notes: json['notes'] as String?,
      terms: json['terms'] as String?,
      cancelledAt: asDate(json['cancelled_at']),
      cancelReason: json['cancel_reason'] as String?,
      createdAt: asDate(json['created_at']),
      lines: asMapList(json['lines']).map(InvoiceLine.fromJson).toList(),
      charges: asMapList(json['charges']).map(InvoiceCharge.fromJson).toList(),
      payments: asMapList(json['payments'])
          .map(InvoicePaymentLink.fromJson)
          .toList(),
    );
  }

  bool get isGst => taxMode == TaxMode.gst;
  bool get isInterState => supplyType == 'inter';
  bool get isDraft => status == InvoiceStatus.draft;
  bool get isCancelled => status == InvoiceStatus.cancelled;
  bool get isWalkIn => partyId == null;

  bool get isOverdue {
    if (status != InvoiceStatus.finalized || outstanding < 0.005 || dueDate == null) {
      return false;
    }
    final now = DateTime.now();
    return dueDate!.isBefore(DateTime(now.year, now.month, now.day));
  }

  double get taxTotal => cgstTotal + sgstTotal + igstTotal + cessTotal;

  bool get hasTransportDetails =>
      [vehicleNo, driverName, lrNo, ewayBillNo, chalanNo]
          .any((value) => value != null && value.isNotEmpty) ||
      deliveryDate != null ||
      transportMode != null;
}
