import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/services/cycle_predictor.dart';

/// Colours shared by the cycle card, the tracker screen and the setup sheet,
/// so a phase looks the same everywhere it is named.
class CycleColors {
  const CycleColors._();

  static const accent = Color(0xFFFF3B5C);
  static const accentSoft = Color(0xFFFFF0F4);
  static const ink = Color(0xFF1E2024);
  static const muted = Color(0xFF6B7280);
  static const hairline = Color(0xFFF0F1F5);

  static const fertile = Color(0xFF8B5CF6);
  static const fertileSoft = Color(0xFFF3E8FF);
  static const follicular = Color(0xFF10B981);
  static const follicularSoft = Color(0xFFECFDF5);
  static const luteal = Color(0xFF3898EC);
  static const lutealSoft = Color(0xFFEDF6FF);
  static const overdue = Color(0xFFF59E0B);
  static const overdueSoft = Color(0xFFFFF7ED);

  static Color of(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => accent,
    CyclePhase.follicular => follicular,
    CyclePhase.fertile => fertile,
    CyclePhase.luteal => luteal,
    CyclePhase.late => overdue,
  };

  static Color softOf(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => accentSoft,
    CyclePhase.follicular => follicularSoft,
    CyclePhase.fertile => fertileSoft,
    CyclePhase.luteal => lutealSoft,
    CyclePhase.late => overdueSoft,
  };

  // Theme-aware versions of the neutrals and washes above: identical to the
  // constants in light mode, palette colours in dark mode.
  static Color inkOn(BuildContext context) =>
      context.palette.pick(ink, context.palette.textPrimary);
  static Color mutedOn(BuildContext context) =>
      context.palette.pick(muted, context.palette.textSecondary);
  static Color hairlineOn(BuildContext context) =>
      context.palette.pick(hairline, context.palette.divider);

  /// [soft] in light mode, a low-alpha wash of [color] in dark mode.
  static Color softOn(BuildContext context, Color color, Color soft) =>
      context.palette.tint(color, soft);

  static Color phaseSoftOn(BuildContext context, CyclePhase phase) =>
      context.palette.tint(of(phase), softOf(phase));

  static IconData iconOf(CyclePhase phase) => switch (phase) {
    CyclePhase.menstrual => Icons.water_drop_rounded,
    CyclePhase.follicular => Icons.eco_rounded,
    CyclePhase.fertile => Icons.favorite_rounded,
    CyclePhase.luteal => Icons.nightlight_round,
    CyclePhase.late => Icons.schedule_rounded,
  };
}
