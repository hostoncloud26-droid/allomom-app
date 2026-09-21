import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/reports/controller/reports_drive_controller.dart';

const Color _accent = Color(0xFFFF3B5C);
const Color _ink = Color(0xFF1E2024);
const Color _muted = Color(0xFF64748B);
const Color _warn = Color(0xFFB45309);

/// The header of My Reports: the state of the user's Google Drive link.
///
/// Three things it can say, and it only ever says one of them:
///
/// * nothing at all, until the server has answered whether Drive is linked —
///   inviting someone who is already connected to connect again is worse than
///   a moment of silence;
/// * an invitation, when it is not linked;
/// * where the reports are going and what is still on its way, when it is.
///
/// Reports work either way. The wording is careful about that: the offer is to
/// back them up, never to make them work.
class DriveConnectTile extends StatelessWidget {
  const DriveConnectTile({super.key, this.onChanged});

  /// Called after a connect or a sync has changed what the list should show.
  final VoidCallback? onChanged;

  @override
  Widget build(BuildContext context) {
    final controller = ReportsDriveController.instance;

    return Obx(() {
      if (controller.isConnected.value) {
        return _ConnectedTile(controller: controller, onChanged: onChanged);
      }
      // Nothing known yet, and nothing cached: stay quiet.
      if (!controller.connectionChecked.value) {
        return const SizedBox.shrink();
      }
      return _ConnectInviteTile(controller: controller, onChanged: onChanged);
    });
  }
}

class _ConnectInviteTile extends StatelessWidget {
  const _ConnectInviteTile({required this.controller, this.onChanged});

  final ReportsDriveController controller;
  final VoidCallback? onChanged;

  Future<void> _connect(BuildContext context) async {
    final connected = await controller.connect();
    if (!context.mounted) return;

    if (connected) {
      onChanged?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google Drive connected. Your reports are backing up.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final error = controller.syncError.value;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = controller.pendingReports.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFECEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.cloud_upload_outlined,
                    color: _accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connect Google Drive',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      pending > 0
                          ? 'Your $pending report${pending == 1 ? '' : 's'} '
                              'are on this phone only. Back them up to your '
                              'own Drive.'
                          : 'Keep your reports safe in your own Google Drive, '
                              'so a new phone gets them back.',
                      style: GoogleFonts.manrope(
                        fontSize: 12.5,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: _accent,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  controller.isConnecting.value ? null : () => _connect(context),
              icon: controller.isConnecting.value
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.link_rounded, size: 18),
              label: Text(
                controller.isConnecting.value
                    ? 'Connecting…'
                    : 'Connect Google Drive',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedTile extends StatelessWidget {
  const _ConnectedTile({required this.controller, this.onChanged});

  final ReportsDriveController controller;
  final VoidCallback? onChanged;

  Future<void> _confirmDisconnect(BuildContext context) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Text(
              'Disconnect Google Drive?',
              style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Your reports stay on this phone and the files already in your '
              'Drive are left untouched. New reports will stop backing up.',
              style: GoogleFonts.manrope(fontSize: 14, height: 1.45),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Disconnect',
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;
    await controller.disconnect();
    onChanged?.call();
  }

  String _statusLine() {
    if (controller.isSyncing.value) return 'Backing up to Google Drive…';

    final reports = controller.pendingReports.value;
    final files = controller.pendingFiles.value;
    if (reports > 0 || files > 0) {
      final parts = <String>[
        if (reports > 0) '$reports report${reports == 1 ? '' : 's'}',
        if (files > 0) '$files file${files == 1 ? '' : 's'}',
      ];
      return '${parts.join(' and ')} waiting to back up';
    }

    final at = controller.lastSyncedAt.value;
    if (at == null) return 'Saving to AlloMom/Reports in your Drive';
    return 'All reports backed up · ${_ago(at)}';
  }

  static String _ago(DateTime instant) {
    final gap = DateTime.now().difference(instant);
    if (gap.inMinutes < 1) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes}m ago';
    if (gap.inHours < 24) return '${gap.inHours}h ago';
    return '${gap.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final needsReconnect = controller.needsReconnect.value;
    final account = controller.account.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: needsReconnect ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: needsReconnect
              ? const Color(0xFFFCD34D)
              : const Color(0xFFF0F1F5),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: needsReconnect
                  ? const Color(0xFFFEF3C7)
                  : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              needsReconnect
                  ? Icons.warning_amber_rounded
                  : Icons.cloud_done_outlined,
              color: needsReconnect ? _warn : const Color(0xFF059669),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  needsReconnect
                      ? 'Reconnect Google Drive'
                      : (account?.email ?? 'Google Drive'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: needsReconnect ? _warn : _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  needsReconnect
                      ? 'Sign in again to keep backing up your reports'
                      : _statusLine(),
                  maxLines: 2,
                  style: GoogleFonts.manrope(
                    fontSize: 11.5,
                    height: 1.35,
                    color: needsReconnect ? _warn.withValues(alpha: 0.9) : _muted,
                  ),
                ),
              ],
            ),
          ),
          if (needsReconnect)
            TextButton(
              onPressed: controller.isConnecting.value
                  ? null
                  : () async {
                      await controller.connect();
                      onChanged?.call();
                    },
              child: Text(
                'Reconnect',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: _warn,
                ),
              ),
            )
          else if (controller.isSyncing.value)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
              ),
            )
          else
            IconButton(
              tooltip: 'Back up now',
              icon: const Icon(Icons.sync_rounded, size: 20, color: _muted),
              onPressed: () async {
                await controller.syncNow();
                onChanged?.call();
              },
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 20, color: _muted),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (value) async {
              if (value == 'disconnect') {
                await _confirmDisconnect(context);
              } else if (value == 'resync') {
                await controller.syncNow(full: true);
                onChanged?.call();
              }
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'resync',
                child: Text('Sync everything again',
                    style: GoogleFonts.manrope(fontSize: 13)),
              ),
              PopupMenuItem(
                value: 'disconnect',
                child: Text(
                  'Disconnect Drive',
                  style: GoogleFonts.manrope(
                      fontSize: 13, color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
