import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/features/blood_oxygen/views/blood_oxygen_card.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class BloodOxygenAnalysisBottomSheet extends StatefulWidget {
  final String userId;

  const BloodOxygenAnalysisBottomSheet({
    super.key,
    required this.userId,
  });

  @override
  State<BloodOxygenAnalysisBottomSheet> createState() =>
      _BloodOxygenAnalysisBottomSheetState();
}

class _BloodOxygenAnalysisBottomSheetState
    extends State<BloodOxygenAnalysisBottomSheet> {
  late final HealthVitalsController _vitalsController;
  late final AllowearController _deviceController;
  late final AllowearMeasurement _allowearSpO2Controller;
  late final AllowearController _healthSyncController;

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
        
    _allowearSpO2Controller = allowear.spo2;
        
    _healthSyncController = allowear;

    _syncCompletionWorker =
        ever(_healthSyncController.isSyncing, (bool syncing) {
      if (!mounted || !_awaitingSyncCompletion || syncing) {
        return;
      }
      _handleSyncFinished();
    });

    // Auto-sync worker: trigger sync when Allowear measurement finishes
    ever(_allowearSpO2Controller.isMonitoring, (bool monitoring) {
      if (!mounted) return;
      final status = _allowearSpO2Controller.status.value;
      if (!monitoring && status == 'Done' && !_autoSyncTriggered && !_awaitingSyncCompletion) {
        _autoSyncTriggered = true;
        _syncAllowearHealthData();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startAllowearAnalysisIfNeeded(restart: false);
    });
  }

  @override
  void dispose() {
    _syncCompletionWorker?.dispose();
    if (_startedAllowearAnalysis && _allowearSpO2Controller.isMonitoring.value) {
      _allowearSpO2Controller.stop();
    }
    super.dispose();
  }

  Future<void> _startAllowearAnalysisIfNeeded({required bool restart}) async {
    final connectedDevice = _deviceController.connectedDevice.value;
    if (connectedDevice == null || (_startedAllowearAnalysis && !restart)) {
      return;
    }

    _startedAllowearAnalysis = true;
    await _allowearSpO2Controller.start();
  }

  Future<void> _syncAllowearHealthData() async {
    if (_healthSyncController.isSyncing.value || _awaitingSyncCompletion) {
      return;
    }

    if (_allowearSpO2Controller.isMonitoring.value) {
      await _allowearSpO2Controller.stop();
    }

    _awaitingSyncCompletion = true;
    await _healthSyncController.startSync();
  }

  Future<void> _handleSyncFinished() async {
    _awaitingSyncCompletion = false;
    await _vitalsController.fetchLatestVitals();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      final connectedDevice = _deviceController.connectedDevice.value;
      final isConnected = connectedDevice != null;

      if (isConnected && !_startedAllowearAnalysis) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAllowearAnalysisIfNeeded(restart: false);
        });
      }

      return AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.only(top: 16),
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
                            ? Colors.white.withOpacity(0.16)
                            : Colors.black.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  if (isConnected)
                    _buildAllowearPanel(context)
                  else
                    _buildNoDevicePanel(context),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildAllowearPanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BloodOxygenCard(
          margin: EdgeInsets.zero,
          showShadow: false,
          showBorder: false,
        ),
        const SizedBox(height: 16),
        Obx(() {
          final isSyncing = _healthSyncController.isSyncing.value;
          final syncStatus = _healthSyncController.syncStatus.value;
          final syncProgress = _healthSyncController.syncProgress.value;

          if (!isSyncing && !_awaitingSyncCompletion) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF0FDF4),
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
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B66D)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          syncStatus,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white70 : const Color(0xFF103B2A),
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
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF00B66D)),
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

  Widget _buildNoDevicePanel(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : Colors.blue.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.bluetooth_searching_rounded,
              size: 64,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
             'Allowear Required',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              fontFamily: 'Manrope',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Blood Oxygen monitoring requires clinical-grade precision from your Allowear device. Please ensure your device is connected.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.white60 : Colors.black54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? Colors.blue.shade700 : Colors.blue.shade600,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Connect Device',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// AlloConnect's SpO₂ "Start": measures live on the connected AlloWear.
Future<void> showBloodOxygenMeasureSheet(
  BuildContext context, {
  VoidCallback? onDone,
}) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: true,
    builder: (_) => BloodOxygenAnalysisBottomSheet(
      userId: HealthVitalsController.instance.userId,
    ),
  );
  await HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
  onDone?.call();
}
