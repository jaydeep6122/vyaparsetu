import 'package:vyaparsetu/global/constants.dart';

class TransactionLog {
  final String id;
  final String factoryId;
  final TransactionType transactionType;
  final String? workerId;
  final String? kilnWorkerId;
  final String? producerMolderId;
  final List<String> truckWorkerIds;
  final int? quantity;
  final double amount;
  final DateTime date;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionLog({
    required this.id,
    required this.factoryId,
    required this.transactionType,
    this.workerId,
    this.kilnWorkerId,
    this.producerMolderId,
    this.truckWorkerIds = const [],
    this.quantity,
    required this.amount,
    required this.date,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionLog.fromJson(Map<String, dynamic> json) {
    return TransactionLog(
      id: json['id'] as String,
      factoryId: json['factory_id'] as String,
      transactionType: TransactionType.fromString(json['transaction_type'] as String? ?? json['type'] as String? ?? 'handoff'),
      workerId: json['worker_id'] as String?,
      kilnWorkerId: json['kiln_worker_id'] as String?,
      producerMolderId: json['producer_molder_id'] as String?,
      truckWorkerIds: (json['truck_worker_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      quantity: int.tryParse(json['quantity']?.toString() ?? ''),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String).toLocal()
          : DateTime.now(),
      notes: json['notes'] as String?,
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
      'transaction_type': transactionType.value,
      'worker_id': workerId,
      'kiln_worker_id': kilnWorkerId,
      'producer_molder_id': producerMolderId,
      'truck_worker_ids': truckWorkerIds,
      'quantity': quantity,
      'amount': amount,
      'date': date.toUtc().toIso8601String(),
      'notes': notes,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  TransactionLog copyWith({
    String? id,
    String? factoryId,
    TransactionType? transactionType,
    String? workerId,
    String? kilnWorkerId,
    String? producerMolderId,
    List<String>? truckWorkerIds,
    int? quantity,
    double? amount,
    DateTime? date,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionLog(
      id: id ?? this.id,
      factoryId: factoryId ?? this.factoryId,
      transactionType: transactionType ?? this.transactionType,
      workerId: workerId ?? this.workerId,
      kilnWorkerId: kilnWorkerId ?? this.kilnWorkerId,
      producerMolderId: producerMolderId ?? this.producerMolderId,
      truckWorkerIds: truckWorkerIds ?? this.truckWorkerIds,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
