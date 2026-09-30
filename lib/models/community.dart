/// A community (entity of type "community"), from `/communities` or
/// `/me/communities`.
class Community {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final String? city;
  final String? state;
  final String? website;
  final int memberCount;
  final bool isJoined;
  final DateTime? joinedAt;

  Community({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.city,
    this.state,
    this.website,
    this.memberCount = 0,
    this.isJoined = false,
    this.joinedAt,
  });

  /// Up to two initials, for when there is no logo.
  String get monogram {
    final words = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) return '?';
    if (words.length == 1) return words.first[0].toUpperCase();
    return (words.first[0] + words.elementAt(1)[0]).toUpperCase();
  }

  /// The same community after she joins or leaves it.
  Community withMembership({required bool joined}) {
    return Community(
      id: id,
      name: name,
      description: description,
      logoUrl: logoUrl,
      bannerUrl: bannerUrl,
      city: city,
      state: state,
      website: website,
      memberCount: (memberCount + (joined ? 1 : -1)).clamp(0, 1 << 31),
      isJoined: joined,
      joinedAt: joined ? DateTime.now() : null,
    );
  }

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      logoUrl: json['logo_url'],
      bannerUrl: json['banner_url'],
      city: json['city'],
      state: json['state'],
      website: json['website'],
      memberCount: json['member_count'] ?? 0,
      isJoined: json['is_joined'] ?? false,
      joinedAt: DateTime.tryParse(json['joined_at'] ?? ''),
    );
  }

  static List<Community> listFrom(dynamic items) {
    if (items is! List) return [];
    return items
        .map((e) => Community.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
