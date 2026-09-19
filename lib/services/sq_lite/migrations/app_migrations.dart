import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

typedef MigrationStep =
    Future<void> Function(Migrator migrator, AppDriftDatabase db);

class AppMigrations {
  /// v8 added the nicknames table the partner step writes.
  static const int currentSchemaVersion = 8;

  /// Tables v7 replaced outright, by their old sqlite names.
  ///
  /// Their columns were modelled on the previous API and do not map cleanly
  /// onto the new ones — `pregnancy_anc_schedule` counted visits while
  /// `anc_checkup_dates` counts months, `birth_records` split a baby's name and
  /// date differently from `baby`. Rather than guess at a lossy column
  /// mapping, v7 drops them and the client re-seeds from
  /// `GET /me/profile/get_all` on the next sign-in, which is authoritative.
  static const List<String> _replacedTables = [
    'users',
    'health_data_table',
    'pregnancies',
    'pregnancy_anc_schedule',
    'vaccinations',
    'report_checklists',
    'birth_records',
    'baby_immunization_records',
    'baby_milestones',
    'vitals',
  ];

  static final Map<int, MigrationStep> _steps = {
    2: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.vitalsStreamTable);
      } catch (e) {
        debugPrint('⚠️ Migration step v2 table creation warning: $e');
      }
    },
    // v3-v6 built up the old pregnancy-care and baby tables. v7 replaces all of
    // them wholesale, so upgrading from any of those versions runs v7 alone and
    // these steps are intentionally empty rather than creating tables that are
    // about to be dropped.
    3: (Migrator migrator, AppDriftDatabase db) async {},
    4: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.reminders);
      } catch (e) {
        debugPrint('⚠️ Migration step v4 table creation warning: $e');
      }
    },
    5: (Migrator migrator, AppDriftDatabase db) async {},
    6: (Migrator migrator, AppDriftDatabase db) async {},
    // v7: realign the synced tables with allomom-api-new.
    7: (Migrator migrator, AppDriftDatabase db) async {
      for (final name in _replacedTables) {
        try {
          await db.customStatement('DROP TABLE IF EXISTS $name;');
        } catch (e) {
          debugPrint('⚠️ Migration v7 could not drop "$name": $e');
        }
      }
      for (final table in <TableInfo>[
        db.users,
        db.userLoginsTable,
        db.healthDataTable,
        db.vitalsStreamTable,
        db.pregnancies,
        db.ancCheckupDates,
        db.pregnancyImmunizationRecords,
        db.pregnancyReportChecklists,
        db.babies,
        db.babyImmunizationRecords,
        db.babyMilestones,
        db.syncStates,
      ]) {
        try {
          await migrator.createTable(table);
        } catch (e) {
          debugPrint('⚠️ Migration v7 table creation warning: $e');
        }
      }
    },
    // v8: nicknames. The partner screen stores the name the user types for
    // their partner here rather than on the partner's own user row, so the two
    // can be edited independently.
    8: (Migrator migrator, AppDriftDatabase db) async {
      try {
        await migrator.createTable(db.userNickNames);
      } catch (e) {
        debugPrint('⚠️ Migration v8 table creation warning: $e');
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
        // Defensive creation so a database left half-migrated by an interrupted
        // upgrade still opens with every table present.
        final migrator = Migrator(db);
        for (final table in db.allTables) {
          try {
            await migrator.createTable(table);
          } catch (_) {
            // Table already exists, ignore.
          }
        }
        await _createIndexes(db);
      },
    );
  }

  static Future<void> _createIndexes(AppDriftDatabase db) async {
    final statements = [
      // Synced tables: indexed on the foreign key each sync module scopes by,
      // and on `synced` so collecting the dirty rows to push stays a lookup
      // rather than a table scan.
      'CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);',
      'CREATE INDEX IF NOT EXISTS idx_users_user_name ON users(user_name);',
      'CREATE INDEX IF NOT EXISTS idx_users_synced ON users(synced);',
      'CREATE INDEX IF NOT EXISTS idx_user_logins_user ON user_logins(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_health_data_user ON health_data(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_health_data_synced ON health_data(synced);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_stream_health ON vitals_stream(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_stream_key ON vitals_stream(key);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_stream_created ON vitals_stream(createdAt);',
      'CREATE INDEX IF NOT EXISTS idx_vitals_stream_synced ON vitals_stream(synced);',
      'CREATE INDEX IF NOT EXISTS idx_pregnancy_health ON pregnancy(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_pregnancy_status ON pregnancy(status);',
      'CREATE INDEX IF NOT EXISTS idx_pregnancy_synced ON pregnancy(synced);',
      'CREATE INDEX IF NOT EXISTS idx_anc_pregnancy ON anc_checkup_dates(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_anc_synced ON anc_checkup_dates(synced);',
      'CREATE INDEX IF NOT EXISTS idx_preg_immun_pregnancy ON pregnancy_immunization_record(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_preg_immun_synced ON pregnancy_immunization_record(synced);',
      'CREATE INDEX IF NOT EXISTS idx_report_checklist_pregnancy ON pregnancy_report_checklist(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_report_checklist_synced ON pregnancy_report_checklist(synced);',
      'CREATE INDEX IF NOT EXISTS idx_baby_pregnancy ON baby(pregnancy_id);',
      'CREATE INDEX IF NOT EXISTS idx_baby_synced ON baby(synced);',
      'CREATE INDEX IF NOT EXISTS idx_baby_immun_baby ON baby_immunization_records(baby_id);',
      'CREATE INDEX IF NOT EXISTS idx_baby_immun_synced ON baby_immunization_records(synced);',
      'CREATE INDEX IF NOT EXISTS idx_baby_milestones_baby ON baby_milestones(baby_id);',
      'CREATE INDEX IF NOT EXISTS idx_baby_milestones_synced ON baby_milestones(synced);',
      // App-local tables.
      'CREATE INDEX IF NOT EXISTS idx_prescriptions_health ON prescriptions(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_reports_health ON reports(healthDataID);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicines_health ON prescription_medicines(health_id);',
      'CREATE INDEX IF NOT EXISTS idx_report_attachments_report ON report_attachments(report_id);',
      'CREATE INDEX IF NOT EXISTS idx_reminders_user ON reminders(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicine_timings_medicine ON prescription_medicine_timings(prescriptionMedicineId);',
      'CREATE INDEX IF NOT EXISTS idx_prescription_medicine_timings_datetime ON prescription_medicine_timings(dateTime);',
      'CREATE INDEX IF NOT EXISTS idx_family_members_family ON family_members_table(familyid);',
      'CREATE INDEX IF NOT EXISTS idx_family_members_user ON family_members_table(userid);',
      'CREATE INDEX IF NOT EXISTS idx_families_code ON families(code);',
      'CREATE INDEX IF NOT EXISTS idx_user_relations_user ON user_relations(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_user_relations_related ON user_relations(related_user_id);',
      'CREATE INDEX IF NOT EXISTS idx_user_nick_names_user ON user_nick_names(user_id);',
      'CREATE INDEX IF NOT EXISTS idx_user_nick_names_related ON user_nick_names(related_user_id);',
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
