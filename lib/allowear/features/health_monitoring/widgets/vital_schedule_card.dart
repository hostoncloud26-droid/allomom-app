import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/features/health_monitoring/widgets/advanced_schedule_sheet.dart';
import 'package:allomom/allowear/features/health_monitoring/widgets/interval_picker.dart';

/// Look of each vital's schedule card.
class VitalScheduleStyle {
  const VitalScheduleStyle(this.label, this.icon, this.color);

  final String label;
  final IconData icon;
  final Color color;

  static VitalScheduleStyle of(VitalType type) => switch (type) {
        VitalType.heartRate => const VitalScheduleStyle(
            'Heart Rate', Icons.favorite_rounded, Color(0xFFE74C3C)),
        VitalType.spo2 => const VitalScheduleStyle(
            'Blood Oxygen', Icons.water_drop_rounded, Color(0xFF3B82F6)),
        VitalType.hrv => const VitalScheduleStyle(
            'HRV', Icons.monitor_heart_rounded, Color(0xFF8B5CF6)),
        VitalType.stress => const VitalScheduleStyle(
            'Stress', Icons.psychology_alt_rounded, Color(0xFFF39C12)),
        VitalType.temperature => const VitalScheduleStyle(
            'Skin Temperature', Icons.thermostat_rounded, Color(0xFFFF8A3D)),
      };
}

/// Automatic measurement schedule of one vital.
///
/// Every device gets the basic controls — on/off and an interval, all day,
/// every day. Devices that can do more (Allowear Fit) also get the Advanced
/// sheet: always-on mode, a time window and weekdays.
class VitalScheduleCard extends StatelessWidget {
  const VitalScheduleCard({super.key, required this.type});

  final VitalType type;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = VitalScheduleStyle.of(type);
    final controller = allowear;

    return Obx(() {
      final caps = controller.capabilities;
      if (caps == null) return const SizedBox.shrink();

      final connected = controller.connectedDevice.value != null;
      final config = controller.autoConfigs[type];
      final current = config ?? const AutoVitalConfig.off();
      final saving = controller.savingSchedules.contains(type);
      final canWrite = connected && !saving;
      final fixed = caps.fixedAutoIntervals[type];
      final advanced = caps.supportsAdvancedAutoConfig(type);
      final accent = style.color;

      final subtitle = saving
          ? 'Saving to device…'
          : !connected
              ? 'Connect your device to change'
              : config == null
                  ? 'Not read from the device yet'
                  : describe(current);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accent.withOpacity(isDark ? 0.18 : 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header: icon, name, summary, switch ─────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(current.enabled ? 0.18 : 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    style.icon,
                    color:
                        current.enabled ? accent : accent.withOpacity(0.4),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        style.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Black800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: current.enabled && connected && !saving
                              ? accent.withOpacity(0.9)
                              : (isDark ? Colors.white38 : Colors.black38),
                        ),
                      ),
                    ],
                  ),
                ),
                if (saving)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: accent),
                    ),
                  )
                else
                  Transform.scale(
                    scale: 0.85,
                    child: Switch.adaptive(
                      value: current.enabled,
                      onChanged: canWrite
                          ? (value) => controller.setBasicSchedule(type,
                              enabled: value,
                              intervalMinutes: current.intervalMinutes)
                          : null,
                      activeColor: Colors.white,
                      activeTrackColor: accent,
                      inactiveThumbColor:
                          isDark ? Colors.white38 : Colors.white,
                      inactiveTrackColor: isDark
                          ? Colors.white12
                          : Colors.black.withOpacity(0.12),
                      trackOutlineColor:
                          WidgetStateProperty.all(Colors.transparent),
                    ),
                  ),
              ],
            ),

            // ── Interval + advanced ─────────────────────────────────────
            const SizedBox(height: 12),
            Row(
              children: [
                IntervalPicker(
                  minutes: current.intervalMinutes,
                  accentColor: accent,
                  fixedMinutes: fixed,
                  deviceChosen:
                      fixed == null && !caps.supportsCustomInterval(type),
                  onChanged: canWrite
                      ? (minutes) => controller.setBasicSchedule(type,
                          enabled: true, intervalMinutes: minutes)
                      : null,
                ),
                const Spacer(),
                if (advanced)
                  TextButton.icon(
                    onPressed: canWrite
                        ? () => _openAdvanced(controller, caps, current)
                        : null,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 16),
                    label: const Text(
                      'Advanced',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),

            // The basic controls write an all-day, every-day interval
            // schedule, so they replace anything set in the Advanced sheet.
            if (current.isAdvanced && config != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 13,
                        color: isDark ? Colors.white38 : Colors.black38),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Advanced schedule active. The switch and interval reset it to all day, every day.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Future<void> _openAdvanced(AllowearController controller,
      DeviceCapabilities caps, AutoVitalConfig current) async {
    final edited = await AdvancedScheduleSheet.show(
      type: type,
      initial: current,
      capabilities: caps,
      accentColor: VitalScheduleStyle.of(type).color,
    );
    if (edited == null) return;
    await controller.setAdvancedSchedule(type, edited);
  }

  /// One line summary, e.g. "Every 30 min · 08:00–22:00 · weekdays".
  static String describe(AutoVitalConfig config) {
    if (!config.enabled) return 'Monitoring off';

    return [
      config.mode == AutoMeasureMode.continuous
          ? 'Always on'
          : 'Every ${IntervalPicker.label(config.intervalMinutes)}',
      config.coversWholeDay
          ? 'all day'
          : '${_time(config.startHour, config.startMinute)}–'
              '${_time(config.endHour, config.endMinute)}',
      _days(config.weekdays),
    ].join(' · ');
  }

  static String _days(List<bool> weekdays) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekdays.every((day) => day)) return 'every day';
    if (weekdays.take(5).every((day) => day) && !weekdays[5] && !weekdays[6]) {
      return 'weekdays';
    }
    if (!weekdays.take(5).any((day) => day) && weekdays[5] && weekdays[6]) {
      return 'weekends';
    }
    return [
      for (var i = 0; i < 7; i++)
        if (weekdays[i]) names[i],
    ].join(', ');
  }

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
