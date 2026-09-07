import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

typedef MigrationStep =
    Future<void> Function(Migrator migrator, AppDriftDatabase db);

class AppMigrations {
  static const int currentSchemaVersion = 5;

  static final Map<int, MigrationStep> _steps = {
    2: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.vitals);
      } catch (e) {
        debugPrint('⚠️ Migration step v2 table creation warning: $e');
      }
    },
    // v3: pregnancy care schedule tables (ANC visits, vaccinations,
    // report checklists) + report file attachments. All brand-new tables,
    // so there is no existing data to migrate.
    3: (Migrator migrator, AppDriftDatabase db) async {
      for (final table in <TableInfo>[
        db.pregnancyAncSchedule,
        db.vaccinations,
        db.reportChecklists,
        db.reportAttachments,
      ]) {
        try {
          await migrator.createTable(table);
        } catch (e) {
          debugPrint('⚠️ Migration step v3 table creation warning: $e');
        }
      }
    },
    // v4: locally-stored reminders. New table, nothing to migrate.
    4: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.reminders);
      } catch (e) {
        debugPrint('⚠️ Migration step v4 table creation warning: $e');
      }
    },
    // v5: pregnancy-month columns on the care schedule tables, plus a
    // required/optional flag for lab tests. Existing rows keep NULL months.
    5: (Migrator migrator, AppDriftDatabase db) async {
      final columns = <(TableInfo, GeneratedColumn)>[
        (db.pregnancyAncSchedule, db.pregnancyAncSchedule.pregnancyMonth),
        (db.vaccinations, db.vaccinations.pregnancyMonth),
        (db.reportChecklists, db.reportChecklists.pregnancyMonth),
        (db.reportChecklists, db.reportChecklists.isRequired),
      ];
      for (final (table, column) in columns) {
        try {
          await migrator.addColumn(table, column);
        } catch (e) {
          debugPrint('⚠️ Migration step v5 column warning: $e');
        }
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
      'CREATE INDEX IF NOT EXISTS idx_anc_pregnancy ON pregnancy_anc_schedule(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_anc_scheduled_date ON pregnancy_anc_schedule(scheduled_date);',
      'CREATE INDEX IF NOT EXISTS idx_vaccinations_user ON vaccinations(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_vaccinations_pregnancy ON vaccinations(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_report_checklists_user ON report_checklists(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_report_checklists_pregnancy ON report_checklists(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_report_attachments_report ON report_attachments(report_id);',
      'CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicine_timings_medicine ON prescription_medicine_timings(prescriptionMedicineId);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicine_timings_datetime ON prescription_medicine_timings(dateTime);',
      'CREATE INDEX IF NOT EXISTS idx_family_members_family ON family_members_table(familyid);',
      'CREATE INDEX IF NOT EXISTS idx_family_members_user ON family_members_table(userid);',
      'CREATE INDEX IF NOT EXISTS idx_families_code ON families(code);',
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
