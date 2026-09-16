import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

/// The part of a payment applied to one invoice, freight charge or expense.
class PaymentAllocation {
  final String? id;
  final String? invoiceId;
  final String? invoiceChargeId;
  final String? expenseId;
  final double amount;
  final String? documentNumber;
  final DateTime? documentDate;

  const PaymentAllocation({
    this.id,
    this.invoiceId,
    this.invoiceChargeId,
    this.expenseId,
    required this.amount,
    this.documentNumber,
    this.documentDate,
  });

  factory PaymentAllocation.fromJson(Map<String, dynamic> json) {
    return PaymentAllocation(
      id: json['id'] as String?,
      invoiceId: json['invoice_id'] as String?,
      invoiceChargeId: json['invoice_charge_id'] as String?,
      expenseId: json['expense_id'] as String?,
      amount: asDouble(json['amount']),
      documentNumber: json['document_number'] as String?,
      documentDate: asDate(json['document_date']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (invoiceId != null) 'invoice_id': invoiceId,
    if (invoiceChargeId != null) 'invoice_charge_id': invoiceChargeId,
    if (expenseId != null) 'expense_id': expenseId,
    'amount': amount.toStringAsFixed(2),
  };
}

class Payment {
  final String id;
  final PaymentDirection paymentType;
  final String paymentNumber;
  final DateTime paymentDate;
  final String? partyId;
  final String? partyName;
  final String accountId;
  final String? accountName;
  final PaymentMode mode;
  final double amount;
  final double amountAllocated;

  /// Kept as an advance on the party.
  final double unallocatedAmount;
  final String? referenceNo;
  final String? chequeNo;
  final DateTime? chequeDate;
  final RecordStatus status;
  final String? notes;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? createdAt;

  /// Empty in list responses.
  final List<PaymentAllocation> allocations;

  const Payment({
    required this.id,
    required this.paymentType,
    required this.paymentNumber,
    required this.paymentDate,
    this.partyId,
    this.partyName,
    required this.accountId,
    this.accountName,
    required this.mode,
    required this.amount,
    required this.amountAllocated,
    required this.unallocatedAmount,
    this.referenceNo,
    this.chequeNo,
    this.chequeDate,
    required this.status,
    this.notes,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
    this.allocations = const [],
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      paymentType: PaymentDirection.fromString(json['payment_type'] as String?),
      paymentNumber: asString(json['payment_number']),
      paymentDate: asDate(json['payment_date']) ?? DateTime.now(),
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String?,
      accountId: asString(json['account_id']),
      accountName: json['account_name'] as String?,
      mode: PaymentMode.fromString(json['mode'] as String?),
      amount: asDouble(json['amount']),
      amountAllocated: asDouble(json['amount_allocated']),
      unallocatedAmount: asDouble(json['unallocated_amount']),
      referenceNo: json['reference_no'] as String?,
      chequeNo: json['cheque_no'] as String?,
      chequeDate: asDate(json['cheque_date']),
      status: RecordStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      cancelledAt: asDate(json['cancelled_at']),
      cancelReason: json['cancel_reason'] as String?,
      createdAt: asDate(json['created_at']),
      allocations: asMapList(json['allocations'])
          .map(PaymentAllocation.fromJson)
          .toList(),
    );
  }

  bool get isIn => paymentType == PaymentDirection.paymentIn;
  bool get isCancelled => status == RecordStatus.cancelled;
}
