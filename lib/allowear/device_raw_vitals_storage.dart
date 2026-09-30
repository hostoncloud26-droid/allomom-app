import 'package:allomom/allowear/allowear_json_store.dart';
import 'package:allomom/models/vital_sync_item.dart';

/// Storage helper for persisting device raw vitals on the device.
///
/// Raw vitals are sensor data points directly received from the wearable device
/// before any step/sleep activity validation is applied by `checkVitalsData`.
class DeviceRawVitalsStorage {
  static const _store = AllowearJsonStore('device_raw_vitals');
  static const int _maxStoredItems = 2000;

  /// Retrieves all previously stored device raw vitals from the DB,
  /// sorted with the newest records first.
  static Future<List<VitalSyncItem>> getRawVitals() async {
    final list = await _store.read();
    list.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
    return list;
  }

  /// Appends new raw vitals, merging them with existing records while avoiding duplicates.
  static Future<void> addRawVitals(List<VitalSyncItem> newItems) async {
    if (newItems.isEmpty) return;

    final existing = await getRawVitals();
    final Set<String> seenSignatures = {};

    String signature(VitalSyncItem item) =>
        '${item.key}_${item.createdAt?.millisecondsSinceEpoch}_${item.value}';

    final List<VitalSyncItem> merged = [];

    // Prioritize new items first
    for (final item in newItems) {
      final sig = signature(item);
      if (seenSignatures.add(sig)) {
        merged.add(item);
      }
    }

    // Add existing items if not already added
    for (final item in existing) {
      final sig = signature(item);
      if (seenSignatures.add(sig)) {
        merged.add(item);
      }
    }

    // Sort descending by timestamp
    merged.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });

    // Cap at maximum stored items
    final capped = merged.length > _maxStoredItems
        ? merged.sublist(0, _maxStoredItems)
        : merged;

    await saveRawVitals(capped);
  }

  /// Saves raw vitals to the DB (replaces existing stored data).
  static Future<void> saveRawVitals(List<VitalSyncItem> items) async {
    await _store.write(items);
    print('DeviceRawVitalsStorage: Saved ${items.length} raw vitals');
  }

  /// Removes a single vital item from the stored raw vitals.
  static Future<void> deleteRawVital(String id) async {
    final existing = await getRawVitals();
    existing.removeWhere((item) => item.id == id);
    await saveRawVitals(existing);
  }

  /// Clears all stored device raw vitals from the DB.
  static Future<void> clearRawVitals() async {
    await _store.clear();
    print('DeviceRawVitalsStorage: Cleared device raw vitals');
  }
}
