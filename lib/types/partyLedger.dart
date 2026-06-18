class PartyLedger {
  final PartyLedgerInfo party;
  final List<LedgerEntry> ledger;

  PartyLedger({
    required this.party,
    required this.ledger,
  });

  factory PartyLedger.fromJson(Map<String, dynamic> json) {
    return PartyLedger(
      party: PartyLedgerInfo.fromJson(Map<String, dynamic>.from(json['party'] ?? {})),
      ledger: json['ledger'] != null
          ? (json['ledger'] as List)
              .map((e) => LedgerEntry.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'party': party.toJson(),
      'ledger': ledger.map((e) => e.toJson()).toList(),
    };
  }
}

class PartyLedgerInfo {
  final String id;
  final String name;
  final double openingBalance;
  final String openingBalanceType;
  final double currentBalance;

  PartyLedgerInfo({
    required this.id,
    required this.name,
    required this.openingBalance,
    required this.openingBalanceType,
    required this.currentBalance,
  });

  factory PartyLedgerInfo.fromJson(Map<String, dynamic> json) {
    return PartyLedgerInfo(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      openingBalance: double.tryParse(json['opening_balance']?.toString() ?? '0') ?? 0.0,
      openingBalanceType: json['opening_balance_type'] as String? ?? 'receive',
      currentBalance: double.tryParse(json['current_balance']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'opening_balance': openingBalance,
      'opening_balance_type': openingBalanceType,
      'current_balance': currentBalance,
    };
  }
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String type;
  final String refNo;
  final double totalAmount;
  final double paidAmount;
  final double balanceEffect;
  final double runningBalance;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.type,
    required this.refNo,
    required this.totalAmount,
    required this.paidAmount,
    required this.balanceEffect,
    required this.runningBalance,
  });

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    return LedgerEntry(
      id: json['id'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String).toLocal()
          : DateTime.now(),
      type: json['type'] as String? ?? '',
      refNo: json['ref_no'] as String? ?? '',
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      paidAmount: double.tryParse(json['paid_amount']?.toString() ?? '0') ?? 0.0,
      balanceEffect: double.tryParse(json['balance_effect']?.toString() ?? '0') ?? 0.0,
      runningBalance: double.tryParse(json['running_balance']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toUtc().toIso8601String(),
      'type': type,
      'ref_no': refNo,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'balance_effect': balanceEffect,
      'running_balance': runningBalance,
    };
  }
}
