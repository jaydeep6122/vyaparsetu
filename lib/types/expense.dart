import 'package:vyaparsetu/global/constants.dart';

class Expense {
  final String id;
  final String businessId;
  final String expenseCategory;
  final String expenseNumber;
  final DateTime expenseDate;
  final double totalAmount;
  final double paidAmount;
  final PaymentMode paymentMode;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  Expense({
    required this.id,
    required this.businessId,
    required this.expenseCategory,
    required this.expenseNumber,
    required this.expenseDate,
    required this.totalAmount,
    required this.paidAmount,
    required this.paymentMode,
    this.description,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      expenseCategory: json['expense_category'] as String? ?? '',
      expenseNumber: json['expense_number'] as String? ?? '',
      expenseDate: json['expense_date'] != null
          ? DateTime.parse(json['expense_date'] as String).toLocal()
          : DateTime.now(),
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
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
      'expense_category': expenseCategory,
      'expense_number': expenseNumber,
      'expense_date': expenseDate.toUtc().toIso8601String(),
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'payment_mode': paymentMode.value,
      'description': description,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Expense copyWith({
    String? id,
    String? businessId,
    String? expenseCategory,
    String? expenseNumber,
    DateTime? expenseDate,
    double? totalAmount,
    double? paidAmount,
    PaymentMode? paymentMode,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Expense(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      expenseCategory: expenseCategory ?? this.expenseCategory,
      expenseNumber: expenseNumber ?? this.expenseNumber,
      expenseDate: expenseDate ?? this.expenseDate,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      paymentMode: paymentMode ?? this.paymentMode,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
