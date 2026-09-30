import 'package:flutter/material.dart';
import 'package:allomom/allowear/allowear_colors.dart';

/// Minutes between automatic measurements: common presets plus "Custom…".
///
/// When [fixedMinutes] is set the device ignores whatever is asked for, so the
/// picker shows that value locked. [deviceChosen] is the same for a device that
/// picks its own interval without saying what it is.
class IntervalPicker extends StatelessWidget {
  const IntervalPicker({
    super.key,
    required this.minutes,
    required this.accentColor,
    required this.onChanged,
    this.fixedMinutes,
    this.deviceChosen = false,
  });

  final int minutes;
  final Color accentColor;

  /// Called with the chosen interval, or null to disable the picker.
  final ValueChanged<int>? onChanged;

  final int? fixedMinutes;
  final bool deviceChosen;

  static const List<int> presets = [5, 10, 15, 30, 60, 120];
  static const int maxMinutes = 24 * 60;
  static const int _custom = -1;

  static String label(int minutes) {
    if (minutes >= 60 && minutes % 60 == 0) {
      final hours = minutes ~/ 60;
      return '$hours hr${hours == 1 ? '' : 's'}';
    }
    return '$minutes min';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fixed = fixedMinutes;

    if (fixed != null || deviceChosen) {
      return Tooltip(
        message: fixed != null
            ? 'This device always measures every $fixed min'
            : 'This device picks its own interval',
        child: _pill(
          isDark,
          icon: Icons.lock_outline_rounded,
          text: fixed != null ? '${label(fixed)} · fixed' : 'Set by device',
          enabled: false,
        ),
      );
    }

    final enabled = onChanged != null;
    return PopupMenuButton<int>(
      enabled: enabled,
      tooltip: 'Measurement interval',
      initialValue: presets.contains(minutes) ? minutes : null,
      color: isDark ? const Color(0xFF2A2A3C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      onSelected: (value) async {
        if (value != _custom) {
          onChanged?.call(value);
          return;
        }
        final entered = await _askForMinutes(context, minutes);
        if (entered != null) onChanged?.call(entered);
      },
      itemBuilder: (_) => [
        for (final preset in presets)
          PopupMenuItem(
            value: preset,
            child: Text(
              'Every ${label(preset)}',
              style: TextStyle(
                fontWeight:
                    preset == minutes ? FontWeight.w800 : FontWeight.w500,
                color: preset == minutes
                    ? accentColor
                    : (isDark ? Colors.white : Black800),
              ),
            ),
          ),
        PopupMenuItem(
          value: _custom,
          child: Text(
            presets.contains(minutes)
                ? 'Custom…'
                : 'Custom… (${label(minutes)})',
            style: TextStyle(color: isDark ? Colors.white70 : Black700),
          ),
        ),
      ],
      child: _pill(
        isDark,
        icon: Icons.timer_outlined,
        text: 'Every ${label(minutes)}',
        enabled: enabled,
        trailing: Icons.expand_more_rounded,
      ),
    );
  }

  Widget _pill(
    bool isDark, {
    required IconData icon,
    required String text,
    required bool enabled,
    IconData? trailing,
  }) {
    final color = enabled
        ? accentColor
        : (isDark ? Colors.white38 : Colors.black38);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 2),
            Icon(trailing, size: 16, color: color),
          ],
        ],
      ),
    );
  }

  static Future<int?> _askForMinutes(BuildContext context, int initial) {
    final controller = TextEditingController(text: '$initial');
    final formKey = GlobalKey<FormState>();
    return showDialog<int>(
      context: context,
      builder: (context) {
        void submit() {
          if (formKey.currentState?.validate() ?? false) {
            Navigator.pop(context, int.parse(controller.text.trim()));
          }
        }

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Custom interval'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Minutes between measurements',
                suffixText: 'min',
              ),
              validator: (text) {
                final value = int.tryParse(text?.trim() ?? '');
                if (value == null) return 'Enter a whole number of minutes';
                if (value < 1 || value > maxMinutes) {
                  return 'Between 1 and $maxMinutes minutes';
                }
                return null;
              },
              onFieldSubmitted: (_) => submit(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(onPressed: submit, child: const Text('Use')),
          ],
        );
      },
    ).whenComplete(controller.dispose);
  }
}
