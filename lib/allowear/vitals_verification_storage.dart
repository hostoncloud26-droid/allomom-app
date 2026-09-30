import 'package:allomom/allowear/allowear_json_store.dart';
import 'package:allomom/models/vital_sync_item.dart';

/// Storage helper for persisting unverified vitals on the device.
///
/// Unverified vitals are data points collected by the wearable device
/// during periods where neither step activity nor sleep was detected,
/// meaning we can't confirm the device was actually being worn.
class VitalsVerificationStorage {
  static const _store = AllowearJsonStore('unverified_vitals');

  /// Retrieves all previously stored unverified vitals from the DB.
  static Future<List<VitalSyncItem>> getUnverifiedVitals() => _store.read();

  /// Saves unverified vitals to the DB (replaces any existing data).
  static Future<void> saveUnverifiedVitals(List<VitalSyncItem> items) async {
    await _store.write(items);
    print(
        'VitalsVerificationStorage: Saved ${items.length} unverified vitals');
  }

  /// Clears all stored unverified vitals.
  static Future<void> clearUnverifiedVitals() async {
    await _store.clear();
    print('VitalsVerificationStorage: Cleared unverified vitals');
  }
}
