import 'package:flutter/foundation.dart';
import 'package:allomom/services/auth/secure_token_store.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/services/sync/sync_service.dart';

/// The vitals end of the sync, kept as the entry point the vitals screens call.
///
/// Vitals are written to SQLite with `synced = 0`. [SyncService] owns the
/// upload — the `vitals` module pushes edits and `deleted_ids`, and runs on its
/// five-minute timer — so this only asks it to run now, straight after a
/// write, instead of leaving the row to wait for the next tick.
class HealthVitalSyncService {
  static final HealthVitalSyncService instance =
      HealthVitalSyncService._internal();
  factory HealthVitalSyncService() => instance;
  HealthVitalSyncService._internal();

  final VitalsSqLiteService _sqLiteService = VitalsSqLiteService();

  void init() {
    // Nothing to start: SyncService runs the periodic pass.
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

  /// Pushes queued vitals — new readings and deletions — now.
  Future<void> syncUnsyncedVitals() async {
    if (!SecureTokenStore.instance.hasSession) {
      debugPrint('HealthVitalSyncService: skipping sync, no active session');
      return;
    }
    try {
      await SyncService.instance.syncModule('vitals');
    } catch (e) {
      debugPrint('HealthVitalSyncService: vitals sync failed: $e');
    }
  }
}
