import 'package:allomom/api/response.dart';
import 'package:allomom/services/health_vital_sync_service.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// AlloConnect's `VitalsApi`, for the call its AlloWear sync makes, so that
/// sync runs here unchanged.
///
/// AlloConnect posts the batch to `/allowear/sync-data-bulk`. Allomom's server
/// takes vitals through the `vitals` sync module, which uploads the rows the
/// AlloWear sync has just saved with `synced = 0`.
class VitalsApi {
  VitalsApi._();

  static Future<APIResponse> syncDataBulk(
    String bluetoothMac,
    List<Map<String, dynamic>> vitals,
  ) async {
    await HealthVitalSyncService.instance.syncUnsyncedVitals();
    // Offline or refused: the rows stay unsynced and the periodic sync
    // retries them.
    final pending = await VitalsSqLiteService().getUnsyncedVitals();
    return APIResponse(
      success: pending.isEmpty,
      map: {'detail': pending.isEmpty ? '' : 'Queued; will sync when online'},
    );
  }
}
