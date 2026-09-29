import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';

const _rust = Color(0xFFA63A24);

/// How far either side of its expected date a milestone counts as "in range".
const _rangeDays = 30;

/// The milestone the baby is in range for right now — not yet reached, with
/// today inside [_rangeDays] of its expected date. The earliest one wins, so
/// an overdue milestone stays in focus until it is ticked off.
BabyMilestone? currentFocusMilestone(
  List<BabyMilestone> milestones, {
  DateTime? now,
}) {
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final inRange =
      milestones.where((m) => !m.achieved && m.expectedDate != null).where((m) {
        final gap = today
            .difference(DateUtils.dateOnly(m.expectedDate!))
            .inDays;
        return gap.abs() <= _rangeDays;
      }).toList()..sort((a, b) => a.expectedDate!.compareTo(b.expectedDate!));
  return inRange.isEmpty ? null : inRange.first;
}

/// "Current focus" under the baby's card: the milestone in range, the days
/// left in its window, and a tick to mark it reached.
class CurrentFocusCard extends StatelessWidget {
  const CurrentFocusCard({
    super.key,
    required this.milestone,
    required this.onReached,
  });

  final BabyMilestone milestone;
  final VoidCallback onReached;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.pick(const Color(0xFF1E2024), p.textPrimary);
    final inkSoft = p.pick(const Color(0xFF4B5563), p.textSecondary);
    final accent = p.pick(_rust, const Color(0xFFF08A6E));

    final today = DateUtils.dateOnly(DateTime.now());
    final expected = DateUtils.dateOnly(milestone.expectedDate!);
    final end = expected.add(const Duration(days: _rangeDays));
    final daysLeft = end.difference(today).inDays.clamp(0, _rangeDays * 2);

    final description = milestone.description.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        gradient: p.isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFE9E4), Colors.white, Color(0xFFF7F2FF)],
                stops: [0, 0.55, 1],
              ),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: p.isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'CURRENT FOCUS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: p.isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        daysLeft == 0
                            ? 'Last day'
                            : '$daysLeft ${daysLeft == 1 ? 'day' : 'days'} left',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  milestone.milestone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.35,
                      color: inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Tooltip(
            message: 'Mark as reached',
            child: Material(
              color: _rust,
              shape: const CircleBorder(),
              elevation: 2,
              shadowColor: _rust.withValues(alpha: 0.4),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: onReached,
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
