import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:allomom/services/sq_lite/migrations/app_migrations.dart';

part 'tables/initial_setup_table.dart';
part 'tables/user_table.dart';
part 'tables/user_entity_table.dart';
part 'tables/user_relation_table.dart';
part 'tables/family_table.dart';
part 'tables/family_requests_table.dart';
part 'tables/family_members_table.dart';
part 'tables/health_data_table.dart';
part 'tables/cycle_history_table.dart';
part 'tables/pregnancy_table.dart';
part 'tables/prescription_table.dart';
part 'tables/prescription_medicine_table.dart';
part 'tables/prescription_medicine_timing_table.dart';
part 'tables/report_table.dart';

part 'drift_database.g.dart';

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final file = File(p.join(documentsDir.path, 'allomom_local.db'));
    return NativeDatabase.createInBackground(file);
  });
}

@DriftDatabase(
  tables: [
    InitialSetup,
    Users,
    UserEntities,
    UserRelations,
    Families,
    FamilyRequestsTable,
    FamilyMembersTable,
    HealthDataTable,
    CycleHistories,
    Pregnancies,
    Prescriptions,
    PrescriptionMedicines,
    PrescriptionMedicineTimings,
    Reports,
  ],
)
class AppDriftDatabase extends _$AppDriftDatabase {
  AppDriftDatabase() : super(_openConnection());

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
}
