import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/types/factorySetup/workerSummaryItem.dart';

class WorkerSummary {
  final String workerId;
  final String name;
  final String type;
  final double? ratePer1000;
  final int totalBricks;
  final double totalAmount;
  final double totalMoneyGiven;
  final double balanceDue;
  final List<WorkerSummaryItem> moneyTransactions;

  WorkerSummary({
    required this.workerId,
    required this.name,
    required this.type,
    this.ratePer1000,
    required this.totalBricks,
    required this.totalAmount,
    required this.totalMoneyGiven,
    required this.balanceDue,
    this.moneyTransactions = const [],
  });

  factory WorkerSummary.fromJson(Map<String, dynamic> json) {
    final wages = json['wages'] != null ? Map<String, dynamic>.from(json['wages'] as Map) : {};
    final money = json['money'] != null ? Map<String, dynamic>.from(json['money'] as Map) : {};
    final transactions = (money['transactions'] as List<dynamic>?)
            ?.map((e) => WorkerSummaryItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList() ??
        [];

    return WorkerSummary(
      workerId: json['worker_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'producer_molder',
      ratePer1000: double.tryParse(json['rate_per_1000']?.toString() ?? ''),
      totalBricks: int.tryParse(wages['total_bricks']?.toString() ?? '') ?? 0,
      totalAmount: double.tryParse(wages['total_amount']?.toString() ?? '0') ?? 0.0,
      totalMoneyGiven: double.tryParse(money['total_given']?.toString() ?? '0') ?? 0.0,
      balanceDue: double.tryParse(json['balance_due']?.toString() ?? '0') ?? 0.0,
      moneyTransactions: transactions,
    );
  }

  WorkerType get workerType => WorkerType.fromString(type);
}
