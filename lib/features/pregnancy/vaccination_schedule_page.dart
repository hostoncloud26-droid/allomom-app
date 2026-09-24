import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// The maternal vaccine doses booked locally when the pregnancy was registered.
class VaccinationSchedulePage extends StatefulWidget {
  const VaccinationSchedulePage({super.key});

  @override
  State<VaccinationSchedulePage> createState() =>
      _VaccinationSchedulePageState();
}

class _VaccinationSchedulePageState extends State<VaccinationSchedulePage> {
  bool _isLoading = true;
  String? _pregnancyId;
  List<PregnancyImmunizationRecord> _vaccines = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// What the card says: the tour of the screen, or, when there is nothing
  /// scheduled, the line that tells her how to get something on it.
  String get _narrationKey => (_pregnancyId == null || _vaccines.isEmpty)
      ? NarrationKeys.pgVaccEmpty
      : NarrationKeys.pgVaccOpen;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final session = MainController.instance;
      final healthId = session.healthDataId;
      final pregnancy = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      final vaccines = pregnancy == null
          ? const <PregnancyImmunizationRecord>[]
          : await PregnancyCareDbService.instance.getVaccinations(pregnancy.id);

      // By due date, undated doses last: the list reads top to bottom as the
      // order she will take them in.
      final sorted = [...vaccines]
        ..sort((a, b) {
          final da = a.scheduledDateRangeFrom ?? a.scheduledDate;
          final db = b.scheduledDateRangeFrom ?? b.scheduledDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _vaccines = sorted;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vaccination schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(PregnancyImmunizationRecord vaccine) async {
    final wasDone = vaccine.status == 'done';
    try {
      // A dose is given exactly when it has a received date.
      await PregnancyController.instance.setVaccinationReceived(
        vaccine.id,
        wasDone ? null : DateTime.now(),
      );
      await _load();
      if (!wasDone) speak(NarrationKeys.pgConfVaccSaved, force: true);
    } catch (e) {
      debugPrint('Error updating vaccination ${vaccine.id}: $e');
    }
  }

  List<PregnancyImmunizationRecord> get _completed =>
      _vaccines.where((v) => v.isDone).toList();

  List<PregnancyImmunizationRecord> get _pending =>
      _vaccines.where((v) => !v.isDone).toList();

  @override
  Widget build(BuildContext context) {
    final week = MainController.instance.currentGestationalWeek;

    final p = context.palette;

    return Scaffold(
      backgroundColor: p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFFFF3B5C),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Vaccinations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.pick(const Color(0xFF1E2024), p.textPrimary),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'About vaccinations',
            icon: Icon(Icons.info_outline_rounded, color: p.textPrimary),
            onPressed: _showInfo,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
              )
            : RefreshIndicator(
                onRefresh: _load,
                color: const Color(0xFFFF3B5C),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  children: [
                    BabyHeroBanner(
                      // The line plays, then the card goes back to its own
                      // copy — which counts the weeks, and the script cannot.
                      narrationKey: _narrationKey,
                      bindNarrationText: false,
                      speechText:
                          "Week $week, Amma!\nWe're growing together. Can you feel the kicks?",
                      bubblePosition: SpeechBubblePosition.left,
                      height: 230,
                      greetingText: '',
                    ),
                    const SizedBox(height: 16),

                    if (_pregnancyId == null || _vaccines.isEmpty)
                      CareScheduleEmpty(
                        icon: Icons.vaccines_rounded,
                        title: 'No vaccinations scheduled',
                        message:
                            'Register your pregnancy and we will book TT-1, '
                            'TT-2, the flu shot and Tdap on their due months.',
                        onRegistered: _load,
                      )
                    else ...[
                      CareProgressCard(
                        done: _completed.length,
                        total: _vaccines.length,
                      ),
                      if (_completed.isNotEmpty) ...[
                        const CareSectionLabel('Completed'),
                        for (final v in _completed) ...[
                          _completedCard(v, p),
                          const SizedBox(height: 10),
                        ],
                      ],
                      if (_pending.isNotEmpty) ...[
                        const CareSectionLabel('Next'),
                        _nextCard(_pending.first, p),
                      ],
                      if (_pending.length > 1) ...[
                        const CareSectionLabel('Coming later'),
                        for (final v in _pending.skip(1)) ...[
                          _laterCard(v, p),
                          const SizedBox(height: 10),
                        ],
                      ],
                      const SizedBox(height: 14),
                      const CareFooterNote(
                        icon: Icons.notifications_none_rounded,
                        title: "We'll remind you",
                        subtitle: "when it's time for your next vaccine.",
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  String? _weekOf(PregnancyImmunizationRecord v) =>
      careWeekLabel(v.scheduledDateRangeFrom ?? v.scheduledDate, v.scheduledDateRangeTo);

  TextStyle _titleStyle(AppPalette p) => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: p.textPrimary,
  );

  TextStyle _subStyle(AppPalette p) =>
      TextStyle(fontSize: 12.5, color: p.textMuted);

  Widget _completedCard(PregnancyImmunizationRecord v, AppPalette p) {
    final week = _weekOf(v);
    return CareCard(
      onTap: () => _openDetails(v),
      child: Row(
        children: [
          const CareMarkerIcon(marker: CareMarker.done),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.vaccineName, style: _titleStyle(p)),
                if (week != null) ...[
                  const SizedBox(height: 3),
                  Text(week, style: _subStyle(p)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (v.administeredDate != null)
                Text(
                  careDateFmt.format(v.administeredDate!),
                  style: TextStyle(fontSize: 12.5, color: p.textSecondary),
                ),
              const SizedBox(height: 4),
              const Text(
                'Completed',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nextCard(PregnancyImmunizationRecord v, AppPalette p) {
    final week = _weekOf(v);
    final date = v.scheduledDate;
    return CareCard(
      onTap: () => _openDetails(v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CareMarkerIcon(marker: CareMarker.next),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(v.vaccineName, style: _titleStyle(p)),
                    if (week != null) ...[
                      const SizedBox(height: 3),
                      Text(week, style: _subStyle(p)),
                    ],
                  ],
                ),
              ),
              const CareChevron(),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  date == null ? 'Date to be decided' : careDateFmt.format(date),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B5C),
                  ),
                ),
              ),
              CareOutlineButton(
                label: 'View details',
                onTap: () => _openDetails(v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _laterCard(PregnancyImmunizationRecord v, AppPalette p) {
    final week = _weekOf(v);
    final date = v.scheduledDate;
    return CareCard(
      onTap: () => _openDetails(v),
      child: Row(
        children: [
          const CareMarkerIcon(marker: CareMarker.later),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v.vaccineName, style: _titleStyle(p)),
                if (week != null) ...[
                  const SizedBox(height: 3),
                  Text(week, style: _subStyle(p)),
                ],
                const SizedBox(height: 6),
                Text(
                  date == null
                      ? 'Date to be decided'
                      : careDateFmt.format(date),
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
              ],
            ),
          ),
          const CareChevron(),
        ],
      ),
    );
  }

  void _openDetails(PregnancyImmunizationRecord v) {
    final status = CareStatus.resolve(status: v.status, date: v.scheduledDate);
    final week = _weekOf(v);
    final month = v.pregnancyMonth;
    showCareDetailSheet(
      context,
      eyebrow: 'Dose ${v.doseNumber}',
      title: v.vaccineName,
      status: status,
      facts: [
        if (week != null) (Icons.pregnant_woman_rounded, week),
        if (month != null) (Icons.calendar_view_month_rounded, monthLabel(month)),
        (
          Icons.event_rounded,
          v.scheduledDate == null
              ? 'Date to be decided'
              : 'Due ${careDateFmt.format(v.scheduledDate!)}',
        ),
        if (v.administeredDate != null)
          (
            Icons.verified_rounded,
            'Given ${careDateFmt.format(v.administeredDate!)}',
          ),
      ],
      primaryLabel: status.isDone ? 'Mark as not taken' : 'Mark as taken',
      primaryIcon: status.isDone
          ? Icons.undo_rounded
          : Icons.check_circle_outline_rounded,
      primaryQuiet: status.isDone,
      primaryEnabled: status.isDone || careIsDue(v.scheduledDate),
      disabledNote: 'You can mark it once its date arrives.',
      onPrimary: () => _toggleDone(v),
    );
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Your vaccinations',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'These doses were booked when you registered your pregnancy. '
          'Tap one to see its details and mark it as taken after the clinic.',
          style: TextStyle(fontSize: 13.5, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFFF3B5C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
