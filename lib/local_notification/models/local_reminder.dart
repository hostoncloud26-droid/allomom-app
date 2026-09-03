/// Enum representing different types of health and pregnancy reminders
enum LocalReminderType {
  drinkWater('drink_water', '💧 Drink Water', 'Stay hydrated! Time to drink some water for you and baby.'),
  sleepReminder('sleep_reminder', '😴 Sleep Reminder', 'Time to wind down and get restful pregnancy sleep.'),
  wakeUpReminder('wake_up_reminder', '🌞 Wake-Up Reminder', 'Good morning, Amma! Rise and shine!'),
  breakfast('breakfast', '🍳 Breakfast Reminder', "Don't skip breakfast! Nourish your body and baby."),
  lunch('lunch', '🥗 Lunch Reminder', "It's lunchtime! Take a healthy break and eat well."),
  dinner('dinner', '🍽️ Dinner Reminder', "Dinner time! Fuel up for a restful night."),
  morningExercise('morning_exercise', '🧘 Prenatal Yoga / Morning Exercise', "Time for your gentle morning stretches!"),
  eveningExercise('evening_exercise', '🚶 Evening Gentle Walk', "Time for a relaxing evening walk!"),
  medicineReminder('medicine_reminder', '💊 Medication Reminder', "Time to take your scheduled pregnancy supplements and medicines.");

  final String key;
  final String label;
  final String defaultMessage;

  const LocalReminderType(this.key, this.label, this.defaultMessage);

  /// Unique notification ID base for each type
  int get notificationIdBase {
    switch (this) {
      case LocalReminderType.drinkWater:
        return 1000;
      case LocalReminderType.sleepReminder:
        return 1400;
      case LocalReminderType.wakeUpReminder:
        return 1500;
      case LocalReminderType.breakfast:
        return 1600;
      case LocalReminderType.lunch:
        return 1700;
      case LocalReminderType.dinner:
        return 1800;
      case LocalReminderType.morningExercise:
        return 2000;
      case LocalReminderType.eveningExercise:
        return 2100;
      case LocalReminderType.medicineReminder:
        return 3000;
    }
  }

  /// Default interval in minutes for interval-based reminders
  int get defaultIntervalMinutes {
    switch (this) {
      case LocalReminderType.drinkWater:
        return 120; // Every 2 hours
      default:
        return 0; // Fixed time
    }
  }

  /// Whether this reminder uses interval-based scheduling vs fixed time
  bool get isIntervalBased {
    switch (this) {
      case LocalReminderType.drinkWater:
        return true;
      default:
        return false;
    }
  }

  /// Default fixed time (hour, minute)
  Map<String, int> get defaultTime {
    switch (this) {
      case LocalReminderType.sleepReminder:
        return {'hour': 22, 'minute': 0}; // 10:00 PM
      case LocalReminderType.wakeUpReminder:
        return {'hour': 6, 'minute': 30}; // 6:30 AM
      case LocalReminderType.breakfast:
        return {'hour': 8, 'minute': 0}; // 8:00 AM
      case LocalReminderType.lunch:
        return {'hour': 13, 'minute': 0}; // 1:00 PM
      case LocalReminderType.dinner:
        return {'hour': 19, 'minute': 30}; // 7:30 PM
      case LocalReminderType.morningExercise:
        return {'hour': 7, 'minute': 0}; // 7:00 AM
      case LocalReminderType.eveningExercise:
        return {'hour': 17, 'minute': 30}; // 5:30 PM
      case LocalReminderType.medicineReminder:
        return {'hour': 8, 'minute': 0}; // 8:00 AM
      default:
        return {'hour': 9, 'minute': 0};
    }
  }

  /// Default active hours for interval-based reminders
  Map<String, int> get defaultActiveHours {
    switch (this) {
      case LocalReminderType.drinkWater:
        return {'startHour': 7, 'endHour': 21}; // 7 AM - 9 PM
      default:
        return {'startHour': 8, 'endHour': 20};
    }
  }

  static LocalReminderType? fromKey(String key) {
    try {
      return LocalReminderType.values.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }
}

/// Model representing a user's local reminder configuration
class LocalReminderConfig {
  final LocalReminderType type;
  bool enabled;
  int intervalMinutes;
  int hour;
  int minute;
  int startHour;
  int endHour;

  LocalReminderConfig({
    required this.type,
    this.enabled = false,
    int? intervalMinutes,
    int? hour,
    int? minute,
    int? startHour,
    int? endHour,
  })  : intervalMinutes = intervalMinutes ?? type.defaultIntervalMinutes,
        hour = hour ?? type.defaultTime['hour']!,
        minute = minute ?? type.defaultTime['minute']!,
        startHour = startHour ?? type.defaultActiveHours['startHour']!,
        endHour = endHour ?? type.defaultActiveHours['endHour']!;

  factory LocalReminderConfig.fromJson(Map<String, dynamic> json) {
    final type = LocalReminderType.fromKey(json['type'] as String);
    if (type == null) {
      throw ArgumentError('Unknown reminder type: ${json['type']}');
    }
    return LocalReminderConfig(
      type: type,
      enabled: json['enabled'] as bool? ?? false,
      intervalMinutes: json['intervalMinutes'] as int?,
      hour: json['hour'] as int?,
      minute: json['minute'] as int?,
      startHour: json['startHour'] as int?,
      endHour: json['endHour'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.key,
      'enabled': enabled,
      'intervalMinutes': intervalMinutes,
      'hour': hour,
      'minute': minute,
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  LocalReminderConfig copyWith({
    bool? enabled,
    int? intervalMinutes,
    int? hour,
    int? minute,
    int? startHour,
    int? endHour,
  }) {
    return LocalReminderConfig(
      type: type,
      enabled: enabled ?? this.enabled,
      intervalMinutes: intervalMinutes ?? this.intervalMinutes,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
    );
  }

  String get formattedTime {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String get formattedInterval {
    if (intervalMinutes >= 60) {
      final hours = intervalMinutes ~/ 60;
      final mins = intervalMinutes % 60;
      if (mins == 0) return 'Every ${hours}h';
      return 'Every ${hours}h ${mins}m';
    }
    return 'Every ${intervalMinutes}m';
  }

  String get formattedActiveHours {
    String format(int h) {
      final displayH = h % 12 == 0 ? 12 : h % 12;
      final period = h >= 12 ? 'PM' : 'AM';
      return '$displayH:00 $period';
    }

    return '${format(startHour)} - ${format(endHour)}';
  }
}
