import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

class Item {
  final String id;
  final String name;
  final ItemType itemType;
  final String? categoryId;
  final String? categoryName;
  final String? sku;
  final String? barcode;
  final String? hsnSac;

  /// GST unit code, e.g. NOS, KGS, BAG.
  final String unitCode;
  final double? salePrice;
  final double? purchasePrice;
  final bool priceIncludesTax;
  final String? taxRateId;

  /// GST rate % of the linked tax rate.
  final double? taxRate;
  final double? cessRate;
  final bool trackStock;
  final double? lowStockThreshold;

  /// Null for items that do not track stock.
  final double? quantityOnHand;
  final double? openingStock;
  final double? openingStockRate;
  final DateTime? openingStockDate;
  final DateTime? archivedAt;

  const Item({
    required this.id,
    required this.name,
    required this.itemType,
    this.categoryId,
    this.categoryName,
    this.sku,
    this.barcode,
    this.hsnSac,
    required this.unitCode,
    this.salePrice,
    this.purchasePrice,
    required this.priceIncludesTax,
    this.taxRateId,
    this.taxRate,
    this.cessRate,
    required this.trackStock,
    this.lowStockThreshold,
    this.quantityOnHand,
    this.openingStock,
    this.openingStockRate,
    this.openingStockDate,
    this.archivedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: asString(json['name']),
      itemType: ItemType.fromString(json['item_type'] as String?),
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      sku: json['sku'] as String?,
      barcode: json['barcode'] as String?,
      hsnSac: json['hsn_sac'] as String?,
      unitCode: asString(json['unit_code'], 'NOS'),
      salePrice: asDoubleOrNull(json['sale_price']),
      purchasePrice: asDoubleOrNull(json['purchase_price']),
      priceIncludesTax: asBool(json['price_includes_tax']),
      taxRateId: json['tax_rate_id'] as String?,
      taxRate: asDoubleOrNull(json['tax_rate']),
      cessRate: asDoubleOrNull(json['cess_rate']),
      trackStock: asBool(json['track_stock'], true),
      lowStockThreshold: asDoubleOrNull(json['low_stock_threshold']),
      quantityOnHand: asDoubleOrNull(json['quantity_on_hand']),
      openingStock: asDoubleOrNull(json['opening_stock']),
      openingStockRate: asDoubleOrNull(json['opening_stock_rate']),
      openingStockDate: asDate(json['opening_stock_date']),
      archivedAt: asDate(json['archived_at']),
    );
  }

  bool get isArchived => archivedAt != null;

  bool get isLowStock =>
      trackStock &&
      lowStockThreshold != null &&
      (quantityOnHand ?? 0) <= lowStockThreshold!;

  /// The price to suggest on a new line for this kind of invoice.
  double? priceFor(InvoiceType type) =>
      type.isSaleSide ? salePrice : purchasePrice;
}

class TaxRate {
  final String id;
  final String name;
  final double rate;
  final double cessRate;
  final bool isActive;

  const TaxRate({
    required this.id,
    required this.name,
    required this.rate,
    required this.cessRate,
    required this.isActive,
  });

  factory TaxRate.fromJson(Map<String, dynamic> json) {
    return TaxRate(
      id: json['id'] as String,
      name: asString(json['name']),
      rate: asDouble(json['rate']),
      cessRate: asDouble(json['cess_rate']),
      isActive: asBool(json['is_active'], true),
    );
  }
}

class Category {
  final String id;
  final String name;
  final DateTime? archivedAt;

  const Category({required this.id, required this.name, this.archivedAt});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: asString(json['name']),
      archivedAt: asDate(json['archived_at']),
    );
  }

  bool get isArchived => archivedAt != null;
}
