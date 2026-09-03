import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:allomom/local_notification/models/local_reminder.dart';
import 'package:allomom/local_notification/services/local_reminder_storage.dart';

class LocalReminderScheduler {
  static bool _initialized = false;
  static final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();

  static const int _maxNotificationsPerType = 20;

  /// Global callback for handling notification taps
  static void Function(Map<String, dynamic> data)? onNotificationAction;

  /// Initialize timezone data and local notification plugin
  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (e) {
      debugPrint('⚠️ Timezone initialization note: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        _handleNotificationTap(details);
      },
    );

    await LocalReminderStorage.init();
    _initialized = true;
  }

  static void _handleNotificationTap(NotificationResponse? details) {
    if (details == null || details.payload == null || details.payload!.isEmpty) return;
    try {
      final data = jsonDecode(details.payload!) as Map<String, dynamic>;
      debugPrint('Notification clicked with data: $data');
      if (onNotificationAction != null) {
        onNotificationAction!(data);
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }

  /// Request notification permissions on Android & iOS
  static Future<bool> requestPermissions() async {
    final android = plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final androidGranted = await android?.requestNotificationsPermission() ?? true;

    final ios = plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    ) ?? true;

    return androidGranted && iosGranted;
  }

  /// Schedule all enabled reminders based on stored configs
  static Future<void> scheduleAllReminders() async {
    await init();
    final configs = LocalReminderStorage.loadAll();

    for (final config in configs) {
      if (config.enabled) {
        await _scheduleReminder(config);
      } else {
        await cancelReminder(config.type);
      }
    }
  }

  /// Schedule a single reminder based on its configuration
  static Future<void> scheduleReminder(LocalReminderConfig config) async {
    await init();
    await cancelReminder(config.type);

    if (!config.enabled) {
      await LocalReminderStorage.save(config);
      return;
    }

    await _scheduleReminder(config);
    await LocalReminderStorage.save(config);
  }

  /// Internal schedule implementation
  static Future<void> _scheduleReminder(LocalReminderConfig config) async {
    if (config.type.isIntervalBased) {
      await _scheduleIntervalReminder(config);
    } else {
      await _scheduleFixedTimeReminder(config);
    }
  }

  /// Schedule interval-based reminders (hydration)
  static Future<void> _scheduleIntervalReminder(LocalReminderConfig config) async {
    final now = tz.TZDateTime.now(tz.local);
    int notificationId = config.type.notificationIdBase;

    int currentHour = config.startHour;
    int currentMinute = 0;
    int scheduledCount = 0;

    while (currentHour < config.endHour && scheduledCount < _maxNotificationsPerType) {
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        currentHour,
        currentMinute,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _scheduleZoned(
        id: notificationId,
        title: config.type.label,
        body: config.type.defaultMessage,
        scheduledDate: scheduledDate,
        notificationDetails: _buildNotificationDetails(config.type),
        payload: jsonEncode({
          'screen': 'local_reminder',
          'type': config.type.key,
        }),
        matchDateTimeComponents: DateTimeComponents.time,
      );

      notificationId++;
      scheduledCount++;

      currentMinute += config.intervalMinutes;
      while (currentMinute >= 60) {
        currentMinute -= 60;
        currentHour++;
      }
    }
  }

  /// Schedule fixed-time reminders (sleep, wake-up, meals, exercise)
  static Future<void> _scheduleFixedTimeReminder(LocalReminderConfig config) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      config.hour,
      config.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleZoned(
      id: config.type.notificationIdBase,
      title: config.type.label,
      body: config.type.defaultMessage,
      scheduledDate: scheduledDate,
      notificationDetails: _buildNotificationDetails(config.type),
      payload: jsonEncode({
        'screen': 'local_reminder',
        'type': config.type.key,
      }),
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Schedule a specific medication reminder
  static Future<void> scheduleMedicationReminder({
    required int id,
    required String medicineName,
    required String dosage,
    required String? mealInstruction,
    required DateTime dateTime,
    required String timingId,
  }) async {
    await init();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime.from(dateTime, tz.local);

    if (scheduledDate.isBefore(now)) {
      return; // Skip past dates
    }

    final mealText = mealInstruction != null && mealInstruction.isNotEmpty ? ' • $mealInstruction' : '';
    final body = 'Time for $medicineName ($dosage$mealText)';

    await _scheduleZoned(
      id: 3000 + (id % 5000),
      title: '💊 Medication Due: $medicineName',
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'medication_reminders',
          'Medication Reminders',
          channelDescription: 'Prescription dose timings and alerts',
          importance: Importance.max,
          priority: Priority.high,
          category: AndroidNotificationCategory.alarm,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: jsonEncode({
        'screen': 'prescription_reminder',
        'timing_id': timingId,
        'medicine_name': medicineName,
      }),
    );
  }

  static Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (_) {
      await plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  /// Cancel all notifications for a specific reminder type
  static Future<void> cancelReminder(LocalReminderType type) async {
    for (int i = 0; i < 25; i++) {
      await plugin.cancel(id: type.notificationIdBase + i);
    }
  }

  /// Cancel all local reminders
  static Future<void> cancelAllReminders() async {
    for (final type in LocalReminderType.values) {
      await cancelReminder(type);
    }
  }

  /// Reschedule all reminders
  static Future<void> rescheduleAll() async {
    await cancelAllReminders();
    await scheduleAllReminders();
  }

  static NotificationDetails _buildNotificationDetails(LocalReminderType type) {
    final android = AndroidNotificationDetails(
      'pregnancy_health_reminders',
      'Pregnancy & Health Reminders',
      channelDescription: 'Reminders for hydration, nutrition, sleep, and exercise',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      autoCancel: true,
      enableVibration: true,
      playSound: true,
    );

    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    return NotificationDetails(android: android, iOS: ios);
  }
}
