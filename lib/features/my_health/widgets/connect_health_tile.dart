import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:localstorage/localstorage.dart';

import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/sync_functions.dart';
import 'package:allomom/config/app_theme.dart';

/// The phone's own health store (Apple Health / Health Connect) as a step
/// source, for when no AlloWear is paired on this phone.
class PhoneHealthLink {
  PhoneHealthLink._();

  static const _connectedKey = 'phone_health_connected';

  /// Apple Health on iOS, Health Connect on Android.
  static String get storeName =>
      Platform.isIOS ? 'Apple Health' : 'Health Connect';

  /// She has linked the phone's health store from the Connect Health tile.
  static bool get isConnected =>
      localStorage.getItem(_connectedKey) == 'true';

  /// A paired AlloWear is the authority for steps, so the phone store is only
  /// offered without one.
  static bool get isAvailable => getConnectedAllowearMac() == null;

  /// Asks for step access and pulls today's steps. True once steps landed.
  static Future<bool> connect() async {
    final ok =
        await allowear.syncDeviceHealthData(requestPermissionIfDenied: true);
    if (ok) localStorage.setItem(_connectedKey, 'true');
    return ok;
  }

  /// Pulls today's steps without prompting, if she has linked the store.
  static Future<void> syncIfConnected() async {
    if (!isConnected || !isAvailable) return;
    await allowear.syncDeviceHealthData();
  }
}

/// Sits above the Step Count tile while no AlloWear is paired: offers to link
/// Apple Health / Health Connect, then to re-sync steps from it.
class ConnectHealthTile extends StatefulWidget {
  /// Called after steps were pulled from the phone's health store.
  final VoidCallback? onSynced;

  const ConnectHealthTile({super.key, this.onSynced});

  @override
  State<ConnectHealthTile> createState() => _ConnectHealthTileState();
}

class _ConnectHealthTileState extends State<ConnectHealthTile> {
  bool _busy = false;

  Future<void> _onTap() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    setState(() => _busy = true);
    final ok = await PhoneHealthLink.connect();
    if (!mounted) return;
    setState(() => _busy = false);

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      widget.onSynced?.call();
      messenger.showSnackBar(
        SnackBar(content: Text('Steps synced from ${PhoneHealthLink.storeName}')),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Could not read steps. Allow step access for AlloMoM in '
            '${PhoneHealthLink.storeName}.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!PhoneHealthLink.isAvailable) return const SizedBox.shrink();

    final isDark = context.palette.isDark;
    final connected = PhoneHealthLink.isConnected;
    const accent = Color(0xFFFF3B5C);
    final textColor = isDark ? Colors.white : Colors.black87;
    final subtitleColor = isDark ? Colors.white60 : Colors.black54;
    final store = PhoneHealthLink.storeName;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.3 : 0.2),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: _busy ? null : _onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        connected ? '$store connected' : 'Connect $store',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        connected
                            ? 'Steps sync when you refresh'
                            : 'Fetch your steps automatically',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: subtitleColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: accent,
                          ),
                        )
                      : Text(
                          connected ? 'Sync' : 'Connect',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
