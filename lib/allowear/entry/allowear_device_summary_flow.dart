import 'package:allomom/allowear/allowear_images.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:localstorage/localstorage.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/allowear_home.dart';

enum AllowearFlowPhase {
  notPaired, // No saved MAC -> "Track your health with AlloWear" + Connect Now
  permissionIssue, // Bluetooth/Location permission required
  connecting, // Saved MAC exists -> Reconnecting to bracelet
  syncing, // Connected -> Syncing health data & steps
  synced, // Successfully synced -> Checkmark & battery badge
  unableToConnect, // Connection timed out/failed -> "Wear your AlloWear"
}

/// AlloConnect's app-open AlloWear card:
/// - If not paired: "Track your health with AlloWear" + "Connect Now"
/// - If paired: Connecting -> Syncing -> Synced, then it closes itself
/// - If unable to connect: "Wear your AlloWear" with Retry & Continue
///
/// AlloConnect then morphs into its WelcomeCard summary with voice narration.
/// Allomom has neither — its home speaks through AlloBaby — so the card simply
/// closes once synced.
class AppOpenDeviceSummaryFlow extends StatefulWidget {
  final VoidCallback? onClose;

  const AppOpenDeviceSummaryFlow({super.key, this.onClose});

  @override
  State<AppOpenDeviceSummaryFlow> createState() =>
      _AppOpenDeviceSummaryFlowState();
}

class _AppOpenDeviceSummaryFlowState extends State<AppOpenDeviceSummaryFlow>
    with TickerProviderStateMixin {
  AllowearFlowPhase _phase = AllowearFlowPhase.connecting;

  // Controllers for ambient animations
  late final AnimationController _pulseController;
  late final AnimationController _progressController;
  late final AnimationController _checkController;

  Timer? _flowTimer;
  Timer? _autoAdvanceTimer;
  Worker? _connectionWorker;
  Worker? _syncWorker;
  Worker? _permissionWorker;

  double _syncProgress = 0.0;

  @override
  void initState() {
    super.initState();

    // Pulse & floating ripple animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Sync progress bar animation (0.0 -> 1.0)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..addListener(() {
        setState(() {
          _syncProgress = _progressController.value;
        });
      });

    // Checkmark scale/bounce animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    _evaluateInitialState();
  }

  @override
  void dispose() {
    _flowTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _connectionWorker?.dispose();
    _syncWorker?.dispose();
    _permissionWorker?.dispose();
    _pulseController.dispose();
    _progressController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  void _evaluateInitialState() {
    final savedMac = allowear.getSavedMac();
    final isConnected = allowear.connectedDevice.value != null;
    final isRealSyncing = allowear.isSyncing.value;

    // 1. If device is already connected
    if (isConnected) {
      if (isRealSyncing) {
        _transitionToPhase(AllowearFlowPhase.syncing);
      } else {
        allowear.startSync();
        _transitionToPhase(AllowearFlowPhase.syncing);
      }
      _listenToRealDevice();
      return;
    }

    // 2. If no saved MAC on record
    if (savedMac == null || savedMac.isEmpty) {
      _transitionToPhase(AllowearFlowPhase.notPaired);
      return;
    }

    // 3. If there is a permission/bluetooth issue
    if (allowear.permissionIssue.value != null) {
      _transitionToPhase(AllowearFlowPhase.permissionIssue);
      _listenToPermissionChanges();
      return;
    }

    // 4. Saved MAC exists -> Attempt connecting
    _startConnectingSequence();
  }

  void _listenToPermissionChanges() {
    _permissionWorker = ever(allowear.permissionIssue, (issue) {
      if (issue == null && _phase == AllowearFlowPhase.permissionIssue) {
        _startConnectingSequence();
      }
    });
  }

  void _startConnectingSequence() {
    _transitionToPhase(AllowearFlowPhase.connecting);
    allowear.startAutoReconnect();

    _listenToRealDevice();

    // Set connection timeout (5.5 seconds)
    _flowTimer?.cancel();
    _flowTimer = Timer(const Duration(milliseconds: 5500), () {
      if (!mounted) return;
      if (allowear.connectedDevice.value == null &&
          _phase == AllowearFlowPhase.connecting) {
        _transitionToPhase(AllowearFlowPhase.unableToConnect);
      }
    });
  }

  void _listenToRealDevice() {
    _connectionWorker?.dispose();
    _connectionWorker = ever(allowear.connectedDevice, (device) {
      if (device != null &&
          (_phase == AllowearFlowPhase.connecting ||
              _phase == AllowearFlowPhase.unableToConnect)) {
        _flowTimer?.cancel();
        allowear.startSync();
        _transitionToPhase(AllowearFlowPhase.syncing);
      }
    });

    _syncWorker?.dispose();
    _syncWorker = ever(allowear.isSyncing, (syncing) {
      if (!syncing && _phase == AllowearFlowPhase.syncing) {
        _flowTimer?.cancel();
        _transitionToPhase(AllowearFlowPhase.synced);
      }
    });
  }

  void _transitionToPhase(AllowearFlowPhase newPhase) {
    if (!mounted) return;

    setState(() {
      _phase = newPhase;
    });

    if (newPhase == AllowearFlowPhase.syncing) {
      HapticFeedback.lightImpact();
      _progressController.forward(from: 0.0);

      // Fallback timer in case sync stream is silent
      _flowTimer?.cancel();
      _flowTimer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        if (_phase == AllowearFlowPhase.syncing) {
          _transitionToPhase(AllowearFlowPhase.synced);
        }
      });
    } else if (newPhase == AllowearFlowPhase.synced) {
      final now = DateTime.now();
      allowear.lastSyncTime.value = now;
      localStorage.setItem('allowear_synced_at', now.toIso8601String());
      HapticFeedback.mediumImpact();
      _checkController.forward(from: 0.0);

      // Show connected state for 2 seconds, then close or advance
      _flowTimer?.cancel();
      _flowTimer = Timer(const Duration(milliseconds: 2000), () {
        if (!mounted) return;
        _closeFlow();
      });
    } else if (newPhase == AllowearFlowPhase.unableToConnect) {
      HapticFeedback.selectionClick();
      // Keep popup open until the user taps Retry, Continue, or Close
      _autoAdvanceTimer?.cancel();
      _flowTimer?.cancel();
    }
  }

  void _closeFlow() {
    _flowTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    if (widget.onClose != null) {
      widget.onClose!();
    } else if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  void _skipOrClose() {
    _flowTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    _closeFlow();
  }

  void _openAllowearHome() {
    _flowTimer?.cancel();
    _autoAdvanceTimer?.cancel();
    if (widget.onClose != null) {
      widget.onClose!();
    }
    Get.to(
      () => const AllowearHome(),
      transition: Transition.rightToLeft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedSize(
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeInOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 0.95).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCardContainer(isDark),
      ),
    );
  }

  Widget _buildCardContainer(bool isDark) {
    return Padding(
      key: ValueKey('sheet_phase_${_phase.name}'),
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeaderRow(isDark),
          const SizedBox(height: 16),
          _buildPhaseContent(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(bool isDark) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _closeFlow,
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhaseContent(bool isDark) {
    switch (_phase) {
      case AllowearFlowPhase.notPaired:
        return _buildNotPairedView(isDark);
      case AllowearFlowPhase.permissionIssue:
        return _buildPermissionIssueView(isDark);
      case AllowearFlowPhase.connecting:
      case AllowearFlowPhase.syncing:
      case AllowearFlowPhase.synced:
        return _buildDeviceConnectedAndSyncView(isDark);
      case AllowearFlowPhase.unableToConnect:
        return _buildUnableToConnectView(isDark);
    }
  }

  // ──────────────────────── 1. NOT PAIRED VIEW ────────────────────────
  Widget _buildNotPairedView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeviceAvatar(
          isDark: isDark,
          haloColor: const Color(0xFF06B6D4),
          iconAsset: AllowearImages.glyph,
        ),
        const SizedBox(height: 14),
        Text(
          'Track Your Health with AlloWear',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Monitor continuous heart rate, sleep cycles, steps, and real-time vital recovery right on your wrist.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 18),
        // Connect Now Primary Button
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAllowearHome,
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF06B6D4), Color(0xFF0284C7)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bluetooth_searching_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Connect Now',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────────── 2. PERMISSION ISSUE VIEW ──────────────────────
  Widget _buildPermissionIssueView(bool isDark) {
    final issue = allowear.permissionIssue.value;
    final title = issue?.title ?? 'Bluetooth Required';
    final desc = issue?.description ??
        'Please turn on Bluetooth to discover and sync your AlloWear bracelet.';
    final actionText = issue?.actionText ?? 'Enable Bluetooth';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeviceAvatar(
          isDark: isDark,
          haloColor: const Color(0xFFF59E0B),
          iconData: Icons.bluetooth_disabled_rounded,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          desc,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => allowear.resolvePermissionIssue(),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFFF59E0B),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                child: Text(
                  actionText,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────── 3. CONNECTING / SYNCING / SYNCED VIEW ────────────────
  Widget _buildDeviceConnectedAndSyncView(bool isDark) {
    final battery = allowear.batteryLevel.value ?? 88;
    final isSynced = _phase == AllowearFlowPhase.synced;

    final Color glowColor = isSynced
        ? const Color(0xFF10B981)
        : const Color(0xFF06B6D4);

    final titleText = isSynced ? 'Allowear Connected' : 'Allowear';
    final statusText = _getStatusText();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeviceAvatar(
          isDark: isDark,
          haloColor: glowColor,
          iconAsset: AllowearImages.glyph,
          showSyncSpinner: _phase == AllowearFlowPhase.syncing,
          showSuccessBadge: isSynced,
        ),
        const SizedBox(height: 12),
        Text(
          titleText,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        if (statusText.isNotEmpty) ...[
          const SizedBox(height: 6),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Text(
              statusText,
              key: ValueKey(_phase),
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
        const SizedBox(height: 14),

        // Progress Bar or Battery Badge or Connecting Dots
        if (_phase == AllowearFlowPhase.syncing)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: _syncProgress.clamp(0.05, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF06B6D4),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${(_syncProgress * 100).toInt()}%',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
              ],
            ),
          )
        else if (_phase == AllowearFlowPhase.synced)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.battery_charging_full_rounded,
                  size: 15,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 5),
                Text(
                  'Battery: $battery%',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(0),
              const SizedBox(width: 4),
              _buildDot(1),
              const SizedBox(width: 4),
              _buildDot(2),
            ],
          ),
      ],
    );
  }

  // ─────────────────── 4. UNABLE TO CONNECT VIEW ─────────────────────
  Widget _buildUnableToConnectView(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildDeviceAvatar(
          isDark: isDark,
          haloColor: const Color(0xFFF59E0B),
          iconAsset: AllowearImages.glyph,
        ),
        const SizedBox(height: 14),
        Text(
          'Wear Your AlloWear',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Make sure your bracelet is nearby, charged, and worn on your wrist to sync your latest health data.',
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.4,
            color: isDark ? Colors.white70 : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Retry Button
            OutlinedButton.icon(
              onPressed: _startConnectingSequence,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: Text(
                'Retry',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    isDark ? Colors.white : const Color(0xFF1E293B),
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.black26,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
            const SizedBox(width: 12),
            // Continue Button
            ElevatedButton(
              onPressed: _skipOrClose,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.manrope(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ────────────────────────── SHARED WIDGETS ──────────────────────────
  Widget _buildDeviceAvatar({
    required bool isDark,
    required Color haloColor,
    String? iconAsset,
    IconData? iconData,
    bool showSyncSpinner = false,
    bool showSuccessBadge = false,
  }) {
    return Center(
      child: SizedBox(
        width: 106,
        height: 106,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ambient Halo Glow
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.12);
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 86,
                    height: 86,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          haloColor.withValues(alpha: isDark ? 0.35 : 0.22),
                          haloColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Rotating sync arcs when syncing
            if (showSyncSpinner)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _pulseController.value * 2 * math.pi,
                    child: Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color:
                              const Color(0xFF06B6D4).withValues(alpha: 0.40),
                          width: 2,
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Central Base Circle
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    isDark ? const Color(0xFF1F2432) : const Color(0xFFE2EDFE),
                border: Border.all(
                  color: haloColor.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: iconAsset != null
                    ? AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final floatOffset =
                              math.sin(_pulseController.value * math.pi) * 2.5;
                          return Transform.translate(
                            offset: Offset(0, floatOffset),
                            child: Image.asset(
                              iconAsset,
                              width: 42,
                              height: 42,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0284C7),
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(
                                Icons.watch_rounded,
                                size: 38,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0284C7),
                              ),
                            ),
                          );
                        },
                      )
                    : Icon(
                        iconData ?? Icons.watch_rounded,
                        size: 36,
                        color: haloColor,
                      ),
              ),
            ),

            // Checkmark Success Badge
            if (showSuccessBadge)
              Positioned(
                right: 10,
                bottom: 10,
                child: ScaleTransition(
                  scale: CurvedAnimation(
                    parent: _checkController,
                    curve: Curves.elasticOut,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF10B981),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x6610B981),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final phaseOffset = (index * 0.3) % 1.0;
        final t = ((_pulseController.value + phaseOffset) % 1.0);
        final opacity = 0.3 + (t * 0.7);
        return Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF06B6D4).withValues(alpha: opacity),
          ),
        );
      },
    );
  }

  String _getStatusText() {
    switch (_phase) {
      case AllowearFlowPhase.connecting:
        return 'Connecting to AlloWear...';
      case AllowearFlowPhase.syncing:
        return 'Syncing health vitals & steps...';
      case AllowearFlowPhase.synced:
      case AllowearFlowPhase.notPaired:
      case AllowearFlowPhase.permissionIssue:
      case AllowearFlowPhase.unableToConnect:
        return '';
    }
  }
}
