import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';

/// CRUD for locally-stored reminders. Local-only; every write resets
/// `synced` to 0 so a future sync worker can push the row.
class ReminderDbService {
  static final ReminderDbService instance = ReminderDbService._internal();
  ReminderDbService._internal();

  final _uuid = const Uuid();

  Future<List<Reminder>> getReminders(String userId) async {
    final db = await SqLiteService().database;
    return (db.select(db.reminders)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<Reminder?> getReminderById(String id) async {
    final db = await SqLiteService().database;
    return (db.select(db.reminders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<String> createReminder({
    required String userId,
    required String title,
    String? reminderType,
    String frequency = 'Daily',
    int? hour,
    int? minute,
    List<String> channels = const ['push'],
    bool enabled = true,
    bool configurable = true,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await SqLiteService().database;
    final id = _uuid.v4();
    await db.into(db.reminders).insertOnConflictUpdate(
          RemindersCompanion(
            id: Value(id),
            userId: Value(userId),
            title: Value(title),
            reminderType: Value(reminderType),
            frequency: Value(frequency),
            hour: Value(hour),
            minute: Value(minute),
            channels: Value(jsonEncode(channels)),
            enabled: Value(enabled),
            configurable: Value(configurable),
            startDate: Value(startDate),
            endDate: Value(endDate),
            createdAt: Value(DateTime.now()),
            synced: const Value(0),
          ),
        );
    return id;
  }

  Future<void> updateReminder(RemindersCompanion reminder) async {
    final db = await SqLiteService().database;
    await (db.update(db.reminders)..where((t) => t.id.equals(reminder.id.value)))
        .write(reminder.copyWith(synced: const Value(0)));
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await updateReminder(
      RemindersCompanion(id: Value(id), enabled: Value(enabled)),
    );
  }

  Future<void> deleteReminder(String id) async {
    final db = await SqLiteService().database;
    await (db.delete(db.reminders)..where((t) => t.id.equals(id))).go();
  }

  Future<List<Reminder>> unsyncedReminders() async {
    final db = await SqLiteService().database;
    return (db.select(db.reminders)..where((t) => t.synced.equals(0))).get();
  }
}
