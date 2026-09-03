class ReminderData {
  final String? id;
  final String? frequency;
  final String? reminderType;
  final String? userId;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final List<String>? channels;
  final bool? enabled;
  final bool? configurable;

  ReminderData({
    this.id,
    this.frequency,
    this.reminderType,
    this.userId,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.channels,
    this.enabled,
    this.configurable = true,
  });

  factory ReminderData.fromJson(Map<String, dynamic> json) {
    return ReminderData(
      id: json['id'] as String? ?? json['_id'] as String?,
      frequency: json['frequency'] as String? ?? 'Daily',
      reminderType: json['reminder_type'] as String? ?? json['remainder_type'] as String? ?? json['type'] as String?,
      userId: json['userid'] as String? ?? json['user_id'] as String?,
      startDate: json['start_date'] != null ? DateTime.tryParse(json['start_date'].toString()) : null,
      endDate: json['end_date'] != null ? DateTime.tryParse(json['end_date'].toString()) : null,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'].toString()) : null,
      channels: json['channels'] != null ? List<String>.from(json['channels'] as List) : null,
      enabled: json['enabled'] as bool? ?? true,
      configurable: json['configurable'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'frequency': frequency,
      'reminder_type': reminderType,
      'userid': userId,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'channels': channels,
      'enabled': enabled,
      'configurable': configurable,
    };
  }
}
