class FactorySummary {
  final String factoryId;
  final int totalBricks;
  final double totalAmount;
  final double totalMoneyGiven;
  final List<WorkerSummaryEntry> workersSummary;

  FactorySummary({
    required this.factoryId,
    required this.totalBricks,
    required this.totalAmount,
    required this.totalMoneyGiven,
    this.workersSummary = const [],
  });

  int get workerCount => workersSummary.length;
  double get balanceDue => totalAmount - totalMoneyGiven;

  FactorySummary copyWith({
    String? factoryId,
    int? totalBricks,
    double? totalAmount,
    double? totalMoneyGiven,
    List<WorkerSummaryEntry>? workersSummary,
  }) {
    return FactorySummary(
      factoryId: factoryId ?? this.factoryId,
      totalBricks: totalBricks ?? this.totalBricks,
      totalAmount: totalAmount ?? this.totalAmount,
      totalMoneyGiven: totalMoneyGiven ?? this.totalMoneyGiven,
      workersSummary: workersSummary ?? this.workersSummary,
    );
  }

  factory FactorySummary.fromJson(Map<String, dynamic> json) {
    final workers = (json['workers_summary'] as List<dynamic>?)
            ?.map((e) =>
                WorkerSummaryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return FactorySummary(
      factoryId: json['factory_id'] as String? ?? '',
      totalBricks:
          int.tryParse(json['total_bricks_produced']?.toString() ?? '') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount_owed']?.toString() ?? '0') ?? 0.0,
      totalMoneyGiven:
          double.tryParse(json['total_money_given']?.toString() ?? '0') ?? 0.0,
      workersSummary: workers,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'factory_id': factoryId,
      'total_bricks_produced': totalBricks,
      'total_amount_owed': totalAmount,
      'total_money_given': totalMoneyGiven,
      'workers_summary': workersSummary.map((e) => e.toJson()).toList(),
    };
  }
}

class WorkerSummaryEntry {
  final String workerId;
  final String name;
  final String type;
  final int totalBricks;
  final double totalAmount;
  final double totalMoneyGiven;
  final double balanceDue;

  WorkerSummaryEntry({
    required this.workerId,
    required this.name,
    required this.type,
    required this.totalBricks,
    required this.totalAmount,
    required this.totalMoneyGiven,
    required this.balanceDue,
  });

  factory WorkerSummaryEntry.fromJson(Map<String, dynamic> json) {
    return WorkerSummaryEntry(
      workerId: json['worker_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'producer_molder',
      totalBricks: int.tryParse(json['total_bricks']?.toString() ?? '') ?? 0,
      totalAmount:
          double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      totalMoneyGiven:
          double.tryParse(json['total_money_given']?.toString() ?? '0') ?? 0.0,
      balanceDue:
          double.tryParse(json['balance_due']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'worker_id': workerId,
      'name': name,
      'type': type,
      'total_bricks': totalBricks,
      'total_amount': totalAmount,
      'total_money_given': totalMoneyGiven,
      'balance_due': balanceDue,
    };
  }
}
