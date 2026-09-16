import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';
import 'package:vyaparsetu/types/invoice.dart';

class Expense {
  final String id;
  final String expenseNumber;
  final DateTime expenseDate;
  final String? categoryId;
  final String? categoryName;

  /// The vendor, when the expense is owed to someone.
  final String? partyId;
  final String? partyName;
  final TaxMode taxMode;
  final double taxableAmount;
  final double cgstAmount;
  final double sgstAmount;
  final double igstAmount;
  final double cessAmount;
  final bool itcEligible;
  final double totalAmount;
  final double amountSettled;
  final PaymentStatus paymentStatus;
  final double outstanding;
  final RecordStatus status;
  final String? notes;
  final DateTime? cancelledAt;
  final String? cancelReason;
  final DateTime? createdAt;

  /// Empty in list responses. Expense payments are always money out.
  final List<InvoicePaymentLink> payments;

  const Expense({
    required this.id,
    required this.expenseNumber,
    required this.expenseDate,
    this.categoryId,
    this.categoryName,
    this.partyId,
    this.partyName,
    required this.taxMode,
    required this.taxableAmount,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.igstAmount,
    required this.cessAmount,
    required this.itcEligible,
    required this.totalAmount,
    required this.amountSettled,
    required this.paymentStatus,
    required this.outstanding,
    required this.status,
    this.notes,
    this.cancelledAt,
    this.cancelReason,
    this.createdAt,
    this.payments = const [],
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    final total = asDouble(json['total_amount']);
    final settled = asDouble(json['amount_settled']);
    return Expense(
      id: json['id'] as String,
      expenseNumber: asString(json['expense_number']),
      expenseDate: asDate(json['expense_date']) ?? DateTime.now(),
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String?,
      taxMode: TaxMode.fromString(json['tax_mode'] as String?),
      taxableAmount: asDouble(json['taxable_amount']),
      cgstAmount: asDouble(json['cgst_amount']),
      sgstAmount: asDouble(json['sgst_amount']),
      igstAmount: asDouble(json['igst_amount']),
      cessAmount: asDouble(json['cess_amount']),
      itcEligible: asBool(json['itc_eligible']),
      totalAmount: total,
      amountSettled: settled,
      paymentStatus: PaymentStatus.fromString(json['payment_status'] as String?),
      outstanding: asDouble(json['outstanding'], total - settled),
      status: RecordStatus.fromString(json['status'] as String?),
      notes: json['notes'] as String?,
      cancelledAt: asDate(json['cancelled_at']),
      cancelReason: json['cancel_reason'] as String?,
      createdAt: asDate(json['created_at']),
      payments: asMapList(json['payments'])
          .map((payment) => InvoicePaymentLink.fromJson({...payment, 'payment_type': 'out'}))
          .toList(),
    );
  }

  bool get isCancelled => status == RecordStatus.cancelled;
  double get taxTotal => cgstAmount + sgstAmount + igstAmount + cessAmount;
}
