import 'package:vyaparsetu/global/constants.dart';

class Worker {
  final String id;
  final String factoryId;
  final String name;
  final WorkerType workerType;
  final double? ratePer1000;
  final int totalBricks;
  final double totalAmount;
  final double totalMoneyGiven;
  final double balanceDue;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Worker({
    required this.id,
    required this.factoryId,
    required this.name,
    required this.workerType,
    this.ratePer1000,
    this.totalBricks = 0,
    this.totalAmount = 0.0,
    this.totalMoneyGiven = 0.0,
    this.balanceDue = 0.0,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
  });

  factory Worker.fromJson(Map<String, dynamic> json) {
    return Worker(
      id: json['id'] as String,
      factoryId: json['factory_id'] as String,
      name: json['name'] as String,
      workerType: WorkerType.fromString(json['worker_type'] as String? ?? json['type'] as String? ?? 'producer_molder'),
      ratePer1000: double.tryParse(json['rate_per_1000']?.toString() ?? ''),
      totalBricks: int.tryParse(json['total_bricks']?.toString() ?? '') ?? 0,
      totalAmount: double.tryParse(json['total_amount']?.toString() ?? '0') ?? 0.0,
      totalMoneyGiven: double.tryParse(json['total_money_given']?.toString() ?? '0') ?? 0.0,
      balanceDue: double.tryParse(json['balance_due']?.toString() ?? '0') ?? 0.0,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String).toLocal()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'factory_id': factoryId,
      'name': name,
      'worker_type': workerType.value,
      'rate_per_1000': ratePer1000,
      'total_bricks': totalBricks,
      'total_amount': totalAmount,
      'total_money_given': totalMoneyGiven,
      'balance_due': balanceDue,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Worker copyWith({
    String? id,
    String? factoryId,
    String? name,
    WorkerType? workerType,
    double? ratePer1000,
    int? totalBricks,
    double? totalAmount,
    double? totalMoneyGiven,
    double? balanceDue,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Worker(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      name: name ?? this.name,
      workerType: workerType ?? this.workerType,
      ratePer1000: ratePer1000 ?? this.ratePer1000,
      totalBricks: totalBricks ?? this.totalBricks,
      totalAmount: totalAmount ?? this.totalAmount,
      totalMoneyGiven: totalMoneyGiven ?? this.totalMoneyGiven,
      balanceDue: balanceDue ?? this.balanceDue,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
