/// A file attached to a piece of feed content — an image, video or document.
class ContentAttachment {
  final int id;
  final String title;
  final String fileName;
  final String fileType;
  final String fileUrl;

  ContentAttachment({
    required this.id,
    required this.title,
    required this.fileName,
    required this.fileType,
    required this.fileUrl,
  });

  static const _videoExtensions = ['.mp4', '.mov', '.m4v', '.webm', '.m3u8'];
  static const _imageExtensions = ['.png', '.jpg', '.jpeg', '.gif', '.webp'];

  /// The admin panel stores a MIME type (`video/mp4`), but older rows may
  /// carry a bare kind or extension, so the file name is checked as well.
  bool get isVideo =>
      fileType.toLowerCase().startsWith('video') ||
      _videoExtensions.any(fileName.toLowerCase().endsWith);

  bool get isImage =>
      fileType.toLowerCase().startsWith('image') ||
      _imageExtensions.any(fileName.toLowerCase().endsWith);

  factory ContentAttachment.fromJson(Map<String, dynamic> json) {
    return ContentAttachment(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      fileName: json['file_name'] ?? '',
      fileType: json['file_type'] ?? '',
      fileUrl: json['file_url'] ?? '',
    );
  }
}

/// One item of the Feeds tab, from `/me/content`.
class FeedContent {
  final int id;
  final String title;
  final String description;
  final String viewType;
  final List<String> tags;
  final List<ContentAttachment> attachments;
  int likes;
  int comments;
  bool isLiked;

  FeedContent({
    required this.id,
    required this.title,
    required this.description,
    required this.viewType,
    this.tags = const [],
    this.attachments = const [],
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
  });

  /// `reels` is what the admin panel saves; `reel` is accepted too.
  bool get isReel => viewType.toLowerCase().startsWith('reel');

  /// The video a reel plays: its first video attachment.
  ContentAttachment? get reelVideo {
    for (final a in attachments) {
      if (a.isVideo && a.fileUrl.isNotEmpty) return a;
    }
    return null;
  }

  /// The pill above the title: the first tag, `pregnancy_week_1` shown as
  /// `PREGNANCY WEEK 1`, with reels marked as such.
  String get label {
    final tag = tags.isEmpty
        ? ''
        : tags.first.replaceAll(RegExp(r'[_-]+'), ' ').trim().toUpperCase();
    if (!isReel) return tag;
    return tag.isEmpty ? 'REEL' : '$tag - REEL';
  }

  factory FeedContent.fromJson(Map<String, dynamic> json) {
    final attachments = json['attachments'];
    return FeedContent(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      viewType: json['view_type'] ?? '',
      tags: (json['tags'] as List? ?? []).map((t) => t.toString()).toList(),
      attachments: attachments is List
          ? attachments
              .map((e) =>
                  ContentAttachment.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : [],
      likes: json['like_count'] ?? 0,
      comments: json['comment_count'] ?? 0,
      isLiked: json['is_liked'] ?? false,
    );
  }

  static List<FeedContent> listFrom(dynamic items) {
    if (items is! List) return [];
    return items
        .map((e) => FeedContent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}

/// A comment on a feed item, from `/me/content/{id}/comments`.
class ContentComment {
  final int id;
  final String comment;
  final String authorName;
  final String? authorPicture;
  final bool isMine;
  final DateTime? createdAt;

  ContentComment({
    required this.id,
    required this.comment,
    required this.authorName,
    this.authorPicture,
    this.isMine = false,
    this.createdAt,
  });

  String get initial =>
      authorName.trim().isEmpty ? '?' : authorName.trim()[0].toUpperCase();

  factory ContentComment.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map
        ? Map<String, dynamic>.from(json['user'])
        : <String, dynamic>{};
    final created = DateTime.tryParse(json['createdAt'] ?? '');
    return ContentComment(
      id: json['id'] ?? 0,
      comment: json['comment'] ?? '',
      authorName: user['name'] ?? 'AlloMom user',
      authorPicture: user['profile_picture'],
      isMine: json['is_mine'] ?? false,
      // The server stores naive UTC timestamps.
      createdAt: created == null
          ? null
          : (created.isUtc
              ? created
              : DateTime.utc(created.year, created.month, created.day,
                  created.hour, created.minute, created.second,
                  created.millisecond, created.microsecond)),
    );
  }

  static List<ContentComment> listFrom(dynamic items) {
    if (items is! List) return [];
    return items
        .map((e) => ContentComment.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
