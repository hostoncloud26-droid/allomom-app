import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:allomom/api/report_api.dart';
import 'package:allomom/api/response.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/reports/service/reports_drive_store.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/report_db_service.dart';

/// The Google identity behind the linked Drive, as the server reports it.
class DriveAccount {
  final String? email;
  final String? name;
  final String? picture;

  const DriveAccount({this.email, this.name, this.picture});

  factory DriveAccount.fromJson(Map<String, dynamic> json) => DriveAccount(
        email: json['email'] as String?,
        name: json['name'] as String?,
        picture: json['picture'] as String?,
      );

  /// Something to put on the tile when Google gave us no display name.
  String get label => (name != null && name!.isNotEmpty)
      ? name!
      : (email ?? 'Google Drive');
}

/// Links My Reports to the user's own Google Drive.
///
/// Reports do not depend on this. They are written to SQLite when the user
/// saves them and read from SQLite when the list opens — no account, no
/// network, no Drive. What this controller adds is a second home for them: the
/// metadata goes to `/me/reports`, the scans go to the user's Drive under
/// `AlloMom/Reports`, and a reinstall or a second phone gets both back.
///
/// Drive is never reached from here. At sign-in the app hands the server a
/// one-time `serverAuthCode`; the server keeps the refresh token and renews
/// access itself, so this controller never holds a Google credential.
///
/// A failed sync is never a failed screen. The local rows stay exactly as they
/// were, the delete queue stays intact, and [syncNow] settles up the next time
/// there is a connection.
class ReportsDriveController extends GetxController {
  static ReportsDriveController get instance =>
      Get.isRegistered<ReportsDriveController>()
          ? Get.find<ReportsDriveController>()
          : Get.put(ReportsDriveController(), permanent: true);

  final ReportsDriveStore _store = ReportsDriveStore();

  Rx<DriveAccount?> account = Rx<DriveAccount?>(null);
  RxBool isConnected = false.obs;
  RxBool isConnecting = false.obs;
  RxBool isSyncing = false.obs;

  /// Set when the server holds a connection but has lost its ability to renew
  /// Drive access, so only a fresh consented sign-in can restore it.
  RxBool needsReconnect = false.obs;

  /// False until `/drive/status` has given a definitive answer.
  ///
  /// The credentials live on the server, so until it replies this device does
  /// not know whether Drive is linked — and a fresh install has no cache to
  /// guess from. The tile stays quiet rather than inviting a user who is
  /// already connected to connect again.
  RxBool connectionChecked = false.obs;

  /// How many reports and files are still waiting to go up.
  RxInt pendingReports = 0.obs;
  RxInt pendingFiles = 0.obs;

  Rx<DateTime?> lastSyncedAt = Rx<DateTime?>(null);

  /// The last sync failure worth telling the user about, or null.
  RxnString syncError = RxnString();

  Future<void>? _statusCheck;

  ConnectionController? get _connection =>
      Get.isRegistered<ConnectionController>()
          ? Get.find<ConnectionController>()
          : null;

  bool get _isOnline => _connection?.isInternetAvailable ?? true;

  bool get hasPendingWork => pendingReports.value > 0 || pendingFiles.value > 0;

  String get _healthScope => ReportDbService.localHealthScope(
        healthDataId: MainController.instance.healthDataId,
        userId: MainController.instance.userId,
      );

  @override
  void onInit() {
    super.onInit();
    _bootstrap();

    final connection = _connection;
    if (connection != null) {
      ever<bool>(connection.isInternetAvailableRx, (online) {
        if (!online) return;
        // Connectivity arriving is the cue to finish what booting could not.
        if (isConnected.value) {
          syncNow();
        } else {
          refreshConnection();
        }
      });
    }
  }

  /// Cache first, network second: the tile should render its last known state
  /// before `/drive/status` answers, and keep it if the call never lands.
  Future<void> _bootstrap() async {
    await refreshPendingCounts();

    final email = await _store.readConnectedEmail();
    if (email != null && email.isNotEmpty) {
      _store.useScope(email);
      isConnected.value = true;
      account.value = DriveAccount(email: email);
      lastSyncedAt.value = await _store.readLastSyncedAt();
    }

    await refreshConnection();
  }

  // ── Connection ─────────────────────────────────────────────────────────────

  /// Asks the server whether it still holds usable Drive credentials.
  ///
  /// The only source of truth for [isConnected] — the device has no Google
  /// session of its own to inspect.
  Future<void> refreshConnection() {
    final inFlight = _statusCheck;
    if (inFlight != null) return inFlight;

    final check = _checkStatus();
    _statusCheck = check;
    return check.whenComplete(() => _statusCheck = null);
  }

  Future<void> _checkStatus() async {
    // Offline we cannot find out, and must not guess: leaving
    // connectionChecked false keeps the tile from claiming either state. The
    // connectivity listener calls back here the moment there is a network.
    if (!_isOnline) return;

    final APIResponse response;
    try {
      response = await ReportApi.driveStatus();
    } catch (e) {
      debugPrint('ReportsDriveController: status check failed: $e');
      return;
    }

    // A transient failure is not an answer either. Same reasoning.
    if (!response.success) return;

    connectionChecked.value = true;

    final item = response.item;
    if (item is! Map || item['connected'] != true) {
      await _applyDisconnected();
      return;
    }

    final claims = Map<String, dynamic>.from(item);
    await _applyConnected(DriveAccount.fromJson(claims));
    needsReconnect.value = claims['offline_access'] != true;

    await syncNow();
  }

  /// Signs in with Google and hands the resulting auth code to the server.
  ///
  /// Returns true once the server confirms the link. The code is single-use,
  /// and only a consented sign-in produces one carrying offline access — which
  /// is why this goes through a full sign-in rather than a silent refresh.
  Future<bool> connect() async {
    if (isConnecting.value) return false;
    if (!_isOnline) {
      syncError.value = 'Internet connection required to connect Google Drive';
      return false;
    }

    isConnecting.value = true;
    syncError.value = null;
    try {
      final serverAuthCode = await GoogleAuthService.driveServerAuthCode();
      if (serverAuthCode == null) {
        // Either the user backed out, or Google returned no auth code — which
        // happens when the sign-in carries no serverClientId, leaving the
        // server nothing to exchange.
        return false;
      }

      final response = await ReportApi.connectDrive(serverAuthCode);
      if (!response.success) {
        syncError.value = response.detail;
        return false;
      }

      final item = response.item;
      await _applyConnected(
        item is Map
            ? DriveAccount.fromJson(Map<String, dynamic>.from(item))
            : const DriveAccount(),
      );
      needsReconnect.value = false;
      connectionChecked.value = true;

      // The library on the server may predate this device entirely, and
      // everything already on this one has yet to be pushed.
      await syncNow(full: true);
      return true;
    } catch (e) {
      debugPrint('ReportsDriveController: connect failed: $e');
      syncError.value = 'Could not connect Google Drive. Please try again.';
      return false;
    } finally {
      isConnecting.value = false;
    }
  }

  /// Unlinks Drive: the server revokes its credentials and this device forgets
  /// the sync state. The reports stay in SQLite and the files stay in the
  /// user's Drive — nothing the user can see disappears.
  Future<void> disconnect() async {
    try {
      await ReportApi.disconnectDrive();
    } catch (e) {
      debugPrint('ReportsDriveController: disconnect call failed: $e');
    }

    await GoogleAuthService.driveSignOut();
    await _store.clearScope();
    await _applyDisconnected();
    await refreshPendingCounts();
  }

  Future<void> _applyConnected(DriveAccount next) async {
    final previousEmail = account.value?.email;
    account.value = next;
    isConnected.value = true;
    _store.useScope(next.email);
    await _store.writeConnectedEmail(next.email);

    // A different Google account means a different library; the watermark we
    // were holding belongs to someone else.
    if (previousEmail != null && previousEmail != next.email) {
      await _store.writeLastSyncedAt(null);
    }
    lastSyncedAt.value = await _store.readLastSyncedAt();
  }

  Future<void> _applyDisconnected() async {
    isConnected.value = false;
    account.value = null;
    needsReconnect.value = false;
    lastSyncedAt.value = null;
    await _store.writeConnectedEmail(null);
  }

  // ── Sync ───────────────────────────────────────────────────────────────────

  /// Settles the device and the server with each other.
  ///
  /// Order matters at each step. Report metadata is pushed first, because a
  /// file cannot be attached to a report the server has never heard of. Then
  /// the files, one at a time, so a dropped connection costs one upload rather
  /// than the whole batch. Then what the server changed is applied locally.
  ///
  /// Pass [full] to discard the watermark and pull the whole library — what a
  /// freshly linked Drive or a cleared database needs.
  Future<void> syncNow({bool full = false}) async {
    if (isSyncing.value) return;
    if (!isConnected.value || !_isOnline) {
      await refreshPendingCounts();
      return;
    }

    isSyncing.value = true;
    syncError.value = null;
    try {
      await _sendAttachmentDeletes();
      final pendingFileDeletes =
          (await _store.readPendingAttachmentDeletes()).toSet();

      final dirty = await ReportDbService.instance.unsyncedReports();
      final queuedDeletes = await _store.readPendingDeletes();

      final response = await ReportApi.sync(
        lastSyncedAt: full ? null : await _store.readLastSyncedAt(),
        reports: dirty.map(_reportToPayload).toList(),
        deletedIds: queuedDeletes,
      );

      if (!response.success || response.item is! Map) {
        // Nothing local is touched: the rows stay dirty and the delete queue
        // stays full, so the next attempt picks up exactly where this left off.
        syncError.value = response.networkError ? null : response.detail;
        return;
      }

      final item = Map<String, dynamic>.from(response.item as Map);

      await _store.removePendingDeletes(
        (item['applied_deletes'] as List? ?? []).whereType<String>(),
      );

      // Rows the server rejected stay dirty so the conflict is retried with
      // whatever the pull below hands us.
      final lost = (item['conflicts'] as List? ?? [])
          .whereType<Map>()
          .map((c) => c['id']?.toString())
          .whereType<String>()
          .toSet();
      await ReportDbService.instance.markReportsSynced(
        dirty.map((r) => r.id).where((id) => !lost.contains(id)),
      );

      await _applyPulled(item, skipAttachments: pendingFileDeletes);
      await _uploadPendingFiles();

      final syncedAt = DateTime.tryParse(item['synced_at'] as String? ?? '');
      if (syncedAt != null) {
        await _store.writeLastSyncedAt(syncedAt);
        lastSyncedAt.value = syncedAt;
      }
    } catch (e) {
      debugPrint('ReportsDriveController: sync failed: $e');
    } finally {
      await refreshPendingCounts();
      isSyncing.value = false;
    }
  }

  /// One dirty report, in the shape `/me/reports/sync` accepts.
  ///
  /// `detail` goes up as the parsed object rather than the JSON string the
  /// column holds, and the local file paths inside it are the server's to
  /// drop — the attachment rows describe those files properly.
  Map<String, dynamic> _reportToPayload(Report report) {
    return {
      'id': report.id,
      'report_type': report.reportType,
      if (report.description != null && report.description!.isNotEmpty)
        'description': report.description,
      'detail': ReportDbService.decodeDetail(report),
      'created_at': report.createdAt.toUtc().toIso8601String(),
      // The row has no modified stamp of its own, so its creation time is the
      // best claim it can make. That loses a conflict against a server row
      // edited later, which is the outcome we want: the phone that pushed last
      // is the one holding the newer text.
      'updated_at': report.createdAt.toUtc().toIso8601String(),
    };
  }

  /// Writes what the server changed into the local database.
  ///
  /// [skipAttachments] are files the user removed that the server has not
  /// yet confirmed deleting; they are left out rather than brought back.
  Future<void> _applyPulled(
    Map<String, dynamic> payload, {
    Set<String> skipAttachments = const {},
  }) async {
    final scope = _healthScope;

    for (final raw in (payload['reports'] as List? ?? []).whereType<Map>()) {
      final report = Map<String, dynamic>.from(raw);
      final id = report['id']?.toString();
      if (id == null || id.isEmpty) continue;

      final detail = report['detail'];
      await ReportDbService.instance.upsertFromServer(
        id: id,
        healthScope: scope,
        reportType: report['report_type']?.toString() ?? 'Report',
        description: report['description']?.toString(),
        detailJson: detail is Map ? jsonEncode(detail) : null,
        createdBy: report['created_by']?.toString(),
        createdAt: DateTime.tryParse(report['created_at']?.toString() ?? ''),
      );

      for (final rawFile
          in (report['attachments'] as List? ?? []).whereType<Map>()) {
        final file = Map<String, dynamic>.from(rawFile);
        final fileId = file['id']?.toString();
        if (fileId == null || fileId.isEmpty) continue;
        if (skipAttachments.contains(fileId)) continue;

        await ReportDbService.instance.upsertAttachmentFromServer(
          id: fileId,
          reportId: id,
          fileName: file['file_name']?.toString(),
          mimeType: file['file_type']?.toString(),
          fileSizeBytes: file['file_size'] is int ? file['file_size'] as int : null,
          cloudUrl: file['file_url']?.toString(),
          createdAt: DateTime.tryParse(file['created_at']?.toString() ?? ''),
        );
      }
    }

    for (final rawId in (payload['deleted_ids'] as List? ?? [])) {
      final id = rawId?.toString();
      if (id == null || id.isEmpty) continue;
      // Deleted elsewhere — on another phone, or on a previous install of this
      // one. `deleteReport` takes the attachment rows with it.
      await ReportDbService.instance.deleteReport(id);
    }
  }

  /// Uploads every file that is on this device but not yet in Drive.
  ///
  /// Stops at the first network failure rather than burning through the queue
  /// against a connection that is plainly down.
  Future<void> _uploadPendingFiles() async {
    final queue = await ReportDbService.instance.attachmentsAwaitingUpload();

    for (final attachment in queue) {
      final reportId = attachment.reportId;
      if (reportId == null || reportId.isEmpty) continue;

      if (!File(attachment.localPath).existsSync()) {
        // The source is gone, so there is nothing left to upload. The row
        // stays: it still records that the report had this file.
        debugPrint('ReportsDriveController: queued file missing, skipping '
            '${attachment.localPath}');
        continue;
      }

      final response = await ReportApi.uploadAttachment(
        reportId: reportId,
        attachmentId: attachment.id,
        filePath: attachment.localPath,
        fileName: attachment.fileName ?? p.basename(attachment.localPath),
        mimeType: attachment.mimeType,
      );

      if (response.success) {
        final item = response.item;
        await ReportDbService.instance.markAttachmentUploaded(
          attachment.id,
          item is Map ? item['file_url']?.toString() : null,
        );
        continue;
      }

      if (response.networkError) return;

      // A rejection the server will keep making — a file too large, a report
      // deleted underneath it — is logged and left alone rather than retried
      // on every sync for the rest of the install's life.
      debugPrint('ReportsDriveController: upload rejected for '
          '${attachment.id}: ${response.detail}');
    }
  }

  Future<void> refreshPendingCounts() async {
    try {
      pendingReports.value =
          (await ReportDbService.instance.unsyncedReports()).length;
      pendingFiles.value =
          (await ReportDbService.instance.attachmentsAwaitingUpload()).length;
    } catch (e) {
      debugPrint('ReportsDriveController: could not count pending work: $e');
    }
  }

  // ── Deletes ────────────────────────────────────────────────────────────────

  /// Records that a report the user just deleted locally has to go on the
  /// server too.
  ///
  /// Queued rather than sent, because the row is already gone from the screen
  /// and the user should not be made to wait — or to care — about the network.
  Future<void> queueDelete(String reportId) async {
    if (!isConnected.value) return;
    await _store.addPendingDelete(reportId);
    if (_isOnline) {
      await syncNow();
    }
  }

  /// Removes one file from a report: the local row now, the Drive copy on
  /// the next sync.
  ///
  /// A file that never reached Drive has nothing to delete remotely, so only
  /// uploaded ones are queued.
  Future<void> deleteAttachment(ReportAttachment attachment) async {
    await ReportDbService.instance.deleteAttachment(attachment.id);
    if (attachment.cloudUrl != null || attachment.synced == 1) {
      await _store.addPendingAttachmentDelete(attachment.id);
    }
    await refreshPendingCounts();
  }

  /// Tells the server about removed files.
  ///
  /// A network failure leaves the rest of the queue for next time. A rejection
  /// — most often a file the server no longer has — is logged and dropped,
  /// like a rejected upload, rather than retried on every sync.
  Future<void> _sendAttachmentDeletes() async {
    final queue = await _store.readPendingAttachmentDeletes();
    final applied = <String>[];
    for (final id in queue) {
      final response = await ReportApi.deleteAttachment(id);
      if (response.networkError) break;
      if (!response.success) {
        debugPrint('ReportsDriveController: attachment delete rejected for '
            '$id: ${response.detail}');
      }
      applied.add(id);
    }
    await _store.removePendingAttachmentDeletes(applied);
  }

  // ── File contents ──────────────────────────────────────────────────────────

  /// A report file on disk: the local copy if there is one, Drive if not.
  ///
  /// A file has no local copy when this device never held it — a report
  /// scanned on another phone, or restored after a reinstall. It is downloaded
  /// once and cached, and the attachment row is pointed at the cache, so
  /// opening the report a second time costs nothing.
  ///
  /// Returns null rather than throwing: offline, with nothing cached, there is
  /// simply nothing to show yet, and the screen says so.
  Future<File?> attachmentFile(ReportAttachment attachment) async {
    if (attachment.localPath.isNotEmpty) {
      final local = File(attachment.localPath);
      if (await local.exists()) return local;
    }

    if (!isConnected.value || !_isOnline) return null;

    final bytes = await ReportApi.downloadAttachment(attachment.id);
    if (bytes == null) return null;

    try {
      final cached = await _cacheFile(attachment, bytes);
      await ReportDbService.instance
          .setAttachmentLocalPath(attachment.id, cached.path);
      return cached;
    } catch (e) {
      debugPrint('ReportsDriveController: could not cache ${attachment.id}: $e');
      return null;
    }
  }

  Future<File> _cacheFile(ReportAttachment attachment, Uint8List bytes) async {
    final directory = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(directory.path, 'report_files'));
    if (!await dir.exists()) await dir.create(recursive: true);

    final name = attachment.fileName?.isNotEmpty == true
        ? '${attachment.id}_${p.basename(attachment.fileName!)}'
        : attachment.id;
    final file = File(p.join(dir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }
}
