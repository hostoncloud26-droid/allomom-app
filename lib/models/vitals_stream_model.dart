class VitalsStreamResponse {
  final String id;
  final String key;
  final double value;
  final String unit;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  VitalsStreamResponse({
    required this.id,
    required this.key,
    required this.value,
    required this.unit,
    required this.createdAt,
    this.data,
  });

  factory VitalsStreamResponse.fromJson(Map<String, dynamic> json) {
    return VitalsStreamResponse(
      id: json['id']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      value: (json['value'] is num) ? (json['value'] as num).toDouble() : 0.0,
      unit: json['unit']?.toString() ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      data: json['data'] is Map<String, dynamic> ? json['data'] as Map<String, dynamic> : null,
    );
  }

  static List<VitalsStreamResponse> fromJsonArray(List<dynamic> jsonArray) {
    return jsonArray
        .whereType<Map<String, dynamic>>()
        .map((json) => VitalsStreamResponse.fromJson(json))
        .toList();
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'key': key,
        'value': value,
        'unit': unit,
        'createdAt': createdAt.toIso8601String(),
        if (data != null) 'data': data,
      };
}
