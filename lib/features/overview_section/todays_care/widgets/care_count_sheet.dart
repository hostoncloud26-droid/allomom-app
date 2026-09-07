import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bottom sheet that asks "how many?" — glasses of water, cups of coffee or
/// portions of a snack. Returns the number the user chose to log, or null if
/// they dismissed it.
///
/// Everything it returns is an **increment** (what was just consumed), never a
/// running total, because every reader of these vitals sums the day's rows.
class CareCountSheet extends StatefulWidget {
  const CareCountSheet({
    super.key,
    required this.title,
    required this.unitLabel,
    required this.unitLabelSingular,
    required this.icon,
    required this.color,
    this.loggedToday = 0,
    this.target,
    this.presets = const [1, 2, 3],
    this.maxPerLog = 12,
    this.subtitle,
  });

  final String title;

  /// Plural unit, e.g. "glasses".
  final String unitLabel;

  /// Singular unit, e.g. "glass".
  final String unitLabelSingular;

  final IconData icon;
  final Color color;

  /// Already logged today, shown as progress.
  final int loggedToday;

  /// Daily goal, when there is one.
  final int? target;

  /// Quick-tap amounts.
  final List<int> presets;

  /// Upper bound for a single log.
  final int maxPerLog;

  final String? subtitle;

  /// Shows the sheet and resolves to the amount to log, or null on dismiss.
  static Future<int?> show(
    BuildContext context, {
    required String title,
    required String unitLabel,
    required String unitLabelSingular,
    required IconData icon,
    required Color color,
    int loggedToday = 0,
    int? target,
    List<int> presets = const [1, 2, 3],
    int maxPerLog = 12,
    String? subtitle,
  }) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CareCountSheet(
        title: title,
        unitLabel: unitLabel,
        unitLabelSingular: unitLabelSingular,
        icon: icon,
        color: color,
        loggedToday: loggedToday,
        target: target,
        presets: presets,
        maxPerLog: maxPerLog,
        subtitle: subtitle,
      ),
    );
  }

  @override
  State<CareCountSheet> createState() => _CareCountSheetState();
}

class _CareCountSheetState extends State<CareCountSheet> {
  late int _count = widget.presets.isNotEmpty ? widget.presets.first : 1;

  String _unitFor(int count) =>
      count == 1 ? widget.unitLabelSingular : widget.unitLabel;

  void _setCount(int next) {
    final clamped = next.clamp(1, widget.maxPerLog);
    if (clamped == _count) return;
    HapticFeedback.selectionClick();
    setState(() => _count = clamped);
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final total = widget.loggedToday + _count;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // ─── STEPPER ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StepperButton(
                icon: Icons.remove_rounded,
                enabled: _count > 1,
                color: widget.color,
                onTap: () => _setCount(_count - 1),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$_count',
                      style: GoogleFonts.manrope(
                        fontSize: 44,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: widget.color,
                      ),
                    ),
                    Text(
                      _unitFor(_count),
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              _StepperButton(
                icon: Icons.add_rounded,
                enabled: _count < widget.maxPerLog,
                color: widget.color,
                onTap: () => _setCount(_count + 1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── PRESETS ───
          if (widget.presets.isNotEmpty)
            Row(
              children: [
                for (final preset in widget.presets) ...[
                  Expanded(
                    child: _PresetChip(
                      label: '$preset ${_unitFor(preset)}',
                      selected: _count == preset,
                      color: widget.color,
                      onTap: () => _setCount(preset),
                    ),
                  ),
                  if (preset != widget.presets.last) const SizedBox(width: 8),
                ],
              ],
            ),

          if (target != null) ...[
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (total / target).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: const Color(0xFFF1F5F9),
                valueColor: AlwaysStoppedAnimation<Color>(widget.color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              total >= target
                  ? "That hits today's goal of $target ${_unitFor(target)} 🎉"
                  : 'Today: ${widget.loggedToday} logged · $total of $target '
                        '${_unitFor(target)} after this',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, _count),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Log $_count ${_unitFor(_count)}',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.icon,
    required this.enabled,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled ? color.withValues(alpha: 0.12) : const Color(0xFFF1F5F9),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(
            icon,
            size: 24,
            color: enabled ? color : const Color(0xFFCBD5E1),
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : const Color(0xFFE2E8F0),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? color : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
