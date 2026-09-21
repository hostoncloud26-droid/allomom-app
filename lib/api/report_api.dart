import 'dart:typed_data';

import 'package:allomom/api/api_base.dart';
import 'package:allomom/api/response.dart';

/// `/me/reports` — the report library and the Google Drive behind it.
///
/// The device never calls Drive and never holds a Google credential. It hands
/// the server a one-time `serverAuthCode` via [connectDrive], and from then on
/// every upload, download and delete is a call to our own API, which talks to
/// Drive on the user's behalf.
///
/// Reports themselves remain local first: nothing here is on the critical path
/// for saving or reading a report, and every call is expected to fail
/// harmlessly when there is no network.
class ReportApi {
  static const String _base = '/me/reports';

  // ── Drive connection ──────────────────────────────────────────────────────

  /// Trades the Google sign-in's one-time auth code for stored credentials.
  ///
  /// Only a consented sign-in yields a code carrying offline access, so this
  /// must come from a real `GoogleSignIn.signIn()` — a silent one will not
  /// produce a usable code. Once exchanged the server holds a refresh token
  /// and renews access itself; the app has nothing further to do.
  static Future<APIResponse> connectDrive(String serverAuthCode) {
    return ApiBase.post('$_base/drive/connect', {
      'server_auth_code': serverAuthCode,
    });
  }

  /// Whether the server currently holds usable Drive credentials for this user.
  static Future<APIResponse> driveStatus() => ApiBase.get('$_base/drive/status');

  /// Revokes our access at Google. The user's files in Drive are untouched.
  static Future<APIResponse> disconnectDrive() =>
      ApiBase.post('$_base/drive/disconnect', const {});

  // ── Reports ───────────────────────────────────────────────────────────────

  static Future<APIResponse> getReports({int skip = 0, int limit = 20}) {
    return ApiBase.get(_base, query: {'skip': skip, 'limit': limit});
  }

  static Future<APIResponse> getReport(String id) => ApiBase.get('$_base/$id');

  static Future<APIResponse> getReportsSummary() =>
      ApiBase.get('$_base/summary');

  /// Records a report the device already holds, under the id it already has.
  ///
  /// That id is the idempotency key: a retry after a dropped connection
  /// updates the row the first attempt created rather than making a second.
  static Future<APIResponse> saveReport(Map<String, dynamic> report) {
    return ApiBase.post(_base, report);
  }

  static Future<APIResponse> updateReport(
    String id,
    Map<String, dynamic> changes,
  ) {
    return ApiBase.patch('$_base/$id', changes);
  }

  static Future<APIResponse> deleteReport(
    String id, {
    bool keepDriveFiles = false,
  }) {
    return ApiBase.delete(
      '$_base/$id${keepDriveFiles ? '?keep_drive_files=true' : ''}',
    );
  }

  // ── Attachments ───────────────────────────────────────────────────────────

  /// Uploads one of a report's files to the user's Drive.
  ///
  /// [attachmentId] is this device's own id for the file. The server stores it
  /// and returns the existing attachment if it sees the same one twice, so a
  /// retry after a dropped upload cannot put a duplicate in the user's Drive.
  static Future<APIResponse> uploadAttachment({
    required String reportId,
    required String attachmentId,
    required String filePath,
    required String fileName,
    String? mimeType,
  }) {
    return ApiBase.multipart(
      '$_base/$reportId/attachments',
      filePath: filePath,
      fileName: fileName,
      contentType: mimeType,
      fields: {
        'attachment_id': attachmentId,
        'file_name': fileName,
      },
    );
  }

  /// The file's bytes, streamed from Drive through the server.
  static Future<Uint8List?> downloadAttachment(String attachmentId) {
    return ApiBase.getBytes('$_base/attachments/$attachmentId/content');
  }

  static Future<APIResponse> deleteAttachment(
    String attachmentId, {
    bool keepDriveFile = false,
  }) {
    return ApiBase.delete(
      '$_base/attachments/$attachmentId'
      '${keepDriveFile ? '?keep_drive_file=true' : ''}',
    );
  }

  // ── Sync ──────────────────────────────────────────────────────────────────

  /// Pushes local changes and pulls everything changed since [lastSyncedAt].
  ///
  /// Pass a null [lastSyncedAt] to pull the whole library — what a fresh
  /// install, a cleared database or a newly linked Drive needs. File bytes are
  /// not carried here; those go through [uploadAttachment] one at a time.
  static Future<APIResponse> sync({
    DateTime? lastSyncedAt,
    List<Map<String, dynamic>> reports = const [],
    List<String> deletedIds = const [],
  }) {
    return ApiBase.post('$_base/sync', {
      if (lastSyncedAt != null)
        'last_synced_at': lastSyncedAt.toUtc().toIso8601String(),
      'reports': reports,
      'deleted_ids': deletedIds,
    });
  }
}
