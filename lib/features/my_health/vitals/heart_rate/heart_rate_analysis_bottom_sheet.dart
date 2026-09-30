import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/features/heart_rate/views/heart_rate_card.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'camera_heart_rate_dialog.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class HeartRateAnalysisBottomSheet extends StatefulWidget {
  final Function(VitalsStreamResponse response) onComplete;
  final String userId;

  const HeartRateAnalysisBottomSheet({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  @override
  State<HeartRateAnalysisBottomSheet> createState() =>
      _HeartRateAnalysisBottomSheetState();
}

class _HeartRateAnalysisBottomSheetState
    extends State<HeartRateAnalysisBottomSheet> {
  late final HealthVitalsController _vitalsController;
  late final AllowearController _deviceController;
  late final AllowearMeasurement _allowearHeartRateController;
  late final AllowearController _healthSyncController;


  bool _isSaving = false;
  bool _startedAllowearAnalysis = false;
  bool _autoSyncTriggered = false;
  bool _awaitingSyncCompletion = false;
  Worker? _syncCompletionWorker;

  @override
  void initState() {
    super.initState();
    _vitalsController = Get.isRegistered<HealthVitalsController>()
        ? Get.find<HealthVitalsController>()
        : Get.put(HealthVitalsController());
    _deviceController = allowear;
    _allowearHeartRateController = allowear.hr;
    _healthSyncController = allowear;
    _syncCompletionWorker =
        ever(_healthSyncController.isSyncing, (bool syncing) {
      if (!mounted || !_awaitingSyncCompletion || syncing) {
        return;
      }
      _handleSyncFinished();
    });

    // Auto-sync worker: trigger sync when Allowear measurement finishes
    ever(_allowearHeartRateController.isMonitoring, (bool monitoring) {
      if (!mounted) return;
      final status = _allowearHeartRateController.status.value;
      if (!monitoring &&
          status == 'Done' &&
          !_autoSyncTriggered &&
          !_awaitingSyncCompletion) {
        _autoSyncTriggered = true;
        _syncAllowearHealthData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _startAllowearAnalysisIfNeeded(restart: false);
    });
  }

  @override
  void dispose() {
    _syncCompletionWorker?.dispose();

    if (_startedAllowearAnalysis &&
        _allowearHeartRateController.isMonitoring.value) {
      _allowearHeartRateController.stop();
    }
    super.dispose();
  }

  Future<void> _startAllowearAnalysisIfNeeded({required bool restart}) async {
    final connectedDevice = _deviceController.connectedDevice.value;
    if (connectedDevice == null || (_startedAllowearAnalysis && !restart)) {
      return;
    }

    _startedAllowearAnalysis = true;
    await _allowearHeartRateController.start();
  }

  Future<void> _measureWithCamera() async {
    final bpm = await showDialog<int?>(
      context: context,
      builder: (context) => const CameraHeartRateDialog(),
    );

    if (bpm == null || !mounted) {
      return;
    }

    // Auto save the camera reading
    await _saveReading(bpm);
  }



  Future<void> _syncAllowearHealthData() async {
    if (_healthSyncController.isSyncing.value || _awaitingSyncCompletion) {
      return;
    }

    if (_allowearHeartRateController.isMonitoring.value) {
      await _allowearHeartRateController.stop();
    }

    _awaitingSyncCompletion = true;
    await _healthSyncController.startSync();
  }

  Future<void> _handleSyncFinished() async {
    _awaitingSyncCompletion = false;
    await _vitalsController.fetchLatestVitals();
    if (!mounted) {
      return;
    }

    final didSucceed = _healthSyncController.syncStatus.value
        .toLowerCase()
        .contains('completed successfully');

    if (didSucceed) {
      // Navigator.of(context).pop(true);
    }
  }

  Future<void> _saveReading(int bpm) async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final vital = await _vitalsController.addVitalEntry(
      key: 'heart_rate',
      value: bpm.toDouble(),
      unit: 'bpm',
      createdAt: DateTime.now(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    Navigator.of(context).pop(true);

    if (vital == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _vitalsController.error.isEmpty
                ? 'Unable to save heart rate right now.'
                : _vitalsController.error,
          ),
        ),
      );
      return;
    }

    if (_allowearHeartRateController.isMonitoring.value) {
      await _allowearHeartRateController.stop();
    }

    if (!mounted) {
      return;
    }

    widget.onComplete(vital);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Heart rate saved: $bpm BPM')),
    );
    // Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Obx(() {
      final connectedDevice = _deviceController.connectedDevice.value;
      final isConnected = connectedDevice != null;

      if (isConnected && !_startedAllowearAnalysis) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startAllowearAnalysisIfNeeded(restart: false);
          }
        });
      }

      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF12161F) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
            border: Border.all(
              color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
              width: 1,
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 16, bottom: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 52,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.16)
                            : Colors.black.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (!isConnected) ...[
                    const SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Start',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        isConnected
                            ? 'Allowear is connected, so this will capture your reading directly from the device.'
                            : 'Allowear is not connected. Enter your heart rate manually or measure it with your phone camera.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (isConnected)
                    _buildAllowearPanel(context, connectedDevice.name)
                  else
                    _buildCameraPanel(context),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAllowearPanel(BuildContext context, String deviceName) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Use the premium HeartRateCard for the monitoring UI
        const HeartRateCard(
          margin: EdgeInsets.zero,
          showShadow: false,
          showBorder: false,
        ),

        const SizedBox(height: 16),

        // Custom Sync Status Overlay if syncing is active
        Obx(() {
          final isSyncing = _healthSyncController.isSyncing.value;
          final syncStatus = _healthSyncController.syncStatus.value;
          final syncProgress = _healthSyncController.syncProgress.value;

          if (!isSyncing && !_awaitingSyncCompletion)
            return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF00B66D).withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF00B66D)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          syncStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF103B2A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (isSyncing) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: syncProgress <= 0 ? null : syncProgress / 100,
                      borderRadius: BorderRadius.circular(999),
                      minHeight: 6,
                      backgroundColor: const Color(0xFF00B66D).withOpacity(0.1),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF00B66D)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildCameraPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isSaving ? null : _measureWithCamera,
            child: Container(
              height: 140,
              width: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF5252), Color(0xFFFF7B7B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5252).withOpacity(0.35),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 44,
                      color: Colors.white.withOpacity(0.95),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.favorite_rounded,
                      size: 24,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Measure with Phone Camera'.tr,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              fontSize: 18,
              fontFamily: 'Manrope',
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Use your phone camera and flash to measure your heart rate in real time without any active Allowear connection.'
                .tr,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Manrope',
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _measureWithCamera,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.play_arrow_rounded, size: 24),
              label: FittedBox(
                  child: Text(_isSaving
                      ? 'Saving...'.tr
                      : 'Start Camera Measurement'.tr)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(56),
                shadowColor: const Color(0xFFFF5252).withOpacity(0.4),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Manrope',
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.04)
                  : const Color(0xFFFFF5F5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : const Color(0xFFFFE3E3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Color(0xFFFF5252),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tip: Place your fingertip fully over the rear camera lens and flash.'
                        .tr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? Colors.grey.shade300
                          : const Color(0xFF8C2626),
                      height: 1.4,
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// AlloConnect's heart-rate "Start": measures live on a connected AlloWear,
/// or with the phone camera when none is connected. [onDone] runs after a
/// reading is saved or the band has synced.
Future<void> showHeartRateMeasureSheet(
  BuildContext context, {
  VoidCallback? onDone,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: true,
    builder: (_) => HeartRateAnalysisBottomSheet(
      userId: HealthVitalsController.instance.userId,
      onComplete: (_) => onDone?.call(),
    ),
  );
  await HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
  onDone?.call();
}
