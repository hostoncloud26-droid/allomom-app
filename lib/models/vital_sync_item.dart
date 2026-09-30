
import 'package:uuid/uuid.dart';

class VitalSyncItem {
  final String id;
  final String key;
  final double value;
  final String unit;
  final DateTime? createdAt;
  final Map<String, dynamic>? data;

  VitalSyncItem({
    String? id,
    required this.key,
    required this.value,
    required this.unit,
    this.createdAt,
    this.data,
  }) : id = id ?? const Uuid().v7();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'key': key,
      'value': value,
      'unit': unit,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (data != null) 'data': data,
    };
  }

  factory VitalSyncItem.fromJson(Map<String, dynamic> json) {
    return VitalSyncItem(
      id: json['id'] as String?,
      key: json['key'] as String,
      value: (json['value'] as num).toDouble(),
      unit: json['unit'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      data: json['data'] as Map<String, dynamic>?,
    );
  }
}

