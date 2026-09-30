import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/core/models/ble_device.dart';
import 'package:localstorage/localstorage.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/allowear_home.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/sync_functions.dart';
import 'package:allomom/allowear/compat/user_api.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

class AllowearStatusTileCard extends StatefulWidget {
  const AllowearStatusTileCard({super.key});

  @override
  State<AllowearStatusTileCard> createState() => _AllowearStatusTileCardState();
}

class _AllowearStatusTileCardState extends State<AllowearStatusTileCard>
    with SingleTickerProviderStateMixin {
  late final AllowearController _allowear;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Worker? _connectedWorker;
  Worker? _batteryWorker;

  /// Last battery level recorded in vitals, shown while the band is offline.
  int? _lastSyncedBattery;

  @override
  void initState() {
    super.initState();
    _allowear = allowear;

    // Refresh battery on launch if already connected
    if (_allowear.connectedDevice.value != null) {
      _allowear.refreshBattery();
    }

    // Reactively refresh battery whenever a device connects
    _connectedWorker = ever(_allowear.connectedDevice, (device) {
      if (device != null) {
        _allowear.refreshBattery();
      } else {
        _loadLastSyncedBattery();
      }
    });

    // Keep the offline fallback in step with live readings
    _batteryWorker = ever(_allowear.batteryLevel, (level) {
      if (level != null && level > 0 && mounted) {
        setState(() => _lastSyncedBattery = level);
      }
    });

    _loadLastSyncedBattery();

    // Subtle pulse animation for connection status
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _connectedWorker?.dispose();
    _batteryWorker?.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadLastSyncedBattery() async {
    final userId = Userapi.getUserID();
    if (userId == null || userId.isEmpty) return;
    try {
      final latest =
          await VitalsSqLiteService().getLatestVital(userId, 'battery');
      final value = (latest?['value'] as num?)?.round();
      if (!mounted || value == null || value <= 0) return;
      setState(() => _lastSyncedBattery = value);
    } catch (e) {
      debugPrint('[AllowearTile] loading last battery failed: $e');
    }
  }

  void _onCardTapped() {
    HapticFeedback.lightImpact();
    Get.to(
      () => const AllowearHome(),
      transition: Transition.rightToLeft,
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60 && !difference.isNegative) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24) {
      final hrs = difference.inHours;
      return '$hrs ${hrs == 1 ? 'hr' : 'hrs'} ago';
    } else if (difference.inDays < 30) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);
    final cardBgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Black800;
    final subtitleColor = isDark ? Colors.white60 : Black700;

    return Obx(() {
      final connectedDevice = _allowear.connectedDevice.value;
      final isConnected = connectedDevice != null;
      final isConnecting = _allowear.isConnecting.value;
      final isSyncing = _allowear.isSyncing.value;
      final hasSavedDevice = getConnectedAllowearMac()?.isNotEmpty == true;
      // Live level when connected; otherwise the last one saved to vitals,
      // as long as a band is still paired.
      // A 0 from the battery stream means the band didn't answer, not empty.
      final rawLive = _allowear.batteryLevel.value;
      final liveBattery = (rawLive != null && rawLive > 0) ? rawLive : null;
      final battery = isConnected
          ? (liveBattery ?? _lastSyncedBattery)
          : (hasSavedDevice ? (liveBattery ?? _lastSyncedBattery) : null);

      DateTime? syncTime = _allowear.lastSyncTime.value;
      if (syncTime == null) {
        final stored = (localStorage.getItem('allowear_synced_atm') ??
                localStorage.getItem('allowear_synced_at'))
            ?.trim();
        if (stored != null && stored.isNotEmpty) {
          syncTime = DateTime.tryParse(stored);
        }
      }

      final Color statusColor = isConnected
          ? const Color(0xFF10B981) // Emerald Green
          : (isConnecting || isSyncing)
              ? const Color(0xFFF59E0B) // Amber
              : (syncTime != null
                  ? const Color(0xFF10B981)
                  : const Color(0xFF9CA3AF)); // Neutral Grey

      String statusText;
      if (isSyncing) {
        statusText = 'Syncing...'.tr;
      } else if (isConnecting) {
        statusText = 'Connecting...'.tr;
      } else if (syncTime != null) {
        statusText = 'Last Synced: ${_formatTimeAgo(syncTime)}';
      } else if (isConnected) {
        statusText = 'Last Synced: Just now';
      } else {
        statusText = 'Disconnected'.tr;
      }

      final Color cardBorderColor = isConnected
          ? const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.2)
          : (isConnecting || isSyncing)
              ? const Color(0xFFF59E0B).withValues(alpha: isDark ? 0.3 : 0.2)
              : (isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.06));

      return Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: isConnected
                  ? const Color(0xFF10B981)
                      .withValues(alpha: isDark ? 0.12 : 0.05)
                  : Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: _onCardTapped,
            borderRadius: BorderRadius.circular(18),
            splashColor: primaryColor.withValues(alpha: 0.08),
            highlightColor: primaryColor.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children: [
                  // Left: Allowear Icon Badge
                  Container(
                    width: 46,
                    height: 46,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color:
                          (isConnected ? const Color(0xFF10B981) : primaryColor)
                              .withValues(alpha: isDark ? 0.18 : 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.asset(
                      'assets/allowear/bracelet_white.png',
                      width: 28,
                      height: 28,
                      color: isConnected
                          ? const Color(0xFF10B981)
                          : (isDark ? Colors.white : primaryColor),
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.watch_rounded,
                        size: 26,
                        color: isConnected
                            ? const Color(0xFF10B981)
                            : primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Middle: Device Name / Allowear Title and Connection Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Allowear'.tr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FadeTransition(
                              opacity: (isConnecting || isSyncing)
                                  ? _pulseAnimation
                                  : const AlwaysStoppedAnimation(1.0),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                statusText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (battery != null && battery < 20) ...[
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.power_rounded,
                                size: 13,
                                color: AllowearBatteryStyle.color(battery),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Low battery, please charge your device'.tr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                    color: AllowearBatteryStyle.color(battery),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Right: Battery Health (live or last synced) and Navigation Chevron
                  if (battery != null) ...[
                    _buildBatteryHealthBadge(
                      batteryLevel: battery,
                      isDark: isDark,
                      textColor: textColor,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: subtitleColor.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBatteryHealthBadge({
    required int? batteryLevel,
    required bool isDark,
    required Color textColor,
  }) {
    final int safeLevel = batteryLevel ?? 0;
    final Color batteryColor = safeLevel > 0
        ? AllowearBatteryStyle.color(safeLevel)
        : const Color(0xFF10B981);
    final IconData batteryIcon = safeLevel > 0
        ? AllowearBatteryStyle.icon(safeLevel)
        : Icons.battery_charging_full_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: batteryColor.withValues(alpha: isDark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: batteryColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            batteryIcon,
            color: batteryColor,
            size: 15,
          ),
          const SizedBox(width: 5),
          Text(
            batteryLevel != null ? '$batteryLevel%' : '--%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: batteryColor,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
