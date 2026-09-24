import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'package:allomom/api/profile_api.dart';
import 'package:allomom/api/sync_api.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/sqlite_service.dart';
import 'package:allomom/services/sync/sync_codec.dart';
import 'package:allomom/services/sync/sync_mappers.dart';

/// Reconciles the local database with the server.
///
/// The app never reads from the network directly — screens read sqlite, and
/// this runs in the background to keep sqlite current. One module at a time, in
/// the dependency order [kSyncMappers] declares, so a pregnancy is written
/// before the ANC rows that point at it.
///
/// The watermark is always the `synced_at` the *server* returned, stored per
/// module in `sync_state`. Using the device clock would let a phone with a
/// wrong time ask for changes since a moment that never happened and skip a
/// window of updates permanently.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  static const Duration _interval = Duration(minutes: 5);

  Timer? _timer;
  bool _running = false;

  /// Fires after any sync that changed local data, so controllers can reload.
  final List<void Function()> _listeners = [];

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void _notify() {
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (e) {
        debugPrint('⚠️ [SyncService] listener failed: $e');
      }
    }
  }

  Future<AppDriftDatabase> get _db => SqLiteService().database;

  /// Starts the periodic loop. Safe to call more than once.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => syncAll());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Watermarks ─────────────────────────────────────────────────────────────

  Future<DateTime?> watermarkFor(String module) async {
    final db = await _db;
    final row = await (db.select(db.syncStates)
          ..where((s) => s.module.equals(module)))
        .getSingleOrNull();
    return row?.syncedAt;
  }

  Future<void> _setWatermark(
    String module,
    DateTime syncedAt, {
    String? error,
  }) async {
    final db = await _db;
    await db
        .into(db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion(
            module: Value(module),
            syncedAt: Value(syncedAt),
            lastAttemptAt: Value(DateTime.now()),
            lastError: Value(error),
          ),
        );
  }

  Future<void> _recordFailure(String module, String error) async {
    final db = await _db;
    final existing = await (db.select(db.syncStates)
          ..where((s) => s.module.equals(module)))
        .getSingleOrNull();
    await db
        .into(db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion(
            module: Value(module),
            // Left untouched: a failed attempt must not advance the watermark,
            // or the changes in that window are never asked for again.
            syncedAt: Value(existing?.syncedAt),
            lastAttemptAt: Value(DateTime.now()),
            lastError: Value(error),
          ),
        );
  }

  /// Clears every watermark, so the next sync pulls the account from scratch.
  Future<void> resetWatermarks() async {
    final db = await _db;
    await db.delete(db.syncStates).go();
  }

  // ── Seeding ────────────────────────────────────────────────────────────────

  /// Replaces the local copy with `GET /me/profile/get_all`.
  ///
  /// Used right after sign-in and after the v7 schema migration, where the old
  /// local rows were dropped. The bundle's `server_time` becomes every module's
  /// watermark, so the first incremental sync continues from exactly this
  /// snapshot rather than re-pulling everything.
  Future<bool> seedFromServer() async {
    final response = await ProfileApi.getAll();
    if (!response.success || response.item is! Map) {
      debugPrint('⚠️ [SyncService] seed failed: ${response.detail}');
      return false;
    }

    final bundle = Map<String, dynamic>.from(response.item as Map);
    final serverTime =
        SyncCodec.date(bundle['server_time']) ?? DateTime.now();
    final db = await _db;

    try {
      await db.transaction(() async {
        for (final mapper in kSyncMappers) {
          await mapper.clear(db);
        }

        final user = bundle['user'];
        if (user is Map) {
          await const UserMapper()
              .applyServerRow(db, Map<String, dynamic>.from(user));
        }

        final health = bundle['health_data'];
        if (health is Map) {
          await const HealthMapper()
              .applyServerRow(db, Map<String, dynamic>.from(health));
        }

        for (final vital in (bundle['vitals'] as List? ?? const [])) {
          if (vital is Map) {
            await const VitalsMapper()
                .applyServerRow(db, Map<String, dynamic>.from(vital));
          }
        }

        for (final raw in (bundle['pregnancies'] as List? ?? const [])) {
          if (raw is! Map) continue;
          final pregnancy = Map<String, dynamic>.from(raw);
          await const PregnancyMapper().applyServerRow(db, pregnancy);

          for (final anc in (pregnancy['anc_checkups'] as List? ?? const [])) {
            if (anc is Map) {
              await const AncMapper()
                  .applyServerRow(db, Map<String, dynamic>.from(anc));
            }
          }
          for (final v in (pregnancy['vaccinations'] as List? ?? const [])) {
            if (v is Map) {
              await const PregnancyVaccinationMapper()
                  .applyServerRow(db, Map<String, dynamic>.from(v));
            }
          }
          for (final r
              in (pregnancy['report_checklists'] as List? ?? const [])) {
            if (r is Map) {
              await const ReportChecklistMapper()
                  .applyServerRow(db, Map<String, dynamic>.from(r));
            }
          }
        }

        for (final raw in (bundle['babies'] as List? ?? const [])) {
          if (raw is! Map) continue;
          final baby = Map<String, dynamic>.from(raw);
          await const BabyMapper().applyServerRow(db, baby);

          for (final v in (baby['vaccinations'] as List? ?? const [])) {
            if (v is Map) {
              await const BabyVaccinationMapper()
                  .applyServerRow(db, Map<String, dynamic>.from(v));
            }
          }
          for (final m in (baby['milestones'] as List? ?? const [])) {
            if (m is Map) {
              await const BabyMilestoneMapper()
                  .applyServerRow(db, Map<String, dynamic>.from(m));
            }
          }
        }
      });
    } catch (e) {
      debugPrint('❌ [SyncService] seed transaction failed: $e');
      return false;
    }

    for (final mapper in kSyncMappers) {
      await _setWatermark(mapper.module, serverTime);
    }

    _notify();
    debugPrint('✅ [SyncService] seeded local database from /me/profile/get_all');
    return true;
  }

  // ── Incremental sync ───────────────────────────────────────────────────────

  /// Runs every module once. Overlapping calls are dropped rather than queued —
  /// the next tick will pick up whatever this pass misses.
  Future<bool> syncAll() async {
    if (_running) return false;
    _running = true;
    var changed = false;
    try {
      for (final mapper in kSyncMappers) {
        changed = await syncModule(mapper.module, notify: false) || changed;
      }
    } finally {
      _running = false;
    }
    if (changed) _notify();
    return changed;
  }

  /// Pushes local edits for one module and applies what the server sends back.
  Future<bool> syncModule(String module, {bool notify = true}) async {
    final mapper = kSyncMappersByModule[module];
    if (mapper == null) return false;

    final db = await _db;
    final watermark = await watermarkFor(module);

    List<Map<String, dynamic>> changes;
    List<String> localDeletes;
    try {
      changes = await mapper.dirtyRows(db);
      localDeletes = await mapper.pendingDeletes(db);
    } catch (e) {
      await _recordFailure(module, 'collect: $e');
      return false;
    }

    final response = await SyncApi.syncModule(
      module,
      syncedAt: watermark,
      changes: changes,
      deletedIds: localDeletes,
    );

    if (!response.success) {
      await _recordFailure(module, response.detail);
      return false;
    }

    // /sync answers with a bare SyncResponse rather than the usual
    // `{detail, item}` envelope, so `synced_at`, `deleted_ids` and `conflicts`
    // only exist on the raw body.
    final body = response.raw;

    final serverTime = SyncCodec.date(body['synced_at']);
    final items = (body['items'] as List? ?? const []);
    final deleted = (body['deleted_ids'] as List? ?? const [])
        .map((e) => e.toString())
        .toList();
    final conflicts = (body['conflicts'] as List? ?? const []);

    var changed = false;
    final appliedIds = <String>{};
    try {
      await db.transaction(() async {
        for (final raw in items) {
          if (raw is Map) {
            final row = Map<String, dynamic>.from(raw);
            await mapper.applyServerRow(db, row);
            appliedIds.add(row['id'].toString());
            changed = true;
          }
        }
        if (deleted.isNotEmpty) {
          await mapper.deleteRows(db, deleted);
          changed = true;
        }

        // The server has our deletions now; the soft-deleted rows can go.
        if (localDeletes.isNotEmpty) {
          await mapper.deleteRows(db, localDeletes);
        }

        // Rows the server accepted are clean now.
        final conflictIds =
            conflicts.map((c) => (c as Map)['id'].toString()).toSet();
        final acceptedIds = changes
            .map((c) => c['id'].toString())
            .where((id) => !conflictIds.contains(id))
            .toList();
        if (acceptedIds.isNotEmpty && serverTime != null) {
          await mapper.markSynced(db, acceptedIds, serverTime);
        }

        // A row that lost a conflict is clean only once the winning server copy
        // has actually overwritten it. Marking it clean without that would drop
        // the local edit *and* keep the stale value — the one outcome worse
        // than either side winning. If the row did not come back, it stays
        // dirty and the next pass tries again.
        final settled = conflictIds.where(appliedIds.contains).toList();
        if (settled.isNotEmpty && serverTime != null) {
          await mapper.markSynced(db, settled, serverTime);
        }
        final unresolved = conflictIds.difference(appliedIds);
        if (unresolved.isNotEmpty) {
          debugPrint(
            '⚠️ [SyncService] $module: ${unresolved.length} conflicted row(s) '
            'came back without the server copy; left queued for retry',
          );
        }
      });
    } catch (e) {
      await _recordFailure(module, 'apply: $e');
      return false;
    }

    if (serverTime != null) {
      await _setWatermark(module, serverTime);
    }

    if (conflicts.isNotEmpty) {
      debugPrint(
        'ℹ️ [SyncService] $module: ${conflicts.length} local edit(s) '
        'superseded by newer server data',
      );
    }

    if (changed && notify) _notify();
    return changed;
  }

  void dispose() {
    stop();
    _listeners.clear();
  }
}
