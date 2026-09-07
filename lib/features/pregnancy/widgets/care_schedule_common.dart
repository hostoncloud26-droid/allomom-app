import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';

/// Shared look and helpers for the three care schedule screens (ANC visits,
/// vaccinations, lab reports), all of which read rows scheduled locally when
/// the pregnancy was registered.

/// How a scheduled item is presented, derived from its status and due date.
enum CareStatus {
  completed,
  overdue,
  dueSoon,
  scheduled,
  missed;

  /// Resolves the display status for a row.
  ///
  /// `done` and `missed` come straight from the stored status; a pending row is
  /// overdue once its date has passed and "due soon" inside the next week.
  static CareStatus resolve({
    required String status,
    required DateTime? date,
    DateTime? now,
  }) {
    final normalized = status.toLowerCase().trim();
    if (normalized == 'done' || normalized == 'completed') {
      return CareStatus.completed;
    }
    if (normalized == 'missed') return CareStatus.missed;

    if (date == null) return CareStatus.scheduled;
    final today = now ?? DateTime.now();
    final startOfToday = DateTime(today.year, today.month, today.day);
    final due = DateTime(date.year, date.month, date.day);

    if (due.isBefore(startOfToday)) return CareStatus.overdue;
    if (due.difference(startOfToday).inDays <= 7) return CareStatus.dueSoon;
    return CareStatus.scheduled;
  }

  String get label => switch (this) {
    CareStatus.completed => 'Completed',
    CareStatus.overdue => 'Overdue',
    CareStatus.dueSoon => 'Due soon',
    CareStatus.scheduled => 'Scheduled',
    CareStatus.missed => 'Missed',
  };

  Color get color => switch (this) {
    CareStatus.completed => const Color(0xFF10B981),
    CareStatus.overdue => const Color(0xFFEF4444),
    CareStatus.dueSoon => const Color(0xFFFF3B5C),
    CareStatus.scheduled => const Color(0xFF3898EC),
    CareStatus.missed => const Color(0xFF8E95A5),
  };

  Color get background => switch (this) {
    CareStatus.completed => const Color(0xFFD1FAE5),
    CareStatus.overdue => const Color(0xFFFEE2E2),
    CareStatus.dueSoon => const Color(0xFFFFF0F4),
    CareStatus.scheduled => const Color(0xFFEDF6FF),
    CareStatus.missed => const Color(0xFFF6F7FA),
  };

  bool get isDone => this == CareStatus.completed;

  /// Highlighted with a heavier border — the thing to act on next.
  bool get needsAttention =>
      this == CareStatus.overdue || this == CareStatus.dueSoon;
}

/// Pill showing a [CareStatus].
class CareStatusChip extends StatelessWidget {
  const CareStatusChip({super.key, required this.status});

  final CareStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status.label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
      ),
    );
  }
}

/// Shown when the mother has no active pregnancy, so nothing was scheduled.
class CareScheduleEmpty extends StatelessWidget {
  const CareScheduleEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRegistered,
  });

  final IconData icon;
  final String title;
  final String message;

  /// Called after the registration flow reports success, so the caller can
  /// reload the freshly scheduled rows.
  final VoidCallback? onRegistered;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF0F4),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 38, color: const Color(0xFFFF3B5C)),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xFF6B707B),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () async {
                final created = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => const PregnancyConfirmationPage(),
                  ),
                );
                if (created == true) onRegistered?.call();
              },
              icon: const Icon(Icons.favorite_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B5C),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              label: Text(
                'Register pregnancy',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Segmented filter used by all three schedules.
class CareFilterTabs extends StatelessWidget {
  const CareFilterTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onSelected,
  });

  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < labels.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected == i ? const Color(0xFFFF3B5C) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected == i
                        ? const Color(0xFFFF3B5C)
                        : const Color(0xFFE5E7EB),
                    width: 1.2,
                  ),
                ),
                child: Text(
                  labels[i],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: selected == i
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: selected == i
                        ? Colors.white
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),
          if (i != labels.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Progress header: "4 of 20 done".
class CareProgressHeader extends StatelessWidget {
  const CareProgressHeader({
    super.key,
    required this.done,
    required this.total,
    required this.label,
  });

  final int done;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : done / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ),
              Text(
                '$done of $total done',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFF3B5C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: const Color(0xFFF0F2F5),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFF3B5C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
