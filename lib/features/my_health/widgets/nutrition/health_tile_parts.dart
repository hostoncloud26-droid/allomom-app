import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/config/quick_action_images.dart';

/// Shared building blocks for the My Health day tiles (nutrition, water,
/// drinks, workouts). They reproduce AlloConnect's tile look: a 28-radius card
/// with a hairline border and soft drop shadow, a short accent bar before the
/// title, a small outlined status badge and pill-shaped action buttons.

/// Start and end of the calendar day [date] falls on.
({DateTime start, DateTime end}) dayBounds(DateTime date) => (
  start: DateTime(date.year, date.month, date.day),
  end: DateTime(date.year, date.month, date.day, 23, 59, 59, 999),
);

/// A row from `VitalsSqLiteService.getVitalsHistory` as a vital.
VitalsStreamResponse vitalFromRow(Map<String, dynamic> map) {
  final rawData = map['data'];
  Map<String, dynamic>? parsed;
  if (rawData is String && rawData.isNotEmpty) {
    try {
      final decoded = jsonDecode(rawData);
      if (decoded is Map) parsed = Map<String, dynamic>.from(decoded);
    } catch (_) {}
  } else if (rawData is Map) {
    parsed = Map<String, dynamic>.from(rawData);
  }
  final created = map['createdAt'];
  return VitalsStreamResponse(
    id: map['id']?.toString() ?? '',
    key: (map['vital_key'] ?? map['key'])?.toString() ?? '',
    value: (map['value'] is num) ? (map['value'] as num).toDouble() : 0.0,
    unit: map['unit']?.toString() ?? '',
    createdAt: created is DateTime
        ? created
        : (DateTime.tryParse(created?.toString() ?? '') ?? DateTime.now()),
    data: parsed,
  );
}

/// Strong text colour used on the tiles.
Color tileTextColor(BuildContext context) =>
    context.palette.isDark ? Colors.white : Colors.black87;

/// Hairline border colour used on the tiles.
Color tileBorderColor(BuildContext context) => context.palette.isDark
    ? Colors.white.withValues(alpha: 0.08)
    : Colors.black.withValues(alpha: 0.06);

/// The card every tile sits in.
class HealthTileCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const HealthTileCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    return Container(
      decoration: BoxDecoration(
        color: context.palette.card,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: tileBorderColor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Accent bar + title, with an optional trailing widget pushed to the end.
class HealthTileHeader extends StatelessWidget {
  final String title;
  final Color accent;
  final bool muted;
  final List<Widget> trailing;

  /// Quick Actions illustration shown in place of the accent bar.
  final String? image;

  const HealthTileHeader({
    super.key,
    required this.title,
    required this.accent,
    this.muted = false,
    this.image,
    this.trailing = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (image != null)
          QuickActionImage(image!, size: 30)
        else
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: muted ? accent.withValues(alpha: 0.3) : accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tileTextColor(context),
              letterSpacing: -0.2,
            ),
          ),
        ),
        if (trailing.isNotEmpty) ...[const Spacer(), ...trailing],
      ],
    );
  }
}

/// Small outlined uppercase badge ("TRACKED", "2 HAD").
class HealthTileBadge extends StatelessWidget {
  final String text;
  final Color color;
  final double fontSize;

  const HealthTileBadge({
    super.key,
    required this.text,
    required this.color,
    this.fontSize = 9,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// Pill action button. [filled] is the empty-state "Log" look (solid accent,
/// white text); otherwise it is the tracked-state tinted look.
class HealthTilePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  const HealthTilePill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: fg),
            SizedBox(width: filled ? 4 : 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined quick-action chip that fills its share of a row ("Tea", "+1 Glass").
class HealthTileQuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double verticalPadding;
  final double fontSize;

  const HealthTileQuickAction({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.verticalPadding = 12,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: fontSize + 3),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Gives a tile AlloConnect's small press-down bounce and a tap target.
class HealthTilePressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const HealthTilePressable({super.key, required this.child, this.onTap});

  @override
  State<HealthTilePressable> createState() => _HealthTilePressableState();
}

class _HealthTilePressableState extends State<HealthTilePressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 1.0,
    end: 0.98,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      if (mounted) _controller.reverse();
    });
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTap: widget.onTap == null ? null : _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Big number with a unit trailing it on the baseline.
class HealthTileBigValue extends StatelessWidget {
  final String value;
  final String unit;
  final double unitSize;
  final double unitAlpha;

  const HealthTileBigValue({
    super.key,
    required this.value,
    required this.unit,
    this.unitSize = 15,
    this.unitAlpha = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = tileTextColor(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 38,
            fontWeight: FontWeight.w900,
            color: textColor,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            unit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: unitSize,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: unitAlpha),
            ),
          ),
        ),
      ],
    );
  }
}

/// Empty-state copy: bold call to action over a muted hint.
class HealthTileEmptyCopy extends StatelessWidget {
  final String title;
  final String hint;

  const HealthTileEmptyCopy({
    super.key,
    required this.title,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = tileTextColor(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          hint,
          style: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Allomom logs workouts (`workout`, `exercise`) in minutes, not kcal. Gentle
/// prenatal movement burns roughly this much per minute, which is what the
/// tiles use when they need a kcal figure.
const double kWorkoutKcalPerMinute = 4.0;
