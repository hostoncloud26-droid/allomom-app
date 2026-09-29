import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';

/// This week's summary: the same words the baby speaks first on home, from
/// the week's AlloBot flow. Takes no room until the catalogue has the week.
class WeeklySummaryCard extends StatefulWidget {
  const WeeklySummaryCard({super.key, required this.week, this.label});

  /// The sheet week: 1–40 for a pregnancy, 41–142 for a baby.
  final int week;

  /// The corner label; "Week [week]" when not given.
  final String? label;

  @override
  State<WeeklySummaryCard> createState() => _WeeklySummaryCardState();
}

class _WeeklySummaryCardState extends State<WeeklySummaryCard> {
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeeklySummaryCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.week != widget.week) _load();
  }

  Future<void> _load() async {
    final message = await WeeklyBabyTalk.message(widget.week);
    if (!mounted) return;
    setState(() => _message = message);
  }

  @override
  Widget build(BuildContext context) {
    final message = _message;
    if (message == null) return const SizedBox.shrink();

    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: p.pick(const Color(0xFFF0F1F5), p.border),
            width: 1.1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: Color(0xFFFF3B5C),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Weekly Summary',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                    ),
                  ),
                ),
                Text(
                  widget.label ?? 'Week ${widget.week}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: p.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.5,
                color: p.pick(const Color(0xFF6B707B), p.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
