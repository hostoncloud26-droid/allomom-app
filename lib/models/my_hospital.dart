/// A hospital the mother added herself, from `/me/hospital`.
class MyHospital {
  final int userEntityId;
  final String entityId;
  final String name;
  final String? address;
  final String? contact;
  final String? website;
  final String? mapsUrl;
  final String? category;
  final double? rating;
  final int? ratingCount;
  final DateTime? addedAt;
  final DateTime? leftAt;

  MyHospital({
    required this.userEntityId,
    required this.entityId,
    required this.name,
    this.address,
    this.contact,
    this.website,
    this.mapsUrl,
    this.category,
    this.rating,
    this.ratingCount,
    this.addedAt,
    this.leftAt,
  });

  bool get hasLeft => leftAt != null;

  factory MyHospital.fromJson(Map<String, dynamic> json) {
    return MyHospital(
      userEntityId: json['user_entity_id'],
      entityId: json['entity_id'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      contact: json['contact'],
      website: json['website'],
      mapsUrl: json['maps_url'],
      category: json['category'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'],
      addedAt: DateTime.tryParse(json['added_at'] ?? ''),
      leftAt: DateTime.tryParse(json['left_at'] ?? ''),
    );
  }
}

/// A Google Maps search result, kept raw so it can be sent back as-is when
/// the mother picks it.
class HospitalPlace {
  final String name;
  final String? address;
  final String? category;
  final double? rating;
  final int? ratingCount;
  final Map<String, dynamic> raw;

  HospitalPlace({
    required this.name,
    this.address,
    this.category,
    this.rating,
    this.ratingCount,
    this.raw = const {},
  });

  factory HospitalPlace.fromJson(Map<String, dynamic> json) {
    return HospitalPlace(
      name: json['name'] ?? '',
      address: json['address'],
      category: json['category'],
      rating: (json['rating'] as num?)?.toDouble(),
      ratingCount: json['rating_count'],
      raw: json,
    );
  }
}
