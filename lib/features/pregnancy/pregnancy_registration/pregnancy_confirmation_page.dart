import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/components/lmp_wheel_picker.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/pregnancy_care_scheduler.dart';

const _accent = Color(0xFFFF3B5C);

// Ink follows light / dark mode; the accent stays the brand pink.
Color _inkOf(BuildContext context) =>
    context.palette.pick(const Color(0xFF1E2024), context.palette.textPrimary);
Color _mutedOf(BuildContext context) => context.palette.pick(
  const Color(0xFF6B707B),
  context.palette.textSecondary,
);

/// A light-mode colour, or its dark-mode stand-in.
Color _pick(BuildContext context, Color light, Color dark) =>
    context.palette.pick(light, dark);

/// Registers a pregnancy from one question: the first day of her last period.
///
/// Everything else follows from that date. Confirming creates the pregnancy
/// and books its whole care schedule — ANC visits in the recommended months,
/// every vaccine dose and every lab test — into SQLite with `synced = 0`. The
/// schedule is not laid out here: it is waiting for her in the journey the
/// moment she lands there, and listing forty rows before she has even started
/// only made a one-question screen look like a form.
class PregnancyConfirmationPage extends StatefulWidget {
  const PregnancyConfirmationPage({super.key});

  @override
  State<PregnancyConfirmationPage> createState() =>
      _PregnancyConfirmationPageState();
}

class _PregnancyConfirmationPageState extends State<PregnancyConfirmationPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// Starts on today, as sign-up's wheels do: she scrolls back from now. It
  /// used to open on a made-up "eight weeks ago", which read as her answer.
  late DateTime _lmp = _today;
  bool _isSubmitting = false;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  // ─── DERIVED VALUES ─────────────────────────────────────────

  DateTime get _edd => _lmp.add(const Duration(days: 280));

  /// Completed weeks, counted exactly as `PregnancyController` does — this is
  /// a preview of what home will say once she registers, so it must not round
  /// the week up when home rounds it down.
  int get _week {
    final days = _today.difference(_lmp).inDays;
    return days >= 0 ? days ~/ 7 : 0;
  }

  String get _trimester {
    final week = _week;
    if (week < 13) return '1st trimester';
    if (week < 28) return '2nd trimester';
    return '3rd trimester';
  }

  int get _daysLeft {
    final days = _edd.difference(_today).inDays;
    return days < 0 ? 0 : days;
  }

  // ─── ACTIONS ────────────────────────────────────────────────

  Future<void> _submit() async {
    final lmp = _lmp;
    setState(() => _isSubmitting = true);

    try {
      final session = MainController.instance;

      // 1. The pregnancy itself.
      final pregnancyId = await PregnancyController.instance.createPregnancy(
        lmpDate: lmp,
        eddDate: _edd,
      );

      if (pregnancyId == null) {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        _toast(
          'Could not register the pregnancy. Please check your connection '
          'and try again.',
          isError: true,
        );
        return;
      }

      // 2. Its care schedule: ANC visits in the recommended months, plus every
      //    vaccine dose and lab test on its clinical date.
      await PregnancyCareScheduler.instance.scheduleFor(
        pregnancyId: pregnancyId,
        userId: session.userId,
        lmpDate: lmp,
        ancMonths: defaultAncMonths,
        includeOptional: true,
      );

      if (!mounted) return;
      _toast('Your pregnancy journey is ready ✨');
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
    final background = _pick(
      context,
      const Color(0xFFFAF6F7),
      context.palette.scaffoldSoft,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _inkOf(context),
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: Text(
          'Register Pregnancy',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _inkOf(context),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            const SizedBox(height: 8),
                            _buildHeader(),
                            const SizedBox(height: 16),
                            const Spacer(flex: 1),
                            LmpWheelPicker(
                              selectedDate: _lmp,
                              onDateChanged: (date) =>
                                  setState(() => _lmp = date),
                            ),
                            const SizedBox(height: 16),
                            const Spacer(flex: 1),
                            _buildSummary(),
                            const SizedBox(height: 16),
                            const Spacer(flex: 1),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildFooter(background),
          ],
        ),
      ),
    );
  }

  /// The baby asks the question herself, in the same card and the same words
  /// as sign-up — this is that step again for a mother who skipped it then.
  /// Her bubble is the only instruction the page needs.
  Widget _buildHeader() {
    return const BabyHeroBanner(
      narrationKey: NarrationKeys.pregLmp,
      speechText: 'Mommy, when did your last period start?',
      height: 210,
    );
  }

  /// What that date means, in one row: the due date she will repeat to
  /// everyone, then her week and the days left.
  Widget _buildSummary() {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  size: 13,
                  color: _accent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'This is the date I will meet you, Mommy! 💕',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _inkOf(context),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _pick(context, const Color(0xFFF0F1F5), p.border),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              _Stat(
                value: _dateFmt.format(_edd),
                label: 'Due date',
                valueColor: _accent,
              ),
              _StatDivider(),
              _Stat(value: 'Week $_week', label: _trimester),
              _StatDivider(),
              _Stat(value: '$_daysLeft', label: 'days to go'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(Color background) {
    final ready = !_isSubmitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      color: background,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: ready ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            disabledBackgroundColor: _accent.withValues(alpha: 0.4),
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
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.favorite_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Start my journey',
                      style: TextStyle(
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

// ─── PIECES ───────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, this.valueColor});

  final String value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              maxLines: 1,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: valueColor ?? _inkOf(context),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _mutedOf(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 38, color: context.palette.divider);
  }
}
