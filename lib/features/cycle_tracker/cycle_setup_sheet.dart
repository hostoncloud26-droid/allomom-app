import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/cycle_tracker/cycle_theme.dart';
import 'package:allomom/features/cycle_tracker/widgets/stepper_row.dart';
import 'package:allomom/repositories/cycle_repository.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/cycle_predictor.dart';

/// Asks for the three things a prediction needs: when the last period started,
/// how long it lasts, and how long the cycle runs.
///
/// The same sheet does first-time setup and "log this month's period" — the
/// questions are identical, only the wording changes, and logging again is how
/// the prediction stays accurate.
class CycleSetupSheet extends StatefulWidget {
  const CycleSetupSheet({super.key, this.isFirstSetup = false});

  /// Whether she has never tracked before, which only changes the copy.
  final bool isFirstSetup;

  /// Opens the sheet; resolves to true when a period was saved.
  static Future<bool> show(
    BuildContext context, {
    required bool isFirstSetup,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CycleSetupSheet(isFirstSetup: isFirstSetup),
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
    final session = UserSessionManager.instance;
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _periodDuration = session.averagePeriodDuration;
    _cycleLength = session.averageCycleLength;
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      // Three months back covers a forgotten cycle or two without letting a
      // mis-tap set a date that would make every prediction nonsense.
      firstDate: now.subtract(const Duration(days: 120)),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: CycleColors.accent,
            onPrimary: Colors.white,
            onSurface: CycleColors.ink,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (_hasEnded == null || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      await CycleRepository.instance.logPeriod(
        start: _startDate,
        // An ongoing period has no end date yet; it gets one when she logs
        // the next cycle or edits this one.
        end: _hasEnded!
            ? _startDate.add(Duration(days: _periodDuration - 1))
            : null,
        cycleLength: _cycleLength,
        periodDuration: _periodDuration,
        cycleType: _hasEnded! ? 'completed' : 'ongoing',
      );
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

  @override
  Widget build(BuildContext context) {
    final canSave = _hasEnded != null && !_isSaving;

    return Padding(
      // Lifts the sheet clear of the keyboard and the home indicator.
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                      color: const Color(0xFFE2E4E9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 22),

                Text(
                  widget.isFirstSetup ? 'Track your cycle' : 'Log your period',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: CycleColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isFirstSetup
                      ? 'Three quick answers and we can tell you when your '
                            'next period and fertile days are due.'
                      : 'Logging each period keeps your predictions accurate.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: CycleColors.muted,
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

                _SectionLabel('Has it finished?'),
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
                        title: 'Finished',
                        selected: _hasEnded == true,
                        onTap: () => setState(() => _hasEnded = true),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                CycleStepperRow(
                  title: 'Period length',
                  subtitle: 'How many days you usually bleed',
                  value: _periodDuration,
                  min: minPeriodDuration,
                  max: maxPeriodDuration,
                  onChanged: (v) => setState(() => _periodDuration = v),
                ),
                const SizedBox(height: 16),
                CycleStepperRow(
                  title: 'Cycle length',
                  subtitle: 'First day of one period to the next',
                  value: _cycleLength,
                  min: minCycleLength,
                  max: maxCycleLength,
                  onChanged: (v) => setState(() => _cycleLength = v),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: canSave ? _save : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CycleColors.accent,
                      disabledBackgroundColor: const Color(0xFFF1F5F9),
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
                            widget.isFirstSetup
                                ? 'Start tracking'
                                : 'Save period',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: canSave
                                  ? Colors.white
                                  : const Color(0xFFA0A7B4),
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
        color: CycleColors.muted,
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
          color: CycleColors.accentSoft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFFFDCE4)),
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
                  color: CycleColors.ink,
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
          color: selected ? CycleColors.accentSoft : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? CycleColors.accent : const Color(0xFFE2E4E9),
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
                color: selected ? CycleColors.accent : CycleColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
