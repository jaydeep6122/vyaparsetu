class MetricBreakdown {
  final double base;
  final double tax;
  final double total;

  MetricBreakdown({
    required this.base,
    required this.tax,
    required this.total,
  });

  factory MetricBreakdown.fromJson(Map<String, dynamic> json) {
    return MetricBreakdown(
      base: (json['base'] as num?)?.toDouble() ?? 0,
      tax: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base': base,
      'tax': tax,
      'total': total,
    };
  }
}

class DashboardSummary {
  final MetricBreakdown totalSales;
  final MetricBreakdown totalPurchases;
  final MetricBreakdown totalReceivables;
  final MetricBreakdown totalPayables;
  final MetricBreakdown received;
  final MetricBreakdown totalPaid;
  final int lowStockItemsCount;
  final List<LowStockItem> lowStockItems;
  final CashBook cashBook;

  DashboardSummary({
    required this.totalSales,
    required this.totalPurchases,
    required this.totalReceivables,
    required this.totalPayables,
    required this.received,
    required this.totalPaid,
    required this.lowStockItemsCount,
    required this.lowStockItems,
    required this.cashBook,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalSales: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['total_sales'] ?? {})),
      totalPurchases: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['total_purchases'] ?? {})),
      totalReceivables: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['total_receivables'] ?? {})),
      totalPayables: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['total_payables'] ?? {})),
      received: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['received'] ?? {})),
      totalPaid: MetricBreakdown.fromJson(Map<String, dynamic>.from(json['total_paid'] ?? {})),
      lowStockItemsCount: (json['low_stock_items_count'] as num? ?? 0).toInt(),
      lowStockItems: json['low_stock_items'] != null
          ? (json['low_stock_items'] as List)
              .map((e) => LowStockItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      cashBook: CashBook.fromJson(Map<String, dynamic>.from(json['cash_book'] ?? {})),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_sales': totalSales.toJson(),
      'total_purchases': totalPurchases.toJson(),
      'total_receivables': totalReceivables.toJson(),
      'total_payables': totalPayables.toJson(),
      'received': received.toJson(),
      'total_paid': totalPaid.toJson(),
      'low_stock_items_count': lowStockItemsCount,
      'low_stock_items': lowStockItems.map((e) => e.toJson()).toList(),
      'cash_book': cashBook.toJson(),
    };
  }
}

class CashBook {
  final double cash;
  final double bank;
  final double upi;
  final double totalMoney;

  CashBook({
    required this.cash,
    required this.bank,
    required this.upi,
    required this.totalMoney,
  });

  factory CashBook.fromJson(Map<String, dynamic> json) {
    return CashBook(
      cash: double.tryParse(json['cash']?.toString() ?? '0') ?? 0.0,
      bank: double.tryParse(json['bank']?.toString() ?? '0') ?? 0.0,
      upi: double.tryParse(json['upi']?.toString() ?? '0') ?? 0.0,
      totalMoney: double.tryParse(json['total_money']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cash': cash,
      'bank': bank,
      'upi': upi,
      'total_money': totalMoney,
    };
  }
}

class LowStockItem {
  final String id;
  final String name;
  final String? sku;
  final double currentStock;
  final double lowStockWarning;
  final String measuringUnit;

  LowStockItem({
    required this.id,
    required this.name,
    this.sku,
    required this.currentStock,
    required this.lowStockWarning,
    required this.measuringUnit,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sku: json['sku'] as String?,
      currentStock: double.tryParse(json['current_stock']?.toString() ?? '0') ?? 0.0,
      lowStockWarning: double.tryParse(json['low_stock_warning']?.toString() ?? '0') ?? 0.0,
      measuringUnit: json['measuring_unit'] as String? ?? 'pcs',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'current_stock': currentStock,
      'low_stock_warning': lowStockWarning,
      'measuring_unit': measuringUnit,
    };
  }
}
