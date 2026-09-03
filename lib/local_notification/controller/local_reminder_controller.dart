import 'package:flutter/material.dart';
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/services/local_reminder_storage.dart';
import 'package:allomom/local_notification/services/local_reminder_scheduler.dart';

class LocalReminderController extends ChangeNotifier {
  static final LocalReminderController instance = LocalReminderController._internal();
  LocalReminderController._internal() {
    _loadConfigs();
  }

  final Map<LocalReminderType, LocalReminderConfig> _configs = {};
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  List<LocalReminderConfig> get configs => LocalReminderType.values.map((t) => getConfig(t)).toList();

  void _loadConfigs() {
    for (final type in LocalReminderType.values) {
      _configs[type] = LocalReminderStorage.load(type);
    }
    notifyListeners();
  }

  LocalReminderConfig getConfig(LocalReminderType type) {
    return _configs[type] ?? LocalReminderStorage.load(type);
  }

  bool isEnabled(LocalReminderType type) {
    return getConfig(type).enabled;
  }

  /// Toggle enabled state
  Future<void> toggleReminder(LocalReminderType type, bool enabled) async {
    final current = getConfig(type);
    final updated = current.copyWith(enabled: enabled);
    _configs[type] = updated;
    notifyListeners();

    await LocalReminderScheduler.scheduleReminder(updated);
  }

  /// Update interval for interval-based reminders
  Future<void> updateInterval(LocalReminderType type, int intervalMinutes) async {
    final current = getConfig(type);
    final updated = current.copyWith(intervalMinutes: intervalMinutes);
    _configs[type] = updated;
    notifyListeners();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Update fixed time
  Future<void> updateTime(LocalReminderType type, int hour, int minute) async {
    final current = getConfig(type);
    final updated = current.copyWith(hour: hour, minute: minute);
    _configs[type] = updated;
    notifyListeners();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Update active window hours
  Future<void> updateActiveHours(LocalReminderType type, int startHour, int endHour) async {
    final current = getConfig(type);
    final updated = current.copyWith(startHour: startHour, endHour: endHour);
    _configs[type] = updated;
    notifyListeners();

    if (updated.enabled) {
      await LocalReminderScheduler.scheduleReminder(updated);
    } else {
      await LocalReminderStorage.save(updated);
    }
  }

  /// Refresh and reschedule all
  Future<void> refreshAndReschedule() async {
    _isLoading = true;
    notifyListeners();

    _loadConfigs();
    await LocalReminderScheduler.rescheduleAll();

    _isLoading = false;
    notifyListeners();
  }
}
