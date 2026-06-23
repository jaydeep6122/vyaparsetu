class Factory {
  final String id;
  final String name;
  final String? location;
  final String status;
  final int workerCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Factory({
    required this.id,
    required this.name,
    this.location,
    this.status = 'active',
    this.workerCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Factory.fromJson(Map<String, dynamic> json) {
    return Factory(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String?,
      status: json['status'] as String? ?? 'active',
      workerCount: int.tryParse(json['worker_count']?.toString() ?? '') ?? 0,
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
      'name': name,
      'location': location,
      'status': status,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Factory copyWith({
    String? id,
    String? name,
    String? location,
    String? status,
    int? workerCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Factory(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      workerCount: workerCount ?? this.workerCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
