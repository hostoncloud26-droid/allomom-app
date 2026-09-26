import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/cycle_tracker/cycle_theme.dart';
import 'package:allomom/features/cycle_tracker/widgets/stepper_row.dart';
import 'package:allomom/repositories/cycle_repository.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/menstrual_tracker.dart';

/// First-time setup and "edit this period", the two forms AlloConnect's
/// tracker has.
///
/// Setup asks whether her latest period is still going, when it started and —
/// if it is over — how long it lasted. Editing corrects a logged period's
/// start, length and cycle length. Logging a new period needs only a date, so
/// the tracker page does that with a date picker instead.
class CycleSetupSheet extends StatefulWidget {
  const CycleSetupSheet({super.key, this.editing});

  /// The period being corrected; null for first-time setup.
  final PeriodLog? editing;

  bool get isEditing => editing != null;

  /// First-time setup; resolves to true when a period was saved.
  static Future<bool> show(BuildContext context) => _open(context, null);

  /// Edits [log]; resolves to true when it was saved.
  static Future<bool> edit(BuildContext context, PeriodLog log) =>
      _open(context, log);

  static Future<bool> _open(BuildContext context, PeriodLog? editing) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleSetupSheet(editing: editing),
    );
    return saved ?? false;
  }

  @override
  State<CycleSetupSheet> createState() => _CycleSetupSheetState();
}

class _CycleSetupSheetState extends State<CycleSetupSheet> {
  static final _dateFmt = DateFormat('d MMMM, yyyy');

  late DateTime _startDate;
  late int _periodDuration;
  late int _cycleLength;

  /// Null until she answers; the save button stays disabled meanwhile, so a
  /// half-answered sheet never writes a guess to her record.
  bool? _hasEnded;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final editing = widget.editing;
    if (editing != null) {
      _startDate = editing.start;
      _periodDuration = editing
          .daysSoFar(DateTime.now())
          .clamp(trackerMinDuration, trackerMaxDuration);
      _cycleLength = editing.averageCycle.clamp(
        trackerMinCycle,
        trackerMaxCycle,
      );
      return;
    }
    final session = MainController.instance;
    _startDate = dateOnly(DateTime.now());
    _periodDuration = session.averagePeriodDuration.clamp(
      trackerMinDuration,
      trackerMaxDuration,
    );
    _cycleLength = session.averageCycleLength.clamp(
      trackerMinCycle,
      trackerMaxCycle,
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      // Three months back for setup, as AlloConnect allows; a year when
      // correcting an older period in her history.
      firstDate: now.subtract(Duration(days: widget.isEditing ? 365 : 90)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: context.palette.isDark
              ? ColorScheme.dark(
                  primary: CycleColors.accent,
                  onPrimary: Colors.white,
                  surface: context.palette.card,
                  onSurface: context.palette.textPrimary,
                )
              : ColorScheme.light(
                  primary: CycleColors.accent,
                  onPrimary: Colors.white,
                  onSurface: CycleColors.inkOn(context),
                ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _isSaving = true);

    try {
      final editing = widget.editing;
      if (editing != null) {
        await CycleRepository.instance.editPeriod(
          editing,
          start: _startDate,
          periodDuration: _periodDuration,
          averageCycle: _cycleLength,
        );
      } else {
        await CycleRepository.instance.setUpTracking(
          start: _startDate,
          completed: _hasEnded!,
          periodDuration: _periodDuration,
          averageCycle: _cycleLength,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save your cycle. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool get _canSave => !_isSaving && (widget.isEditing || _hasEnded != null);

  @override
  Widget build(BuildContext context) {
    final canSave = _canSave;
    final editing = widget.isEditing;

    return Padding(
      // Lifts the sheet clear of the keyboard and the home indicator.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: context.palette.pick(
                        const Color(0xFFE2E4E9),
                        context.palette.divider,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  editing ? 'Edit cycle entry' : 'Quick setup',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: CycleColors.inkOn(context),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  editing
                      ? 'Correct when this period started, how long it lasted '
                            'and your usual cycle length.'
                      : 'A few quick answers and we can tell you when your '
                            'next period and fertile days are due.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: CycleColors.mutedOn(context),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                _SectionLabel('When did it start?'),
                const SizedBox(height: 8),
                _DateTile(
                  label: _dateFmt.format(_startDate),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 20),

                if (!editing) ...[
                  _SectionLabel('Is your latest period completed?'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ChoiceCard(
                          emoji: '🩸',
                          title: 'Ongoing',
                          selected: _hasEnded == false,
                          onTap: () => setState(() => _hasEnded = false),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ChoiceCard(
                          emoji: '✅',
                          title: 'Completed',
                          selected: _hasEnded == true,
                          onTap: () => setState(() => _hasEnded = true),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // An ongoing period's length is not known yet — it is
                // recorded when she marks it ended.
                if (editing || _hasEnded == true) ...[
                  CycleStepperRow(
                    title: 'Period length',
                    subtitle: 'How many days it lasted',
                    value: _periodDuration,
                    min: trackerMinDuration,
                    max: trackerMaxDuration,
                    onChanged: (v) => setState(() => _periodDuration = v),
                  ),
                  const SizedBox(height: 16),
                ],
                CycleStepperRow(
                  title: 'Cycle length',
                  subtitle: 'First day of one period to the next',
                  value: _cycleLength,
                  min: trackerMinCycle,
                  max: trackerMaxCycle,
                  onChanged: (v) => setState(() => _cycleLength = v),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CycleColors.accent,
                      disabledBackgroundColor: context.palette.pick(
                        const Color(0xFFF1F5F9),
                        context.palette.surface,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            editing ? 'Update entry' : 'Start tracking',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: canSave
                                  ? Colors.white
                                  : context.palette.pick(
                                      const Color(0xFFA0A7B4),
                                      context.palette.textMuted,
                                    ),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: CycleColors.mutedOn(context),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: CycleColors.softOn(
            context,
            CycleColors.accent,
            CycleColors.accentSoft,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: context.palette.pick(
              const Color(0xFFFFDCE4),
              context.palette.accentBorder,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              color: CycleColors.accent,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CycleColors.inkOn(context),
                ),
              ),
            ),
            const Icon(
              Icons.edit_calendar_rounded,
              color: CycleColors.accent,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.emoji,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? CycleColors.softOn(
                  context,
                  CycleColors.accent,
                  CycleColors.accentSoft,
                )
              : context.palette.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? CycleColors.accent
                : context.palette.pick(
                    const Color(0xFFE2E4E9),
                    context.palette.border,
                  ),
            width: selected ? 1.6 : 1.2,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? CycleColors.accent
                    : CycleColors.inkOn(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
