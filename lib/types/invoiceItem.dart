class InvoiceItem {
  final String id;
  final String invoiceId;
  final String? itemId;
  final String name;
  final double quantity;
  final double unitPrice;
  final double discountPercentage;
  final double discountAmount;
  final double taxRate;
  final double taxAmount;
  final double totalAmount;

  InvoiceItem({
    required this.id,
    required this.invoiceId,
    this.itemId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.discountPercentage,
    required this.discountAmount,
    required this.taxRate,
    required this.taxAmount,
    required this.totalAmount,
  });

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String? ?? '',
      invoiceId: json['invoice_id'] as String? ?? '',
      itemId: json['item_id'] as String?,
      name: json['name'] as String? ?? '',
      quantity: double.tryParse(json['quantity']?.toString() ?? '0') ?? 0.0,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      discountPercentage: double.tryParse(json['discount_percentage']?.toString() ?? '0') ?? 0.0,
      discountAmount: double.tryParse(json['discount_amount']?.toString() ?? '0') ?? 0.0,
      taxRate: double.tryParse(json['tax_rate']?.toString() ?? '0') ?? 0.0,
      taxAmount: double.tryParse(json['tax_amount']?.toString() ?? '0') ?? 0.0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (invoiceId.isNotEmpty) 'invoice_id': invoiceId,
      if (itemId != null) 'item_id': itemId,
      'name': name,
      'quantity': quantity,
      'unit_price': unitPrice,
      'discount_percentage': discountPercentage,
      'discount_amount': discountAmount,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
    };
  }

  InvoiceItem copyWith({
    String? id,
    String? invoiceId,
    String? itemId,
    String? name,
    double? quantity,
    double? unitPrice,
    double? discountPercentage,
    double? discountAmount,
    double? taxRate,
    double? taxAmount,
    double? totalAmount,
  }) {
    return InvoiceItem(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      discountAmount: discountAmount ?? this.discountAmount,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
    );
  }
}
