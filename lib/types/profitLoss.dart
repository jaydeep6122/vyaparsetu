class ProfitLoss {
  final double grossSales;
  final double salesReturns;
  final double netRevenue;
  final double grossPurchases;
  final double purchaseReturns;
  final double netPurchases;
  final double operatingExpenses;
  final double netProfit;

  ProfitLoss({
    required this.grossSales,
    required this.salesReturns,
    required this.netRevenue,
    required this.grossPurchases,
    required this.purchaseReturns,
    required this.netPurchases,
    required this.operatingExpenses,
    required this.netProfit,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      grossSales: double.tryParse(json['gross_sales']?.toString() ?? '0') ?? 0.0,
      salesReturns: double.tryParse(json['sales_returns']?.toString() ?? '0') ?? 0.0,
      netRevenue: double.tryParse(json['net_revenue']?.toString() ?? '0') ?? 0.0,
      grossPurchases: double.tryParse(json['gross_purchases']?.toString() ?? '0') ?? 0.0,
      purchaseReturns: double.tryParse(json['purchase_returns']?.toString() ?? '0') ?? 0.0,
      netPurchases: double.tryParse(json['net_purchases']?.toString() ?? '0') ?? 0.0,
      operatingExpenses: double.tryParse(json['operating_expenses']?.toString() ?? '0') ?? 0.0,
      netProfit: double.tryParse(json['net_profit']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gross_sales': grossSales,
      'sales_returns': salesReturns,
      'net_revenue': netRevenue,
      'gross_purchases': grossPurchases,
      'purchase_returns': purchaseReturns,
      'net_purchases': netPurchases,
      'operating_expenses': operatingExpenses,
      'net_profit': netProfit,
    };
  }
}
