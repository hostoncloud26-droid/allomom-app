/// One sleep session's window and stages, as AlloConnect's
/// `SleepResponseMapModel` reads a `sleep_data` row: snake_case keys, stage
/// durations in minutes.
///
/// Allomom rows are read too: the camelCase spellings, and the manual `sleep`
/// row the ported entry sheet writes (the same snake_case window plus
/// Allomom's `totalMinutes` / `deepSleep` / `lightSleep` fields).
class SleepResponseMapModel {
  final DateTime sleepTime;
  final DateTime awakeTime;
  final int totalSleepDuration;
  final int deepSleepDuration;
  final int lightSleepDuration;
  final int remSleepDuration;
  final int awakeDuration;

  SleepResponseMapModel({
    required this.sleepTime,
    required this.awakeTime,
    required this.totalSleepDuration,
    required this.deepSleepDuration,
    required this.lightSleepDuration,
    required this.remSleepDuration,
    required this.awakeDuration,
  });

  static DateTime? _time(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw is DateTime) return raw.toLocal();
      if (raw is String && raw.isNotEmpty) {
        final parsed = DateTime.tryParse(raw);
        if (parsed != null) return parsed.toLocal();
      }
      if (raw is num && raw > 0) {
        return DateTime.fromMillisecondsSinceEpoch(raw.toInt()).toLocal();
      }
    }
    return null;
  }

  static int _int(Map<String, dynamic> json, List<String> keys) {
    for (final k in keys) {
      final raw = json[k];
      if (raw is num) return raw.toInt();
      if (raw is String) {
        final parsed = num.tryParse(raw);
        if (parsed != null) return parsed.toInt();
      }
    }
    return 0;
  }

  /// Throws [FormatException] when the row carries no sleep / wake window,
  /// as AlloConnect's model does, so callers fall back to the row's value.
  factory SleepResponseMapModel.fromJson(Map<String, dynamic> json) {
    final sleep = _time(json, const ['sleep_time', 'sleepTime', 'bedTime']);
    final awake = _time(json, const ['awake_time', 'awakeTime', 'wakeTime']);
    if (sleep == null || awake == null) {
      throw const FormatException('Sleep row has no sleep / wake window');
    }

    return SleepResponseMapModel(
      sleepTime: sleep,
      awakeTime: awake,
      totalSleepDuration: _int(json, const [
        'total_sleep_duration',
        'totalSleepDuration',
        'totalMinutes',
      ]),
      deepSleepDuration: _int(json, const [
        'deep_sleep_duration',
        'deepSleepDuration',
      ]),
      lightSleepDuration: _int(json, const [
        'light_sleep_duration',
        'lightSleepDuration',
      ]),
      remSleepDuration: _int(json, const [
        'rem_sleep_duration',
        'remSleepDuration',
      ]),
      awakeDuration: _int(json, const ['awake_duration', 'awakeDuration']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sleep_time': sleepTime.toIso8601String(),
      'awake_time': awakeTime.toIso8601String(),
      'total_sleep_duration': totalSleepDuration,
      'deep_sleep_duration': deepSleepDuration,
      'light_sleep_duration': lightSleepDuration,
      'rem_sleep_duration': remSleepDuration,
      'awake_duration': awakeDuration,
    };
  }
}
