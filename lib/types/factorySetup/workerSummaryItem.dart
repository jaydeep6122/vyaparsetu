class WorkerSummaryItem {
  final DateTime date;
  final double amount;
  final String? notes;

  WorkerSummaryItem({
    required this.date,
    required this.amount,
    this.notes,
  });

  factory WorkerSummaryItem.fromJson(Map<String, dynamic> json) {
    return WorkerSummaryItem(
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String).toLocal()
          : DateTime.now(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      notes: json['notes'] as String?,
    );
  }
}
