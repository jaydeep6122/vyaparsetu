class QuantityStats {
  final double sold;
  final double purchased;
  final double saleReturned;
  final double purchaseReturned;

  double get netStock => purchased - sold + saleReturned - purchaseReturned;

  QuantityStats({
    required this.sold,
    required this.purchased,
    required this.saleReturned,
    required this.purchaseReturned,
  });

  factory QuantityStats.fromJson(Map<String, dynamic> json) {
    return QuantityStats(
      sold: (json['sold'] as num?)?.toDouble() ?? 0,
      purchased: (json['purchased'] as num?)?.toDouble() ?? 0,
      saleReturned: (json['sale_returned'] as num?)?.toDouble() ?? 0,
      purchaseReturned: (json['purchase_returned'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sold': sold,
      'purchased': purchased,
      'sale_returned': saleReturned,
      'purchase_returned': purchaseReturned,
    };
  }
}

class PartyQuantityBreakdown {
  final String? partyId;
  final String partyName;
  final double sold;
  final double purchased;
  final double saleReturned;
  final double purchaseReturned;

  PartyQuantityBreakdown({
    this.partyId,
    required this.partyName,
    required this.sold,
    required this.purchased,
    required this.saleReturned,
    required this.purchaseReturned,
  });

  factory PartyQuantityBreakdown.fromJson(Map<String, dynamic> json) {
    return PartyQuantityBreakdown(
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String? ?? 'Walk-in/Unknown',
      sold: (json['sold'] as num?)?.toDouble() ?? 0,
      purchased: (json['purchased'] as num?)?.toDouble() ?? 0,
      saleReturned: (json['sale_returned'] as num?)?.toDouble() ?? 0,
      purchaseReturned: (json['purchase_returned'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'party_id': partyId,
      'party_name': partyName,
      'sold': sold,
      'purchased': purchased,
      'sale_returned': saleReturned,
      'purchase_returned': purchaseReturned,
    };
  }
}

class ItemQuantitySummary {
  final String itemId;
  final QuantityStats overall;
  final List<PartyQuantityBreakdown> byParty;

  ItemQuantitySummary({
    required this.itemId,
    required this.overall,
    required this.byParty,
  });

  factory ItemQuantitySummary.fromJson(Map<String, dynamic> json) {
    return ItemQuantitySummary(
      itemId: json['itemId'] as String? ?? '',
      overall: QuantityStats.fromJson(Map<String, dynamic>.from(json['overall'] ?? {})),
      byParty: json['byParty'] != null
          ? (json['byParty'] as List)
              .map((e) => PartyQuantityBreakdown.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'overall': overall.toJson(),
      'byParty': byParty.map((e) => e.toJson()).toList(),
    };
  }
}
