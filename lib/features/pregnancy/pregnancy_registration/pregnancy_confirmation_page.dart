import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/pregnancy_care_scheduler.dart';

const _accent = Color(0xFFFF3B5C);
const _ink = Color(0xFF1E2024);
const _muted = Color(0xFF6B707B);

/// Registers a pregnancy and books its whole care schedule locally.
///
/// Three steps: the LMP date, which pregnancy months the mother will attend an
/// ANC check-up in, then a review of every ANC visit, vaccine dose and lab test
/// that is about to be created. Confirming writes the pregnancy plus the
/// schedule into SQLite with `synced = 0`.
class PregnancyConfirmationPage extends StatefulWidget {
  const PregnancyConfirmationPage({super.key});

  @override
  State<PregnancyConfirmationPage> createState() =>
      _PregnancyConfirmationPageState();
}

class _PregnancyConfirmationPageState extends State<PregnancyConfirmationPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _shortFmt = DateFormat('dd MMM');

  static const _stepTitles = ['LMP date', 'ANC months', 'Review plan'];

  int _step = 0;
  late DateTime _selectedLmpDate;
  final Set<int> _ancMonths = {...defaultAncMonths};
  bool _includeOptional = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Default to approximately 8 weeks ago
    final now = DateTime.now();
    _selectedLmpDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 56));
  }

  // ─── DERIVED VALUES ─────────────────────────────────────────

  DateTime get _calculatedEdd =>
      _selectedLmpDate.add(const Duration(days: 280));

  int get _calculatedGestationalWeek {
    final days = DateTime.now().difference(_selectedLmpDate).inDays;
    return days >= 0 ? (days ~/ 7) + 1 : 1;
  }

  String get _calculatedTrimester {
    final week = _calculatedGestationalWeek;
    if (week <= 12) return '1st Trimester';
    if (week <= 26) return '2nd Trimester';
    return '3rd Trimester';
  }

  int get _daysRemaining {
    final days = _calculatedEdd.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  PregnancyCarePlanPreview get _preview => PregnancyCareScheduler.preview(
    lmpDate: _selectedLmpDate,
    ancMonths: _ancMonths.toList(),
    includeOptional: _includeOptional,
  );

  List<ScheduledReport> get _dueReports => _includeOptional
      ? reportSchedule
      : reportSchedule.where((r) => r.isRequired).toList();

  // ─── ACTIONS ────────────────────────────────────────────────

  Future<void> _pickLmpDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedLmpDate,
      firstDate: now.subtract(const Duration(days: 280)),
      lastDate: now,
      helpText: 'SELECT FIRST DAY OF LAST PERIOD (LMP)',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _accent,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _ink,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedLmpDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _goToStep(int step) {
    setState(() => _step = step.clamp(0, _stepTitles.length - 1));
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);

    try {
      final session = UserSessionManager.instance;

      // 1. The pregnancy itself, written locally with synced = 0.
      final pregnancyId = await session.saveOrUpdatePregnancy(
        lmpDate: _selectedLmpDate,
        eddDate: _calculatedEdd,
      );

      if (pregnancyId == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _toast(
          'Could not register the pregnancy — no signed-in profile found.',
          isError: true,
        );
        return;
      }

      // 2. The ANC / vaccination / lab-report schedule hanging off it.
      final result = await PregnancyCareScheduler.instance.scheduleFor(
        pregnancyId: pregnancyId,
        userId: session.userId,
        lmpDate: _selectedLmpDate,
        ancMonths: _ancMonths.toList(),
        includeOptional: _includeOptional,
      );

      if (!mounted) return;
      _toast(
        'Journey created — ${result.ancVisits} ANC visits, '
        '${result.vaccinations} vaccinations and ${result.reports} lab tests '
        'scheduled ✨',
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _toast('Failed to create pregnancy: $e', isError: true);
    }
  }

  void _toast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFEF4444) : _accent,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 4 : 3),
      ),
    );
  }

  // ─── BUILD ──────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF6F7),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _ink,
            size: 20,
          ),
          onPressed: _step == 0
              ? () => Navigator.maybePop(context)
              : () => _goToStep(_step - 1),
        ),
        centerTitle: true,
        title: Text(
          'Register Pregnancy',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
                child: switch (_step) {
                  0 => _buildLmpStep(),
                  1 => _buildAncStep(),
                  _ => _buildReviewStep(),
                },
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          for (var i = 0; i < _stepTitles.length; i++) ...[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _step ? _accent : const Color(0xFFF0D9DE),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _stepTitles[i],
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: i == _step
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: i <= _step ? _accent : const Color(0xFFB6AEB1),
                    ),
                  ),
                ],
              ),
            ),
            if (i != _stepTitles.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  // ─── STEP 1 · LMP ───────────────────────────────────────────

  Widget _buildLmpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 150,
          child: Image.asset(
            'assets/allobaby/Baby3D.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/allobaby/BabyIllustration.png',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0F4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  size: 50,
                  color: _accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'When was the first day of\nyour last period (LMP)?',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Your LMP date sets your baby's gestational age, your due date and "
          'every appointment we schedule next.',
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.45),
        ),
        const SizedBox(height: 24),

        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _CardLabel(
                icon: Icons.calendar_today_rounded,
                text: 'LAST MENSTRUAL PERIOD (LMP)',
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: _pickLmpDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF0F4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD2DC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.event_note_rounded,
                        color: _accent,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _dateFmt.format(_selectedLmpDate),
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Change',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFFFF0F4),
                icon: Icons.event_available_rounded,
                iconColor: const Color(0xFFFF4E6A),
                title: 'Estimated Due',
                value: _dateFmt.format(_calculatedEdd),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFF3E8FF),
                icon: Icons.child_care_rounded,
                iconColor: const Color(0xFF8B5CF6),
                title: 'Current Stage',
                value: 'Week $_calculatedGestationalWeek',
                subtitle: _calculatedTrimester,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFEDF6FF),
                icon: Icons.hourglass_bottom_rounded,
                iconColor: const Color(0xFF3898EC),
                title: 'Days Left',
                value: '$_daysRemaining d',
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── STEP 2 · ANC MONTHS ────────────────────────────────────

  Widget _buildAncStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Which months will you go\nfor your ANC check-up?',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.25,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pick the pregnancy months you plan to visit your doctor in. Each '
          'visit is booked on the same day of the month as your LMP.',
          style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.45),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            _QuickChip(
              label: 'All 10 months',
              onTap: () => setState(() {
                _ancMonths
                  ..clear()
                  ..addAll(pregnancyMonths);
              }),
            ),
            const SizedBox(width: 8),
            _QuickChip(
              label: 'Recommended',
              onTap: () => setState(() {
                _ancMonths
                  ..clear()
                  ..addAll(defaultAncMonths);
              }),
            ),
            const SizedBox(width: 8),
            _QuickChip(label: 'Clear', onTap: () => setState(_ancMonths.clear)),
          ],
        ),
        const SizedBox(height: 16),

        for (final month in pregnancyMonths)
          _MonthRow(
            month: month,
            selected: _ancMonths.contains(month),
            dateLabel: _dateFmt.format(
              addMonthsClamped(_selectedLmpDate, month),
            ),
            onTap: () => setState(() {
              if (!_ancMonths.remove(month)) _ancMonths.add(month);
            }),
          ),

        const SizedBox(height: 6),
        _InfoNote(
          text: _ancMonths.isEmpty
              ? 'No ANC visits will be booked. Your vaccinations and lab tests '
                    'are still scheduled on their clinical dates.'
              : '${_ancMonths.length} ANC visit'
                    '${_ancMonths.length == 1 ? '' : 's'} will be booked.',
        ),
      ],
    );
  }

  // ─── STEP 3 · REVIEW ────────────────────────────────────────

  Widget _buildReviewStep() {
    final preview = _preview;
    final reportsByMonth = <int, List<ScheduledReport>>{};
    for (final report in _dueReports) {
      reportsByMonth.putIfAbsent(report.month, () => []).add(report);
    }
    final months = reportsByMonth.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          "Here's your care plan",
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Due ${_dateFmt.format(_calculatedEdd)} · everything below is saved '
          'on this device.',
          style: GoogleFonts.poppins(fontSize: 13, color: _muted, height: 1.45),
        ),
        const SizedBox(height: 18),

        Row(
          children: [
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFFFF0F4),
                icon: Icons.local_hospital_rounded,
                iconColor: const Color(0xFFFF4E6A),
                title: 'ANC visits',
                value: '${preview.ancCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFEFFAF3),
                icon: Icons.vaccines_rounded,
                iconColor: const Color(0xFF10B981),
                title: 'Vaccines',
                value: '${preview.vaccineCount}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _EstimateChip(
                bg: const Color(0xFFEDF6FF),
                icon: Icons.science_rounded,
                iconColor: const Color(0xFF3898EC),
                title: 'Lab tests',
                value: '${preview.reportCount}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ── ANC visits ──
        _Section(
          icon: Icons.local_hospital_rounded,
          color: const Color(0xFFFF4E6A),
          title: 'ANC check-ups',
          subtitle: preview.ancCount == 0
              ? 'None selected'
              : '${preview.ancCount} visits',
          child: preview.ancCount == 0
              ? _EmptyRow(
                  text: 'You did not pick any ANC months.',
                  onFix: () => _goToStep(1),
                )
              : Column(
                  children: [
                    for (final entry in preview.ancDates.entries)
                      _PlanRow(
                        title: 'ANC · ${monthLabel(entry.key)}',
                        trailing: _shortFmt.format(entry.value),
                        subtitle: 'Trimester ${trimesterForMonth(entry.key)}',
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),

        // ── Vaccinations ──
        _Section(
          icon: Icons.vaccines_rounded,
          color: const Color(0xFF10B981),
          title: 'Vaccinations',
          subtitle: '${vaccineSchedule.length} doses',
          child: Column(
            children: [
              for (final vaccine in vaccineSchedule)
                _PlanRow(
                  title: vaccine.name,
                  subtitle: '${monthLabel(vaccine.month)} · ${vaccine.purpose}',
                  trailing: _shortFmt.format(
                    addMonthsClamped(_selectedLmpDate, vaccine.month),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Lab reports ──
        _Section(
          icon: Icons.science_rounded,
          color: const Color(0xFF3898EC),
          title: 'Lab tests & scans',
          subtitle: '${_dueReports.length} tests',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                value: _includeOptional,
                onChanged: (v) => setState(() => _includeOptional = v),
                activeThumbColor: const Color(0xFF3898EC),
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(
                  'Include optional tests',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: _ink,
                  ),
                ),
                subtitle: Text(
                  'TB screening and NST are only done when your doctor '
                  'asks for them',
                  style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                ),
              ),
              const SizedBox(height: 4),
              for (final month in months) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 4),
                  child: Text(
                    '${monthLabel(month)} · '
                    '${_shortFmt.format(addMonthsClamped(_selectedLmpDate, month))}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3898EC),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                for (final report in reportsByMonth[month]!)
                  _PlanRow(
                    title: report.name,
                    subtitle: report.purpose,
                    badge: report.isRequired ? null : 'Optional',
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── FOOTER ─────────────────────────────────────────────────

  Widget _buildFooter() {
    final isLast = _step == _stepTitles.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF6F7),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.04)),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : isLast
              ? _submit
              : () => _goToStep(_step + 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: 0.5),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLast
                          ? Icons.favorite_rounded
                          : Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isLast ? 'Create Pregnancy Journey' : 'Continue',
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ─── SHARED PIECES ────────────────────────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _CardLabel extends StatelessWidget {
  const _CardLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _accent, size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _accent,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

class _EstimateChip extends StatelessWidget {
  const _EstimateChip({
    required this.bg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final Color bg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 13),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle ?? title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF0D9DE)),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: _accent,
          ),
        ),
      ),
    );
  }
}

class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.month,
    required this.dateLabel,
    required this.selected,
    required this.onTap,
  });

  final int month;
  final String dateLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F4) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFFFFD2DC) : const Color(0xFFF0F1F5),
            width: selected ? 1.4 : 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _accent : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: const Color(0xFFD0D5DD), width: 1.6),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monthLabel(month),
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                    ),
                  ),
                  Text(
                    'Trimester ${trimesterForMonth(month)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: _muted),
                  ),
                ],
              ),
            ),
            Text(
              dateLabel,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? _accent : const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: _muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
  });

  final String title;
  final String? subtitle;
  final String? trailing;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: Color(0xFFD0D5DD),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _ink,
                        ),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: _muted,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8E95A5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyRow extends StatelessWidget {
  const _EmptyRow({required this.text, required this.onFix});

  final String text;
  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(fontSize: 12, color: _muted),
            ),
          ),
          TextButton(
            onPressed: onFix,
            child: Text(
              'Pick months',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: const Color(0xFF8A5A63),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
