import 'package:vyaparsetu/global/constants.dart';
import 'package:vyaparsetu/helpers/json.dart';

class StockAdjustmentLine {
  final String? id;
  final String itemId;
  final String? itemName;
  final String? unitCode;

  /// Positive adds stock, negative removes it.
  final double quantity;
  final double? unitCost;

  const StockAdjustmentLine({
    this.id,
    required this.itemId,
    this.itemName,
    this.unitCode,
    required this.quantity,
    this.unitCost,
  });

  factory StockAdjustmentLine.fromJson(Map<String, dynamic> json) {
    return StockAdjustmentLine(
      id: json['id'] as String?,
      itemId: asString(json['item_id']),
      itemName: json['item_name'] as String?,
      unitCode: json['unit_code'] as String?,
      quantity: asDouble(json['quantity']),
      unitCost: asDoubleOrNull(json['unit_cost']),
    );
  }
}

class StockAdjustment {
  final String id;
  final DateTime adjustmentDate;
  final AdjustmentReason reason;
  final String? notes;
  final RecordStatus status;
  final int lineCount;
  final DateTime? createdAt;

  /// Empty in list responses.
  final List<StockAdjustmentLine> lines;

  const StockAdjustment({
    required this.id,
    required this.adjustmentDate,
    required this.reason,
    this.notes,
    required this.status,
    required this.lineCount,
    this.createdAt,
    this.lines = const [],
  });

  factory StockAdjustment.fromJson(Map<String, dynamic> json) {
    final lines = asMapList(json['lines'])
        .map(StockAdjustmentLine.fromJson)
        .toList();
    return StockAdjustment(
      id: json['id'] as String,
      adjustmentDate: asDate(json['adjustment_date']) ?? DateTime.now(),
      reason: AdjustmentReason.fromString(json['reason'] as String?),
      notes: json['notes'] as String?,
      status: RecordStatus.fromString(json['status'] as String?),
      lineCount: asInt(json['line_count'], lines.length),
      createdAt: asDate(json['created_at']),
      lines: lines,
    );
  }

  bool get isCancelled => status == RecordStatus.cancelled;
}
