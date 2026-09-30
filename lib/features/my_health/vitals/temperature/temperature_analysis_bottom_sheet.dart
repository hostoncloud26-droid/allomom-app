import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

/// Measures skin temperature live on the connected Allowear.
///
/// Starts as soon as it opens, stops on the first reading, and the controller
/// saves that reading as the latest temperature vital.
class TemperatureAnalysisBottomSheet extends StatefulWidget {
  const TemperatureAnalysisBottomSheet({super.key});

  @override
  State<TemperatureAnalysisBottomSheet> createState() =>
      _TemperatureAnalysisBottomSheetState();
}

class _TemperatureAnalysisBottomSheetState
    extends State<TemperatureAnalysisBottomSheet> {
  static const Color _accent = Color(0xFFFF8A3D);

  final AllowearController _device = allowear;
  AllowearMeasurement get _measurement => _device.temperature;

  bool _started = false;

  bool get _canMeasure =>
      _device.connectedDevice.value != null &&
      _device.supportsLive(VitalType.temperature);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    if (_measurement.isMonitoring.value) _measurement.stop();
    super.dispose();
  }

  Future<void> _start() async {
    if (!mounted || !_canMeasure || _measurement.isMonitoring.value) return;
    setState(() => _started = true);
    await _measurement.start();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
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
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.16)
                        : Colors.black.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 20),
                Obx(() => _canMeasure
                    ? _buildMeasurePanel(context, isDark)
                    : _buildUnavailablePanel(context, isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeasurePanel(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : Colors.black87;

    return Obx(() {
      final measuring = _measurement.isMonitoring.value;
      final status = _measurement.status.value;
      final value = _measurement.preciseReading.value;
      final hasValue = value != null && value > 0;
      final finished = _started && !measuring;

      final statusText = measuring
          ? (hasValue ? 'Reading received'.tr : 'Measuring... keep the device on'.tr)
          : finished
              ? (hasValue ? 'Saved to your health data'.tr : 'No reading received. Try again.'.tr)
              : status.tr;

      return Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.thermostat_rounded,
                    color: _accent, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Skin Temperature'.tr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  fontFamily: 'Manrope',
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox.expand(
                  child: CircularProgressIndicator(
                    value: measuring ? _measurement.progress.value : 1.0,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    backgroundColor: _accent.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _accent.withOpacity(hasValue || measuring ? 1 : 0.3)),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      hasValue ? value.toStringAsFixed(1) : '--',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        fontFamily: 'Manrope',
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: textColor.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            statusText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: measuring ? _measurement.stop : _start,
              icon: Icon(measuring
                  ? Icons.stop_rounded
                  : Icons.play_arrow_rounded),
              label: Text(
                measuring
                    ? 'Stop'.tr
                    : (finished ? 'Measure again'.tr : 'Start'.tr),
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: measuring ? const Color(0xFFE74C3C) : _accent,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                elevation: 0,
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildUnavailablePanel(BuildContext context, bool isDark) {
    final connected = _device.connectedDevice.value != null;
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            connected
                ? Icons.thermostat_rounded
                : Icons.bluetooth_searching_rounded,
            size: 56,
            color: _accent,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          connected
              ? 'Not Supported on This Device'.tr
              : 'Allowear Required'.tr,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            fontFamily: 'Manrope',
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          connected
              ? 'Live skin temperature is available on Allowear Fit. Readings your device records on its own still appear after a sync.'
                  .tr
              : 'Connect your Allowear device to measure skin temperature.'.tr,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark ? Colors.white60 : Colors.black54,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        ElevatedButton(
          onPressed: () => Get.back(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            elevation: 0,
          ),
          child: Text('Close'.tr,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      ],
    );
  }
}

/// AlloConnect's temperature "Start": measures skin temperature live on the
/// connected AlloWear; the controller saves the reading.
Future<void> showTemperatureMeasureSheet(
  BuildContext context, {
  VoidCallback? onDone,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    useSafeArea: true,
    builder: (_) => const TemperatureAnalysisBottomSheet(),
  );
  await HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
  onDone?.call();
}
