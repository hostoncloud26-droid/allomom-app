import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:allomom/services/sq_lite/migrations/app_migrations.dart';

// ── Tables mirroring allomom-api-new ─────────────────────────────────────────
part 'tables/user_table.dart';
part 'tables/user_logins_table.dart';
part 'tables/health_data_table.dart';
part 'tables/vitals_stream_table.dart';
part 'tables/pregnancy_table.dart';
part 'tables/anc_checkup_dates_table.dart';
part 'tables/pregnancy_immunization_table.dart';
part 'tables/pregnancy_report_checklist_table.dart';
part 'tables/baby_table.dart';
part 'tables/baby_immunization_record_table.dart';
part 'tables/baby_milestone_table.dart';
part 'tables/sync_state_table.dart';

// ── App-local tables with no server counterpart yet ──────────────────────────
part 'tables/initial_setup_table.dart';
part 'tables/user_entity_table.dart';
part 'tables/user_relation_table.dart';
part 'tables/user_nick_name_table.dart';
part 'tables/family_table.dart';
part 'tables/family_requests_table.dart';
part 'tables/family_members_table.dart';
part 'tables/cycle_history_table.dart';
part 'tables/prescription_table.dart';
part 'tables/prescription_medicine_table.dart';
part 'tables/prescription_medicine_timing_table.dart';
part 'tables/report_table.dart';
part 'tables/report_attachment_table.dart';
part 'tables/reminder_table.dart';

part 'drift_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(documentsDir.path, 'allomom_local.db'));
    return NativeDatabase.createInBackground(file);
  });
}

/// The device's local replica of the account.
///
/// Everything the app reads comes from here, never straight from the network:
/// screens stay fully usable offline, and [SyncService] reconciles with the
/// server in the background. Tables that mirror allomom-api-new carry
/// `synced` / `synced_at` so that reconciliation knows what to push and where
/// to resume; the app-local tables below have no server counterpart yet and are
/// left alone by sync.
@DriftDatabase(
  tables: [
    // Mirrored from the server
    Users,
    UserLoginsTable,
    HealthDataTable,
    VitalsStreamTable,
    Pregnancies,
    AncCheckupDates,
    PregnancyImmunizationRecords,
    PregnancyReportChecklists,
    Babies,
    BabyImmunizationRecords,
    BabyMilestones,
    SyncStates,
    // App-local only
    InitialSetup,
    UserEntities,
    UserRelations,
    UserNickNames,
    Families,
    FamilyRequestsTable,
    FamilyMembersTable,
    CycleHistories,
    Prescriptions,
    PrescriptionMedicines,
    PrescriptionMedicineTimings,
    Reports,
    ReportAttachments,
    Reminders,
  ],
)
class AppDriftDatabase extends _$AppDriftDatabase {
  AppDriftDatabase() : super(_openConnection());

  /// Lets tests drive the schema over an in-memory executor instead of the
  /// on-device file, which needs path_provider.
  AppDriftDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => AppMigrations.currentSchemaVersion;

  @override
  MigrationStrategy get migration => AppMigrations.build(this);

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  /// Wipes everything the signed-in account owns, leaving app-level settings
  /// such as the chosen language in place. Used on sign-out and when a
  /// different user signs in on the same device.
  Future<void> clearAccountData() async {
    await transaction(() async {
      for (final table in <TableInfo>[
        babyMilestones,
        babyImmunizationRecords,
        babies,
        pregnancyReportChecklists,
        pregnancyImmunizationRecords,
        ancCheckupDates,
        pregnancies,
        vitalsStreamTable,
        healthDataTable,
        userLoginsTable,
        users,
        syncStates,
        cycleHistories,
        prescriptionMedicineTimings,
        prescriptionMedicines,
        prescriptions,
        reportAttachments,
        reports,
        reminders,
        familyMembersTable,
        familyRequestsTable,
        families,
        userNickNames,
        userRelations,
        userEntities,
      ]) {
        await delete(table).go();
      }
    });
  }
}
