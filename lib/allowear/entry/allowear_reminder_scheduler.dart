import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:allomom/local_notification/services/local_reminder_scheduler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Local "charge your Allowear" reminders, driven by the battery level read
/// each time the band connects.
///
/// Below [lowThreshold] it schedules one-off reminders at [reminderHours]
/// for [reminderDays] days, today included (times already past are skipped).
/// At or above [chargedThreshold] they're cancelled. Levels in between leave
/// whatever is scheduled alone.
///
/// Ids 8000-8019 sit outside [LocalReminderScheduler.cancelAllReminders] and
/// past the medication range (3000-7999), so app start doesn't wipe them.
class AllowearReminderScheduler {
  static const int lowThreshold = 20;
  static const int chargedThreshold = 50;
  static const List<int> reminderHours = [10, 18];
  static const int reminderDays = 2;

  static const int _idBase = 8000;
  static const int _idRange = 20;

  static FlutterLocalNotificationsPlugin get _plugin =>
      LocalReminderScheduler.plugin;

  /// Schedules or cancels the charge reminders for [level].
  static Future<void> onBatteryLevel(int level) async {
    if (level <= 0) return;
    try {
      if (level < lowThreshold) {
        await _scheduleChargeReminders();
      } else if (level >= chargedThreshold) {
        await cancelChargeReminders();
      }
    } catch (e) {
      debugPrint('AllowearReminderScheduler: $e');
    }
  }

  static Future<void> _scheduleChargeReminders() async {
    await cancelChargeReminders();
    // Also loads the timezone database tz.local reads below.
    await LocalReminderScheduler.init();

    final now = tz.TZDateTime.now(tz.local);
    var id = _idBase;
    for (var day = 0; day < reminderDays; day++) {
      for (final hour in reminderHours) {
        final at = tz.TZDateTime(
            tz.local, now.year, now.month, now.day + day, hour);
        if (!at.isAfter(now)) continue;
        await LocalReminderScheduler.scheduleZoned(
          id: id++,
          title: 'Allowear Battery Low'.tr,
          body: 'Please charge your Allowear to keep tracking your vitals.'.tr,
          scheduledDate: at,
          notificationDetails: _details,
          payload: jsonEncode({'screen': 'allowear'}),
        );
      }
    }
  }

  /// Drops every pending charge reminder.
  static Future<void> cancelChargeReminders() async {
    final List<PendingNotificationRequest> pending;
    try {
      pending = await _plugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('AllowearReminderScheduler: could not read pending: $e');
      return;
    }
    for (final request in pending) {
      if (request.id >= _idBase && request.id < _idBase + _idRange) {
        await _plugin.cancel(id: request.id);
      }
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      'allowear_reminders',
      'Allowear Reminders',
      channelDescription: 'Reminders to charge your Allowear',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );
}
