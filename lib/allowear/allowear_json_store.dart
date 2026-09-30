import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:allomom/models/vital_sync_item.dart';

/// A list of [VitalSyncItem]s kept as one JSON file in app support storage.
///
/// AlloConnect keeps these lists as rows of its `InitialSetup` table. Allomom
/// has no such table, and these lists are device-local working state (the raw
/// band dump, the readings still waiting on a worn check) that never syncs —
/// so a file per list does the job without a schema migration.
class AllowearJsonStore {
  const AllowearJsonStore(this.name);

  final String name;

  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'allowear', '$name.json'));
  }

  Future<List<VitalSyncItem>> read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map((e) => VitalSyncItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('AllowearJsonStore($name): read failed: $e');
      return [];
    }
  }

  Future<void> write(List<VitalSyncItem> items) async {
    final file = await _file();
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('AllowearJsonStore($name): clear failed: $e');
    }
  }
}
