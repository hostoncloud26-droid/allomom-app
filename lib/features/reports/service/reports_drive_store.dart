import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What the reports sync has to remember between launches.
///
/// Three things, all small, all in SharedPreferences: which Google account the
/// server last told us was connected, the watermark `/me/reports/sync` resumes
/// from, and the deletes made while offline. The reports themselves live in
/// SQLite — this is only the state that makes the *sync* resumable.
///
/// Keys are scoped to the connected Google account, so linking a different
/// Drive starts from a clean watermark instead of inheriting the last
/// account's.
class ReportsDriveStore {
  static const String _connectedKey = 'reports_drive:connected_email';

  String _scope = 'anonymous';

  /// Points the store at one account's data. Call before any scoped read.
  void useScope(String? email) {
    _scope = (email == null || email.isEmpty) ? 'anonymous' : email;
  }

  String get _syncedAtKey => 'reports_drive:last_synced_at:$_scope';
  String get _deletesKey => 'reports_drive:pending_deletes:$_scope';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  // ── Connection ─────────────────────────────────────────────────────────────

  /// The account the server last reported as connected, so a cold start can
  /// render the connected tile before `/drive/status` comes back.
  Future<String?> readConnectedEmail() async =>
      (await _prefs).getString(_connectedKey);

  Future<void> writeConnectedEmail(String? email) async {
    final prefs = await _prefs;
    if (email == null || email.isEmpty) {
      await prefs.remove(_connectedKey);
      return;
    }
    await prefs.setString(_connectedKey, email);
  }

  // ── Watermark ──────────────────────────────────────────────────────────────

  /// The server clock reading the last sync finished at. Null means the next
  /// sync should pull the whole library.
  Future<DateTime?> readLastSyncedAt() async {
    final raw = (await _prefs).getString(_syncedAtKey);
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> writeLastSyncedAt(DateTime? value) async {
    final prefs = await _prefs;
    if (value == null) {
      await prefs.remove(_syncedAtKey);
      return;
    }
    await prefs.setString(_syncedAtKey, value.toUtc().toIso8601String());
  }

  // ── Pending deletes ────────────────────────────────────────────────────────

  /// Reports the user deleted while offline.
  ///
  /// The local row is gone the moment they confirm — the screen must not lie
  /// about that — so this queue is the only remaining record that the server
  /// still has to be told.
  Future<List<String>> readPendingDeletes() async {
    try {
      final raw = (await _prefs).getString(_deletesKey);
      if (raw == null || raw.isEmpty) return [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<String>().toList();
    } catch (e) {
      debugPrint('ReportsDriveStore: could not read $_deletesKey: $e');
      return [];
    }
  }

  Future<void> addPendingDelete(String reportId) async {
    final queue = await readPendingDeletes();
    if (queue.contains(reportId)) return;
    queue.add(reportId);
    await (await _prefs).setString(_deletesKey, jsonEncode(queue));
  }

  Future<void> removePendingDeletes(Iterable<String> reportIds) async {
    final applied = reportIds.toSet();
    if (applied.isEmpty) return;
    final queue = await readPendingDeletes();
    queue.removeWhere(applied.contains);
    await (await _prefs).setString(_deletesKey, jsonEncode(queue));
  }

  /// Drops everything for the current scope. Used on disconnect: a queued
  /// delete can no longer be delivered as this account.
  Future<void> clearScope() async {
    final prefs = await _prefs;
    await prefs.remove(_syncedAtKey);
    await prefs.remove(_deletesKey);
  }
}
