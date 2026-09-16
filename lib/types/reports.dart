import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

class Period {
  final DateTime from;
  final DateTime to;

  const Period({required this.from, required this.to});

  factory Period.fromJson(Map<String, dynamic> json) {
    return Period(
      from: asDate(json['from']) ?? DateTime.now(),
      to: asDate(json['to']) ?? DateTime.now(),
    );
  }
}

class GrossNet {
  final double gross;
  final double returns;
  final double net;
  final int count;

  const GrossNet({
    required this.gross,
    required this.returns,
    required this.net,
    required this.count,
  });

  factory GrossNet.fromJson(Map<String, dynamic> json) {
    return GrossNet(
      gross: asDouble(json['gross']),
      returns: asDouble(json['returns']),
      net: asDouble(json['net']),
      count: asInt(json['count']),
    );
  }
}

class AccountBalance {
  final String id;
  final String name;
  final AccountType accountType;
  final double balance;

  const AccountBalance({
    required this.id,
    required this.name,
    required this.accountType,
    required this.balance,
  });

  factory AccountBalance.fromJson(Map<String, dynamic> json) {
    return AccountBalance(
      id: asString(json['id']),
      name: asString(json['name']),
      accountType: AccountType.fromString(json['account_type'] as String?),
      balance: asDouble(json['balance']),
    );
  }
}

class LowStockItem {
  final String id;
  final String name;
  final String? unitCode;
  final double lowStockThreshold;
  final double quantityOnHand;

  const LowStockItem({
    required this.id,
    required this.name,
    this.unitCode,
    required this.lowStockThreshold,
    required this.quantityOnHand,
  });

  factory LowStockItem.fromJson(Map<String, dynamic> json) {
    return LowStockItem(
      id: asString(json['id']),
      name: asString(json['name']),
      unitCode: json['unit_code'] as String?,
      lowStockThreshold: asDouble(json['low_stock_threshold']),
      quantityOnHand: asDouble(json['quantity_on_hand']),
    );
  }
}

class DashboardData {
  final Period period;
  final double receivable;
  final double payable;
  final double cashBalance;
  final double bankBalance;
  final List<AccountBalance> accounts;
  final GrossNet sales;
  final GrossNet purchases;
  final double received;
  final double paid;
  final double expenses;
  final int overdueCount;
  final double overdueAmount;
  final List<LowStockItem> lowStock;

  const DashboardData({
    required this.period,
    required this.receivable,
    required this.payable,
    required this.cashBalance,
    required this.bankBalance,
    required this.accounts,
    required this.sales,
    required this.purchases,
    required this.received,
    required this.paid,
    required this.expenses,
    required this.overdueCount,
    required this.overdueAmount,
    required this.lowStock,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    final overdue = asMap(json['overdue_receivables']);
    return DashboardData(
      period: Period.fromJson(asMap(json['period'])),
      receivable: asDouble(json['receivable']),
      payable: asDouble(json['payable']),
      cashBalance: asDouble(json['cash_balance']),
      bankBalance: asDouble(json['bank_balance']),
      accounts: asMapList(json['accounts']).map(AccountBalance.fromJson).toList(),
      sales: GrossNet.fromJson(asMap(json['sales'])),
      purchases: GrossNet.fromJson(asMap(json['purchases'])),
      received: asDouble(json['received']),
      paid: asDouble(json['paid']),
      expenses: asDouble(json['expenses']),
      overdueCount: asInt(overdue['count']),
      overdueAmount: asDouble(overdue['amount']),
      lowStock: asMapList(json['low_stock']).map(LowStockItem.fromJson).toList(),
    );
  }
}

class LedgerEntry {
  final int id;
  final DateTime entryDate;
  final LedgerSource sourceType;
  final String sourceId;
  final double debit;
  final double credit;

  /// Signed amount for account books: money in is positive.
  final double amount;
  final String? narration;

  /// Running balance after this entry.
  final double balance;

  const LedgerEntry({
    required this.id,
    required this.entryDate,
    required this.sourceType,
    required this.sourceId,
    required this.debit,
    required this.credit,
    required this.amount,
    this.narration,
    required this.balance,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: asInt(json['id']),
      entryDate: asDate(json['entry_date']) ?? DateTime.now(),
      sourceType: LedgerSource.fromString(json['source_type'] as String?),
      sourceId: asString(json['source_id']),
      debit: asDouble(json['debit']),
      credit: asDouble(json['credit']),
      amount: asDouble(json['amount']),
      narration: json['narration'] as String?,
      balance: asDouble(json['balance']),
    );
  }
}

/// A party ledger or an account book for a period.
class Ledger {
  final String ownerId;
  final String ownerName;
  final Period period;
  final double openingBalance;

  /// Party ledgers: debits and credits. Account books: money in and out.
  final double totalDebitOrIn;
  final double totalCreditOrOut;
  final double closingBalance;
  final List<LedgerEntry> entries;

  const Ledger({
    required this.ownerId,
    required this.ownerName,
    required this.period,
    required this.openingBalance,
    required this.totalDebitOrIn,
    required this.totalCreditOrOut,
    required this.closingBalance,
    required this.entries,
  });

  factory Ledger.partyFromJson(Map<String, dynamic> json) {
    final party = asMap(json['party']);
    return Ledger(
      ownerId: asString(party['id']),
      ownerName: asString(party['name']),
      period: Period.fromJson(asMap(json['period'])),
      openingBalance: asDouble(json['opening_balance']),
      totalDebitOrIn: asDouble(json['total_debit']),
      totalCreditOrOut: asDouble(json['total_credit']),
      closingBalance: asDouble(json['closing_balance']),
      entries: asMapList(json['entries']).map(LedgerEntry.fromJson).toList(),
    );
  }

  factory Ledger.accountFromJson(Map<String, dynamic> json) {
    final account = asMap(json['account']);
    return Ledger(
      ownerId: asString(account['id']),
      ownerName: asString(account['name']),
      period: Period.fromJson(asMap(json['period'])),
      openingBalance: asDouble(json['opening_balance']),
      totalDebitOrIn: asDouble(json['total_in']),
      totalCreditOrOut: asDouble(json['total_out']),
      closingBalance: asDouble(json['closing_balance']),
      entries: asMapList(json['entries']).map(LedgerEntry.fromJson).toList(),
    );
  }
}

class StockSummaryRow {
  final String id;
  final String name;
  final String? sku;
  final String? unitCode;
  final double? lowStockThreshold;
  final double quantityOnHand;
  final double? averageCost;
  final double stockValue;
  final bool isLow;

  const StockSummaryRow({
    required this.id,
    required this.name,
    this.sku,
    this.unitCode,
    this.lowStockThreshold,
    required this.quantityOnHand,
    this.averageCost,
    required this.stockValue,
    required this.isLow,
  });

  factory StockSummaryRow.fromJson(Map<String, dynamic> json) {
    return StockSummaryRow(
      id: asString(json['id']),
      name: asString(json['name']),
      sku: json['sku'] as String?,
      unitCode: json['unit_code'] as String?,
      lowStockThreshold: asDoubleOrNull(json['low_stock_threshold']),
      quantityOnHand: asDouble(json['quantity_on_hand']),
      averageCost: asDoubleOrNull(json['average_cost']),
      stockValue: asDouble(json['stock_value']),
      isLow: asBool(json['is_low']),
    );
  }
}

class StockSummary {
  final List<StockSummaryRow> items;
  final double totalValue;

  const StockSummary({required this.items, required this.totalValue});

  factory StockSummary.fromJson(Map<String, dynamic> json) {
    return StockSummary(
      items: asMapList(json['items']).map(StockSummaryRow.fromJson).toList(),
      totalValue: asDouble(json['total_value']),
    );
  }
}

class OutstandingDocument {
  /// 'invoice', 'charge' (freight owed to a payee) or 'expense'.
  final String kind;
  final String id;
  final String number;
  final String documentType;
  final DateTime? documentDate;
  final DateTime? dueDate;
  final String? partyId;
  final String partyName;
  final double totalAmount;
  final double amountSettled;
  final double outstanding;
  final int daysOverdue;
  final String bucket;

  const OutstandingDocument({
    required this.kind,
    required this.id,
    required this.number,
    required this.documentType,
    this.documentDate,
    this.dueDate,
    this.partyId,
    required this.partyName,
    required this.totalAmount,
    required this.amountSettled,
    required this.outstanding,
    required this.daysOverdue,
    required this.bucket,
  });

  factory OutstandingDocument.fromJson(Map<String, dynamic> json) {
    return OutstandingDocument(
      kind: asString(json['kind']),
      id: asString(json['id']),
      number: asString(json['number']),
      documentType: asString(json['document_type']),
      documentDate: asDate(json['document_date']),
      dueDate: asDate(json['due_date']),
      partyId: json['party_id'] as String?,
      partyName: asString(json['party_name']),
      totalAmount: asDouble(json['total_amount']),
      amountSettled: asDouble(json['amount_settled']),
      outstanding: asDouble(json['outstanding']),
      daysOverdue: asInt(json['days_overdue']),
      bucket: asString(json['bucket']),
    );
  }
}

class OutstandingReport {
  final OutstandingType type;
  final DateTime? asOf;
  final double total;

  /// not_due, 1_30, 31_60, 61_90, over_90 → amount.
  final Map<String, double> buckets;
  final List<OutstandingDocument> documents;

  const OutstandingReport({
    required this.type,
    this.asOf,
    required this.total,
    required this.buckets,
    required this.documents,
  });

  static const bucketKeys = ['not_due', '1_30', '31_60', '61_90', 'over_90'];

  factory OutstandingReport.fromJson(Map<String, dynamic> json) {
    final buckets = asMap(json['buckets']);
    return OutstandingReport(
      type: json['type'] == 'payable'
          ? OutstandingType.payable
          : OutstandingType.receivable,
      asOf: asDate(json['as_of']),
      total: asDouble(json['total']),
      buckets: {for (final key in bucketKeys) key: asDouble(buckets[key])},
      documents: asMapList(json['documents'])
          .map(OutstandingDocument.fromJson)
          .toList(),
    );
  }
}

class ProfitLoss {
  final Period period;
  final double netSales;
  final double chargesRecovered;
  final double revenue;
  final double costOfGoodsSold;
  final double nonStockPurchases;
  final double freightAndCharges;
  final double grossProfit;
  final double expenses;
  final double netProfit;
  final double netPurchases;

  const ProfitLoss({
    required this.period,
    required this.netSales,
    required this.chargesRecovered,
    required this.revenue,
    required this.costOfGoodsSold,
    required this.nonStockPurchases,
    required this.freightAndCharges,
    required this.grossProfit,
    required this.expenses,
    required this.netProfit,
    required this.netPurchases,
  });

  factory ProfitLoss.fromJson(Map<String, dynamic> json) {
    return ProfitLoss(
      period: Period.fromJson(asMap(json['period'])),
      netSales: asDouble(json['net_sales']),
      chargesRecovered: asDouble(json['charges_recovered']),
      revenue: asDouble(json['revenue']),
      costOfGoodsSold: asDouble(json['cost_of_goods_sold']),
      nonStockPurchases: asDouble(json['non_stock_purchases']),
      freightAndCharges: asDouble(json['freight_and_charges']),
      grossProfit: asDouble(json['gross_profit']),
      expenses: asDouble(json['expenses']),
      netProfit: asDouble(json['net_profit']),
      netPurchases: asDouble(json['net_purchases']),
    );
  }
}

class TaxTotals {
  final double taxable;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;

  const TaxTotals({
    required this.taxable,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
  });

  factory TaxTotals.fromJson(Map<String, dynamic> json) {
    return TaxTotals(
      taxable: asDouble(json['taxable']),
      cgst: asDouble(json['cgst']),
      sgst: asDouble(json['sgst']),
      igst: asDouble(json['igst']),
      cess: asDouble(json['cess']),
    );
  }

  double get totalTax => cgst + sgst + igst + cess;
}

class HsnSummaryRow {
  final String? hsnSac;
  final String? unitCode;
  final double taxRate;
  final double quantity;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double cess;

  const HsnSummaryRow({
    this.hsnSac,
    this.unitCode,
    required this.taxRate,
    required this.quantity,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.cess,
  });

  factory HsnSummaryRow.fromJson(Map<String, dynamic> json) {
    return HsnSummaryRow(
      hsnSac: json['hsn_sac'] as String?,
      unitCode: json['unit_code'] as String?,
      taxRate: asDouble(json['tax_rate']),
      quantity: asDouble(json['quantity']),
      taxableValue: asDouble(json['taxable_value']),
      cgst: asDouble(json['cgst']),
      sgst: asDouble(json['sgst']),
      igst: asDouble(json['igst']),
      cess: asDouble(json['cess']),
    );
  }
}

class GstSummary {
  final Period period;
  final TaxTotals output;

  /// GST on charges billed to customers (not split into CGST/SGST/IGST).
  final double outputChargesTax;
  final double b2bTaxable;
  final double b2cTaxable;
  final TaxTotals input;
  final double netTaxPayable;
  final double nonGstSales;
  final List<HsnSummaryRow> hsnSummary;

  const GstSummary({
    required this.period,
    required this.output,
    required this.outputChargesTax,
    required this.b2bTaxable,
    required this.b2cTaxable,
    required this.input,
    required this.netTaxPayable,
    required this.nonGstSales,
    required this.hsnSummary,
  });

  factory GstSummary.fromJson(Map<String, dynamic> json) {
    final output = asMap(json['output']);
    return GstSummary(
      period: Period.fromJson(asMap(json['period'])),
      output: TaxTotals.fromJson(output),
      outputChargesTax: asDouble(output['charges_tax']),
      b2bTaxable: asDouble(output['b2b_taxable']),
      b2cTaxable: asDouble(output['b2c_taxable']),
      input: TaxTotals.fromJson(asMap(json['input'])),
      netTaxPayable: asDouble(json['net_tax_payable']),
      nonGstSales: asDouble(json['non_gst_sales']),
      hsnSummary: asMapList(json['hsn_summary'])
          .map(HsnSummaryRow.fromJson)
          .toList(),
    );
  }
}

class DayBookEntry {
  /// 'invoice', 'payment', 'expense' or 'transfer'.
  final String kind;
  final String id;

  /// Invoice type, payment direction ('in'/'out'), 'expense' or 'transfer'.
  final String type;
  final String? number;
  final String? party;
  final double amount;
  final String status;
  final DateTime? createdAt;

  const DayBookEntry({
    required this.kind,
    required this.id,
    required this.type,
    this.number,
    this.party,
    required this.amount,
    required this.status,
    this.createdAt,
  });

  factory DayBookEntry.fromJson(Map<String, dynamic> json) {
    return DayBookEntry(
      kind: asString(json['kind']),
      id: asString(json['id']),
      type: asString(json['type']),
      number: json['number'] as String?,
      party: json['party'] as String?,
      amount: asDouble(json['amount']),
      status: asString(json['status']),
      createdAt: asDate(json['created_at']),
    );
  }
}

class DayBook {
  final DateTime date;
  final List<DayBookEntry> entries;

  const DayBook({required this.date, required this.entries});

  factory DayBook.fromJson(Map<String, dynamic> json) {
    return DayBook(
      date: asDate(json['date']) ?? DateTime.now(),
      entries: asMapList(json['entries']).map(DayBookEntry.fromJson).toList(),
    );
  }
}
