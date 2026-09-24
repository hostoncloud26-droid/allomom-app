import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/cycle_tracker/cycle_theme.dart';

/// A labelled −/+ counter, used for cycle length and period length.
///
/// A stepper rather than a text field because both values are small integers
/// in a known range, and a mother nudging "28" to "30" should not have to open
/// a keyboard.
class CycleStepperRow extends StatelessWidget {
  const CycleStepperRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.suffix = 'days',
  });

  final String title;
  final String subtitle;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: CycleColors.inkOn(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  color: CycleColors.mutedOn(context),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _RoundStepButton(
          icon: Icons.remove_rounded,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        SizedBox(
          width: 64,
          child: Column(
            children: [
              Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: CycleColors.accent,
                ),
              ),
              Text(
                suffix,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: CycleColors.mutedOn(context),
                ),
              ),
            ],
          ),
        ),
        _RoundStepButton(
          icon: Icons.add_rounded,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _RoundStepButton extends StatelessWidget {
  const _RoundStepButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: enabled
          ? CycleColors.accent.withValues(alpha: 0.12)
          : context.palette.pick(
              const Color(0xFFF1F5F9),
              context.palette.surface,
            ),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: enabled ? CycleColors.accent : context.palette.pick(
                    const Color(0xFFCBD5E1),
                    context.palette.textMuted,
                  ),
          ),
        ),
      ),
    );
  }
}
