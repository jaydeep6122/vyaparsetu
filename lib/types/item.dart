class Item {
  final String id;
  final String businessId;
  final String name;
  final String? hsnCode;
  final String measuringUnit;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.businessId,
    required this.name,
    this.hsnCode,
    required this.measuringUnit,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      businessId: json['business_id'] as String? ?? '',
      name: json['name'] as String,
      hsnCode: json['hsn_code'] as String?,
      measuringUnit: json['measuring_unit'] as String? ?? 'pcs',
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
      'business_id': businessId,
      'name': name,
      'hsn_code': hsnCode,
      'measuring_unit': measuringUnit,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? businessId,
    String? name,
    String? hsnCode,
    String? measuringUnit,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      hsnCode: hsnCode ?? this.hsnCode,
      measuringUnit: measuringUnit ?? this.measuringUnit,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
