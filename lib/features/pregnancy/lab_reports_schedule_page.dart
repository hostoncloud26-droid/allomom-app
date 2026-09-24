import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/reports/add_report.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/controllers/pregnancy_controller.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// The lab tests and scans booked locally when the pregnancy was registered,
/// grouped by the pregnancy month they are due in.
class LabReportsSchedulePage extends StatefulWidget {
  const LabReportsSchedulePage({super.key});

  @override
  State<LabReportsSchedulePage> createState() => _LabReportsSchedulePageState();
}

class _LabReportsSchedulePageState extends State<LabReportsSchedulePage> {
  bool _isLoading = true;
  String? _pregnancyId;
  List<PregnancyReportChecklist> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// What the card says: the tour of the screen, or, when there is nothing
  /// scheduled, the line that tells her how to get something on it.
  String get _narrationKey => (_pregnancyId == null || _reports.isEmpty)
      ? NarrationKeys.pgLabEmpty
      : NarrationKeys.pgLabOpen;

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final session = MainController.instance;
      final healthId = session.healthDataId;
      final pregnancy = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      final reports = pregnancy == null
          ? const <PregnancyReportChecklist>[]
          : await PregnancyCareDbService.instance.getReportChecklists(
              pregnancy.id,
            );

      final sorted = [...reports]
        ..sort((a, b) {
          final da = a.scheduledDateRangeFrom ?? a.dueDate;
          final db = b.scheduledDateRangeFrom ?? b.dueDate;
          if (da == null && db == null) return 0;
          if (da == null) return 1;
          if (db == null) return -1;
          return da.compareTo(db);
        });

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _reports = sorted;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading lab report schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(PregnancyReportChecklist report) async {
    final wasDone = report.status == 'done';
    try {
      // A test is done exactly when it has a completion date — no separate
      // status column to keep in step with it.
      await PregnancyController.instance.setReportCompleted(
        report.id,
        wasDone ? null : DateTime.now(),
      );
      await _load();
      if (!wasDone) speak(NarrationKeys.pgConfLabSaved, force: true);
    } catch (e) {
      debugPrint('Error updating report checklist ${report.id}: $e');
    }
  }

  /// Opens the report uploader pre-tagged with this test. When the test has a
  /// checklist row, saving the file also ticks that row off.
  Future<void> _uploadResult(_Entry entry) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddReport(
          checklistId: entry.row?.id,
          checklistName: entry.plan.name,
        ),
      ),
    );
    if (added == true) await _load();
  }


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
          IconButton(
            tooltip: 'About reports',
            icon: Icon(Icons.info_outline_rounded, color: p.textPrimary),
            onPressed: _showInfo,
          ),
          const SizedBox(width: 4),
        ],
        title: Text(
          'Reports & Scans',
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
                        icon: Icons.science_rounded,
                        title: 'No lab tests scheduled',
                        message:
                            'Register your pregnancy and we will lay out every '
                            'blood test, urine test and scan month by month.',
                        onRegistered: _load,
                      )
                    else ...[
                      for (final month in _months)
                        ..._monthGroup(month, p),
                      const SizedBox(height: 14),
                      CareFooterNote(
                        icon: Icons.description_outlined,
                        title: 'Upload any report (image or PDF).',
                        subtitle: "We'll identify and organize it for you.",
                        accent: const Color(0xFF7C5CFC),
                        lightBackground: const Color(0xFFF3EFFF),
                        onTap: _uploadAny,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  /// The tests in the order of the clinical plan, each with the checklist row
  /// that tracks it, if one was synced.
  ///
  /// The list on screen is the plan itself, so it always shows every test due
  /// that month under the name the plan gives it. The rows only say whether a
  /// result has been uploaded.
  List<_Entry> get _entries {
    final unused = [..._reports];
    PregnancyReportChecklist? take(bool Function(PregnancyReportChecklist) f) {
      for (final r in unused) {
        if (f(r)) {
          unused.remove(r);
          return r;
        }
      }
      return null;
    }

    return [
      for (final plan in reportSchedule)
        _Entry(
          plan,
          // The same name first; failing that, the same test without its
          // "3rd Month" prefix in the same month.
          take((r) => _norm(r.reportName) == _norm(plan.name)) ??
              take(
                (r) =>
                    _norm(_stripMonth(r.reportName)) ==
                        _norm(_stripMonth(plan.name)) &&
                    _rowMonth(r) == plan.month,
              ),
        ),
    ];
  }

  static final _monthPrefix = RegExp(
    r'^(\d{1,2})(?:st|nd|rd|th)\s+Month\s+',
    caseSensitive: false,
  );

  static String _norm(String s) => s.trim().toLowerCase();

  static String _stripMonth(String s) =>
      s.trim().replaceFirst(_monthPrefix, '');

  static int? _rowMonth(PregnancyReportChecklist r) {
    final m = _monthPrefix.firstMatch(r.reportName.trim());
    return m != null ? int.parse(m.group(1)!) : r.pregnancyMonth;
  }

  List<int> get _months =>
      reportSchedule.map((r) => r.month).toSet().toList()..sort();

  List<Widget> _monthGroup(int month, AppPalette p) {
    final entries = _entries.where((e) => e.plan.month == month).toList();
    if (entries.isEmpty) return const [];
    return [
      CareSectionLabel(
        monthLabel(month),
        color: p.pick(const Color(0xFF2F6FE4), const Color(0xFF6EA2FF)),
      ),
      for (final e in entries) ...[
        _reportCard(e, p),
        const SizedBox(height: 10),
      ],
    ];
  }

  Widget _reportCard(_Entry e, AppPalette p) {
    final row = e.row;
    final done = row?.isDone ?? false;
    return CareCard(
      onTap: () => done ? _openDetails(e) : _uploadResult(e),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Row(
        children: [
          CareMarkerIcon(
            marker: done ? CareMarker.done : CareMarker.later,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.plan.name,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: p.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.plan.purpose,
                  style: TextStyle(fontSize: 12, color: p.textSecondary),
                ),
                const SizedBox(height: 4),
                if (done)
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Uploaded',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (row!.completedDate != null)
                          TextSpan(
                            text: '  ${careDateFmt.format(row.completedDate!)}',
                            style: TextStyle(color: p.textMuted),
                          ),
                      ],
                    ),
                    style: const TextStyle(fontSize: 12),
                  )
                else
                  Text(
                    e.plan.isRequired
                        ? 'Not uploaded · Required'
                        : 'Not uploaded · Optional',
                    style: TextStyle(fontSize: 12, color: p.textMuted),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CareOutlineButton(
            label: done ? 'View' : 'Upload',
            radius: 8,
            onTap: () => done ? _openDetails(e) : _uploadResult(e),
          ),
        ],
      ),
    );
  }

  void _openDetails(_Entry e) {
    final row = e.row!;
    final status = CareStatus.resolve(status: row.status, date: row.dueDate);
    showCareDetailSheet(
      context,
      eyebrow: [
        ?_categoryLabel(e.plan.category),
        e.plan.isRequired ? 'Required' : 'Optional',
      ].join(' · '),
      title: e.plan.name,
      status: status,
      statusLabel: status.isDone ? 'Uploaded' : null,
      facts: [
        (Icons.info_outline_rounded, e.plan.purpose),
        (Icons.calendar_view_month_rounded, monthLabel(e.plan.month)),
        if (row.dueDate != null)
          (Icons.event_rounded, 'Due ${careDateFmt.format(row.dueDate!)}'),
        if (row.completedDate != null)
          (
            Icons.cloud_done_rounded,
            'Uploaded ${careDateFmt.format(row.completedDate!)}',
          ),
      ],
      primaryLabel: 'Upload again',
      primaryIcon: Icons.upload_file_rounded,
      onPrimary: () => _uploadResult(e),
      secondaryLabel: 'Mark as not uploaded',
      secondaryIcon: Icons.undo_rounded,
      onSecondary: () => _toggleDone(row),
    );
  }

  /// A report that is not on the checklist — filed with her other reports.
  Future<void> _uploadAny() async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const AddReport()),
    );
    if (added == true) await _load();
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ctx.palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Reports & scans',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Every test and scan for your pregnancy, month by month. Upload the '
          'result when you get it and the test is ticked off.',
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

  /// The stored category as something readable — the table shows it under the
  /// test name, where the card used to show it as an icon.
  static String? _categoryLabel(String? category) => switch (category) {
    'blood' => 'Blood test',
    'urine' => 'Urine test',
    'screening' => 'Screening',
    'monitoring' => 'Monitoring',
    _ => null,
  };
}

/// One test from the plan, with the checklist row tracking it if there is one.
class _Entry {
  const _Entry(this.plan, this.row);

  final ScheduledReport plan;
  final PregnancyReportChecklist? row;
}
