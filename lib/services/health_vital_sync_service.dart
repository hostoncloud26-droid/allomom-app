import 'package:flutter/foundation.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Placeholder for the vitals sync worker.
///
/// AlloMom currently runs fully on the local database: vitals are written to
/// SQLite with `synced = 0` and stay there. Nothing is pushed to allomom-api
/// yet, so this service only reports how much data is queued. The periodic
/// timer and the `VitalsApi.syncDataBulk` upload were removed deliberately —
/// re-add them here when the sync implementation lands, and mark rows via
/// [VitalsSqLiteService.markAsSynced] once the server accepts them.
class HealthVitalSyncService {
  static final HealthVitalSyncService instance =
      HealthVitalSyncService._internal();
  factory HealthVitalSyncService() => instance;
  HealthVitalSyncService._internal();

  final VitalsSqLiteService _sqLiteService = VitalsSqLiteService();

  void init() {
    // No-op: no background sync while the app is local-only.
  }

  void dispose() {}

  /// Number of vitals still waiting to be pushed to the server.
  Future<int> pendingCount() async {
    try {
      final unsynced = await _sqLiteService.getUnsyncedVitals();
      return unsynced.length;
    } catch (e) {
      debugPrint('HealthVitalSyncService: could not count pending vitals: $e');
      return 0;
    }
  }

  /// Kept so existing callers compile. Does not touch the network; local
  /// records intentionally stay at `synced = 0`.
  Future<void> syncUnsyncedVitals() async {
    final pending = await pendingCount();
    if (pending > 0) {
      debugPrint(
        'HealthVitalSyncService: $pending vital(s) pending upload. '
        'Sync is disabled (local-only mode).',
      );
    }
  }
}
