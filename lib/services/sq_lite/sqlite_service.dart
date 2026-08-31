import 'package:flutter/foundation.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

class SqLiteService {
  static final SqLiteService _instance = SqLiteService._internal();
  factory SqLiteService() => _instance;
  SqLiteService._internal();

  static AppDriftDatabase? _database;

  Future<AppDriftDatabase> get database async {
    if (_database != null) return _database!;
    _database = AppDriftDatabase();
    return _database!;
  }

  static Future<void> init() async {
    await SqLiteService().database;
    debugPrint("Allomom SQLite / Drift Database initialized");
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }

  static Future<void> clearDatabase() async {
    final db = _database;
    if (db != null) {
      await db.clearAllData();
    } else {
      final newDb = await SqLiteService().database;
      await newDb.clearAllData();
    }
  }
}
