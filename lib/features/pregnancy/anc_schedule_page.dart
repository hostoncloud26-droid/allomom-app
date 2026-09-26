import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

/// The ANC visits booked locally when the pregnancy was registered.
class AncSchedulePage extends StatefulWidget {
  const AncSchedulePage({super.key});

  @override
  State<AncSchedulePage> createState() => _AncSchedulePageState();
}

class _AncSchedulePageState extends State<AncSchedulePage> {
  static final _timeFmt = DateFormat('h:mm a');

  int _trimesterFilter = 0; // 0: All, 1..3: trimester
  bool _isLoading = true;
  String? _pregnancyId;
  List<AncCheckupDate> _visits = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// What the card says: the tour of the screen, or, when there is nothing
  /// scheduled, the line that tells her how to get something on it.
  String get _narrationKey => (_pregnancyId == null || _visits.isEmpty)
      ? NarrationKeys.pgAncEmpty
      : NarrationKeys.pgAncOpen;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final session = MainController.instance;
      final healthId = session.healthDataId;
      final pregnancy = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      final visits = pregnancy == null
          ? const <AncCheckupDate>[]
          : await PregnancyCareDbService.instance.getAncVisits(pregnancy.id);

      final sorted = [...visits]..sort((a, b) => a.month.compareTo(b.month));

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _visits = sorted;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading ANC schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(AncCheckupDate visit) async {
    final wasDone = visit.status == 'done';
    try {
      // A visit is done exactly when it has a completion date — there is no
      // separate status column to keep in step with it.
      await PregnancyController.instance.setAncCompleted(
        visit.id,
        wasDone ? null : DateTime.now(),
      );
      await _load();
      if (!wasDone) speak(NarrationKeys.pgConfAncSaved, force: true);
    } catch (e) {
      debugPrint('Error updating ANC visit ${visit.id}: $e');
    }
  }

  List<AncCheckupDate> get _filtered => _trimesterFilter == 0
      ? _visits
      : _visits.where((v) => v.trimester == _trimesterFilter).toList();

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
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: _showInfo,
              customBorder: const CircleBorder(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: p.textPrimary, width: 1.4),
                ),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: p.textPrimary,
                ),
              ),
            ),
          ),
        ],
        title: Text(
          'ANC Care',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.pick(const Color(0xFF1E2024), p.textPrimary),
          ),
        ),
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

                    if (_pregnancyId == null)
                      CareScheduleEmpty(
                        icon: Icons.local_hospital_rounded,
                        title: 'No ANC visits yet',
                        message:
                            'Register your pregnancy and we will book an ANC '
                            'check-up for every month you choose.',
                        onRegistered: _load,
                      )
                    else if (_visits.isEmpty)
                      CareScheduleEmpty(
                        icon: Icons.event_busy_rounded,
                        title: 'No ANC months picked',
                        message:
                            'You did not select any ANC months when '
                            'registering. Register again to pick them.',
                        onRegistered: _load,
                      )
                    else ...[
                      CareFilterChips(
                        labels: const [
                          'All',
                          '1st Trimester',
                          '2nd Trimester',
                          '3rd Trimester',
                        ],
                        selected: _trimesterFilter,
                        onSelected: (i) => setState(() => _trimesterFilter = i),
                      ),
                      const SizedBox(height: 4),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'No visits in this trimester.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: p.textSecondary,
                            ),
                          ),
                        )
                      else
                        for (final trimester in const [1, 2, 3])
                          ..._trimesterGroup(trimester, p),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  static const _trimesterNames = {
    1: 'First Trimester',
    2: 'Second Trimester',
    3: 'Third Trimester',
  };

  /// The first visit not yet attended — the one card that gets the pink
  /// outline and the "View details" button.
  AncCheckupDate? get _nextVisit {
    for (final v in _visits) {
      if (!v.isDone) return v;
    }
    return null;
  }

  List<Widget> _trimesterGroup(int trimester, AppPalette p) {
    final visits = _filtered.where((v) => v.trimester == trimester).toList();
    if (visits.isEmpty) return const [];
    final next = _nextVisit;
    return [
      CareSectionLabel(
        _trimesterNames[trimester]!,
        color: p.pick(const Color(0xFF4B5563), p.textSecondary),
      ),
      for (var i = 0; i < visits.length; i++)
        CareTimelineTile(
          marker: _markerFor(visits[i], next),
          isFirst: i == 0,
          isLast: i == visits.length - 1,
          child: _visitCard(visits[i], visits[i].id == next?.id, p),
        ),
    ];
  }

  CareMarker _markerFor(AncCheckupDate v, AncCheckupDate? next) {
    if (v.isDone) return CareMarker.done;
    if (v.id == next?.id) return CareMarker.next;
    return CareMarker.later;
  }

  String _weekLine(AncCheckupDate v) =>
      careWeekLabel(v.scheduledDateRangeFrom ?? v.scheduledDate, null) ??
      monthLabel(v.pregnancyMonth);

  /// "12 Sep 2026 · 10:30 AM" — the time only when one was actually booked.
  String? _whenLine(AncCheckupDate v) {
    final d = v.scheduledDate;
    if (d == null) return null;
    final hasTime = d.hour != 0 || d.minute != 0;
    return hasTime
        ? '${careDateFmt.format(d)} · ${_timeFmt.format(d)}'
        : careDateFmt.format(d);
  }

  Widget _visitCard(AncCheckupDate v, bool isNext, AppPalette p) {
    final status = CareStatus.resolve(status: v.status, date: v.scheduledDate);
    final when = _whenLine(v);

    return CareCard(
      highlighted: isNext,
      onTap: () => _openDetails(v),
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isNext) ...[
                      const Text(
                        'NEXT UP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: Color(0xFFFF3B5C),
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      _weekLine(v),
                      style: TextStyle(fontSize: 12, color: p.textMuted),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'ANC Check-up',
                      style: TextStyle(
                        fontSize: isNext ? 16.5 : 15,
                        fontWeight: FontWeight.w800,
                        color: p.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isNext && when != null)
                      Text(
                        when,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textSecondary,
                        ),
                      )
                    else if (!isNext)
                      CarePill(
                        status: status,
                        label:
                            status == CareStatus.scheduled ||
                                status == CareStatus.dueSoon
                            ? 'Upcoming'
                            : null,
                      ),
                  ],
                ),
              ),
              const CareChevron(),
            ],
          ),
          if (isNext)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: CareOutlineButton(
                  label: 'View details',
                  onTap: () => _openDetails(v),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetails(AncCheckupDate v) {
    final status = CareStatus.resolve(status: v.status, date: v.scheduledDate);
    final when = _whenLine(v);
    showCareDetailSheet(
      context,
      eyebrow: _weekLine(v),
      title: 'ANC Check-up',
      status: status,
      statusLabel:
          status == CareStatus.scheduled || status == CareStatus.dueSoon
          ? 'Upcoming'
          : null,
      facts: [
        (Icons.calendar_view_month_rounded, monthLabel(v.pregnancyMonth)),
        (Icons.event_rounded, when ?? 'Date to be decided'),
        if (v.actualDate != null)
          (
            Icons.verified_rounded,
            'Attended ${careDateFmt.format(v.actualDate!)}',
          ),
      ],
      primaryLabel: status.isDone ? 'Mark as pending' : 'Mark as done',
      primaryIcon: status.isDone
          ? Icons.undo_rounded
          : Icons.check_circle_outline_rounded,
      primaryQuiet: status.isDone,
      primaryEnabled: status.isDone || careIsDue(v.scheduledDate),
      disabledNote: 'You can mark it once the visit date arrives.',
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
          'Your ANC check-ups',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'One check-up for every month you picked when registering. '
          'Tap a visit to see it and mark it done after you see the doctor.',
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
