import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

typedef MigrationStep =
    Future<void> Function(Migrator migrator, AppDriftDatabase db);

class AppMigrations {
  static const int currentSchemaVersion = 2;

  static final Map<int, MigrationStep> _steps = {
    2: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.vitals);
      } catch (e) {
        debugPrint('⚠️ Migration step v2 table creation warning: $e');
      }
    },
  };

  static MigrationStrategy build(AppDriftDatabase db) {
    return MigrationStrategy(
      onCreate: (Migrator migrator) async {
        await migrator.createAll();
      },
      onUpgrade: (Migrator migrator, int from, int to) async {
        for (int version = from + 1; version <= to; version++) {
          final step = _steps[version];
          if (step != null) {
            await step(migrator, db);
          }
        }
      },
      beforeOpen: (details) async {
        // Defensive creation to ensure all tables exist even if migration state lagged
        final migrator = Migrator(db);
        for (final table in db.allTables) {
          try {
            await migrator.createTable(table);
          } catch (_) {
            // Table already exists, ignore
          }
        }
        await _createIndexes(db);
      },
    );
  }

  static Future<void> _createIndexes(AppDriftDatabase db) async {
    final statements = [
      'CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);',
      'CREATE INDEX IF NOT EXISTS idx_users_user_name ON users(user_name);',
      'CREATE INDEX IF NOT EXISTS idx_health_data_user ON health_data_table(UserID);',
      'CREATE INDEX IF NOT EXISTS idx_pregnancy_health ON pregnancies(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_prescriptions_health ON prescriptions(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_reports_health ON reports(healthDataID);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicines_health ON prescription_medicines(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_user_id ON vitals(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_created_at ON vitals(created_at);',
    ];

    for (final stmt in statements) {
      try {
        await db.customStatement(stmt);
      } catch (e) {
        debugPrint('⚠️ Index creation warning for "$stmt": $e');
      }
    }
  }
}
