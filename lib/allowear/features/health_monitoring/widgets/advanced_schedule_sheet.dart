import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/features/health_monitoring/widgets/interval_picker.dart';

/// Edits a vital's full automatic schedule: mode (off, interval or always on),
/// interval, daily time window and weekdays — showing only the parts the
/// device supports.
///
/// Resolves to the edited schedule, or null when dismissed.
class AdvancedScheduleSheet extends StatefulWidget {
  const AdvancedScheduleSheet({
    super.key,
    required this.type,
    required this.initial,
    required this.capabilities,
    required this.accentColor,
  });

  final VitalType type;
  final AutoVitalConfig initial;
  final DeviceCapabilities capabilities;
  final Color accentColor;

  static Future<AutoVitalConfig?> show({
    required VitalType type,
    required AutoVitalConfig initial,
    required DeviceCapabilities capabilities,
    required Color accentColor,
  }) =>
      Get.bottomSheet<AutoVitalConfig>(
        AdvancedScheduleSheet(
          type: type,
          initial: initial,
          capabilities: capabilities,
          accentColor: accentColor,
        ),
        isScrollControlled: true,
      );

  @override
  State<AdvancedScheduleSheet> createState() => _AdvancedScheduleSheetState();
}

class _AdvancedScheduleSheetState extends State<AdvancedScheduleSheet> {
  static const List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  late AutoVitalConfig _draft = widget.initial;

  DeviceCapabilities get _caps => widget.capabilities;
  Color get _accent => widget.accentColor;

  void _update(AutoVitalConfig next) => setState(() => _draft = next);

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start
          ? TimeOfDay(hour: _draft.startHour, minute: _draft.startMinute)
          : TimeOfDay(hour: _draft.endHour, minute: _draft.endMinute),
      helpText: start ? 'Window opens' : 'Window closes',
    );
    if (picked == null) return;
    _update(start
        ? _draft.copyWith(startHour: picked.hour, startMinute: picked.minute)
        : _draft.copyWith(endHour: picked.hour, endMinute: picked.minute));
  }

  void _toggleDay(int index) {
    final days = List<bool>.of(_draft.weekdays);
    days[index] = !days[index];
    _update(_draft.copyWith(weekdays: days));
  }

  static String _time(int hour, int minute) =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Black800;
    final mutedColor = isDark ? Colors.white54 : Colors.black54;
    final measuring = _draft.enabled;
    final fixedInterval = _caps.fixedAutoIntervals[widget.type];
    final noDays = measuring && _draft.weekdays.every((day) => !day);

    Widget label(String text) => Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        );

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${widget.type.label} Schedule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose how and when your device measures automatically',
              style: TextStyle(fontSize: 13, color: mutedColor),
            ),
            const SizedBox(height: 24),

            // ── Mode ──────────────────────────────────────────────────────
            label('Mode'),
            const SizedBox(height: 10),
            Row(
              children: [
                _modeOption(AutoMeasureMode.off, 'Off', Icons.block_rounded,
                    isDark),
                const SizedBox(width: 8),
                _modeOption(AutoMeasureMode.interval, 'Interval',
                    Icons.timer_outlined, isDark),
                if (_caps.supportsContinuous(widget.type)) ...[
                  const SizedBox(width: 8),
                  _modeOption(AutoMeasureMode.continuous, 'Always on',
                      Icons.all_inclusive_rounded, isDark),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              switch (_draft.mode) {
                AutoMeasureMode.off => 'No automatic measurement.',
                AutoMeasureMode.interval =>
                  'One measurement every interval inside the time window.',
                AutoMeasureMode.continuous =>
                  'Measures continuously inside the time window. Uses more battery.',
              },
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),

            // ── Interval ──────────────────────────────────────────────────
            if (_draft.mode == AutoMeasureMode.interval) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  label('Interval'),
                  const Spacer(),
                  IntervalPicker(
                    minutes: _draft.intervalMinutes,
                    accentColor: _accent,
                    fixedMinutes: fixedInterval,
                    deviceChosen: fixedInterval == null &&
                        !_caps.supportsCustomInterval(widget.type),
                    onChanged: (minutes) =>
                        _update(_draft.copyWith(intervalMinutes: minutes)),
                  ),
                ],
              ),
            ],

            // ── Time window ───────────────────────────────────────────────
            if (measuring && _caps.supportsAutoTimeWindow) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  label('Time window'),
                  const Spacer(),
                  TextButton(
                    onPressed: _draft.coversWholeDay
                        ? null
                        : () => _update(_draft.copyWith(
                              startHour: 0,
                              startMinute: 0,
                              endHour: 23,
                              endMinute: 59,
                            )),
                    child: Text('All day',
                        style: TextStyle(
                            color: _draft.coversWholeDay ? null : _accent)),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _timeButton(
                      'From',
                      _time(_draft.startHour, _draft.startMinute),
                      () => _pickTime(start: true),
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timeButton(
                      'To',
                      _time(_draft.endHour, _draft.endMinute),
                      () => _pickTime(start: false),
                      isDark,
                    ),
                  ),
                ],
              ),
            ],

            // ── Weekdays ──────────────────────────────────────────────────
            if (measuring && _caps.supportsAutoWeekdays) ...[
              const SizedBox(height: 22),
              Row(
                children: [
                  label('Days'),
                  const Spacer(),
                  TextButton(
                    onPressed: _draft.weekdays.every((day) => day)
                        ? null
                        : () => _update(_draft.copyWith(
                              weekdays: List<bool>.filled(7, true),
                            )),
                    child: Text('Every day',
                        style: TextStyle(
                            color: _draft.weekdays.every((d) => d)
                                ? null
                                : _accent)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < 7; i++) _dayChip(i, isDark),
                ],
              ),
              if (noDays)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Pick at least one day, or switch the mode off.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.red.shade300),
                  ),
                ),
            ],

            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: noDays ? null : () => Get.back(result: _draft),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _accent.withOpacity(0.3),
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'Save to Device',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeOption(
      AutoMeasureMode mode, String text, IconData icon, bool isDark) {
    final selected = _draft.mode == mode;
    return Expanded(
      child: InkWell(
        onTap: () => _update(_draft.copyWith(mode: mode)),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? _accent.withOpacity(0.15)
                : (isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.black.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? _accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? _accent
                      : (isDark ? Colors.white54 : Colors.black45)),
              const SizedBox(height: 4),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? _accent
                      : (isDark ? Colors.white70 : Black700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeButton(
      String caption, String time, VoidCallback onTap, bool isDark) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _accent.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: _accent),
            const SizedBox(width: 8),
            Text(
              caption,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
            const Spacer(),
            Text(
              time,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Black800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dayChip(int index, bool isDark) {
    final selected = _draft.weekdays[index];
    return InkWell(
      onTap: () => _toggleDay(index),
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? _accent
              : (isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05)),
        ),
        child: Text(
          _dayLabels[index],
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }
}
