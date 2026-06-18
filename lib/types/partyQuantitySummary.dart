class ItemQuantityBreakdown {
  final String? itemId;
  final String itemName;
  final double sold;
  final double purchased;
  final double saleReturned;
  final double purchaseReturned;

  ItemQuantityBreakdown({
    this.itemId,
    required this.itemName,
    required this.sold,
    required this.purchased,
    required this.saleReturned,
    required this.purchaseReturned,
  });

  factory ItemQuantityBreakdown.fromJson(Map<String, dynamic> json) {
    return ItemQuantityBreakdown(
      itemId: json['item_id'] as String?,
      itemName: json['item_name'] as String? ?? 'Deleted Item',
      sold: (json['sold'] as num?)?.toDouble() ?? 0,
      purchased: (json['purchased'] as num?)?.toDouble() ?? 0,
      saleReturned: (json['sale_returned'] as num?)?.toDouble() ?? 0,
      purchaseReturned: (json['purchase_returned'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'sold': sold,
      'purchased': purchased,
      'sale_returned': saleReturned,
      'purchase_returned': purchaseReturned,
    };
  }
}

class PartyQuantitySummary {
  final String partyId;
  final List<ItemQuantityBreakdown> items;

  PartyQuantitySummary({
    required this.partyId,
    required this.items,
  });

  factory PartyQuantitySummary.fromJson(Map<String, dynamic> json) {
    return PartyQuantitySummary(
      partyId: json['partyId'] as String? ?? '',
      items: json['items'] != null
          ? (json['items'] as List)
              .map((e) => ItemQuantityBreakdown.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partyId': partyId,
      'items': items.map((e) => e.toJson()).toList(),
    };
  }
}
