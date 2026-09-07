import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/reports/add_report.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';

/// The lab tests and scans booked locally when the pregnancy was registered,
/// grouped by the pregnancy month they are due in.
class LabReportsSchedulePage extends StatefulWidget {
  const LabReportsSchedulePage({super.key});

  @override
  State<LabReportsSchedulePage> createState() => _LabReportsSchedulePageState();
}

class _LabReportsSchedulePageState extends State<LabReportsSchedulePage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  /// 0: All, 1: Pending, 2: Done
  int _filter = 0;

  bool _isLoading = true;
  String? _pregnancyId;
  List<ReportChecklist> _reports = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final session = UserSessionManager.instance;
      final healthId = session.healthDataId;
      final pregnancy = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      final reports = pregnancy == null
          ? const <ReportChecklist>[]
          : await PregnancyCareDbService.instance.getReportChecklists(
              session.userId,
              pregnancyId: pregnancy.id,
            );

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading lab report schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(ReportChecklist report) async {
    final wasDone = report.status == 'done';
    try {
      await PregnancyCareDbService.instance.updateReportChecklist(
        ReportChecklistsCompanion(
          id: Value(report.id),
          status: Value(wasDone ? 'pending' : 'done'),
          completedDate: Value(wasDone ? null : DateTime.now()),
        ),
      );
      await _load();
    } catch (e) {
      debugPrint('Error updating report checklist ${report.id}: $e');
    }
  }

  /// Opens the report uploader pre-tagged with this checklist entry, which
  /// closes the entry out once the file is saved.
  Future<void> _uploadResult(ReportChecklist report) async {
    final added = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AddReport(checklistId: report.id, checklistName: report.reportName),
      ),
    );
    if (added == true) await _load();
  }

  List<ReportChecklist> get _filtered => switch (_filter) {
    1 => _reports.where((r) => r.status != 'done').toList(),
    2 => _reports.where((r) => r.status == 'done').toList(),
    _ => _reports,
  };

  int get _doneCount => _reports.where((r) => r.status == 'done').length;

  /// Filtered rows bucketed by pregnancy month, months in order.
  Map<int, List<ReportChecklist>> get _byMonth {
    final grouped = <int, List<ReportChecklist>>{};
    for (final report in _filtered) {
      grouped.putIfAbsent(report.pregnancyMonth ?? 0, () => []).add(report);
    }
    return Map.fromEntries(
      grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final week = UserSessionManager.instance.currentGestationalWeek;
    final grouped = _byMonth;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1E2024),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Lab Tests & Scans',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
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
                      speechText:
                          "Am $week weeks, Amma! 🧪\nLet's keep our tests on track.",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 270,
                      greetingText: '',
                    ),
                    const SizedBox(height: 16),

                    if (_pregnancyId == null || _reports.isEmpty)
                      CareScheduleEmpty(
                        icon: Icons.science_rounded,
                        title: 'No lab tests scheduled',
                        message:
                            'Register your pregnancy and we will lay out every '
                            'blood test, urine test and scan month by month.',
                        onRegistered: _load,
                      )
                    else ...[
                      CareProgressHeader(
                        done: _doneCount,
                        total: _reports.length,
                        label: 'Antenatal investigations',
                      ),
                      const SizedBox(height: 14),
                      CareFilterTabs(
                        labels: [
                          'All (${_reports.length})',
                          'Pending (${_reports.length - _doneCount})',
                          'Done ($_doneCount)',
                        ],
                        selected: _filter,
                        onSelected: (i) => setState(() => _filter = i),
                      ),
                      const SizedBox(height: 16),
                      if (grouped.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'Nothing here yet.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        for (final entry in grouped.entries) ...[
                          _buildMonthHeader(entry.key, entry.value),
                          const SizedBox(height: 10),
                          for (final report in entry.value) ...[
                            _buildReportCard(report),
                            const SizedBox(height: 10),
                          ],
                          const SizedBox(height: 8),
                        ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMonthHeader(int month, List<ReportChecklist> reports) {
    final due = reports.first.dueDate;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFEDF6FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            month == 0 ? 'Unscheduled' : monthLabel(month),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF3898EC),
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (due != null)
          Text(
            _dateFmt.format(due),
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
            ),
          ),
        const Spacer(),
        Text(
          '${reports.length} test${reports.length == 1 ? '' : 's'}',
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }

  Widget _buildReportCard(ReportChecklist report) {
    final status = CareStatus.resolve(
      status: report.status,
      date: report.dueDate,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: status.needsAttention ? status.color : const Color(0xFFF0F1F5),
          width: status.needsAttention ? 1.6 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconForCategory(report.category),
                  size: 16,
                  color: status.color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            report.reportName,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E2024),
                              height: 1.25,
                            ),
                          ),
                        ),
                        if (!report.isRequired) ...[
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
                              'Optional',
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
                    if (report.notes != null && report.notes!.isNotEmpty)
                      Text(
                        report.notes!,
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                          height: 1.35,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CareStatusChip(status: status),
            ],
          ),

          if (report.completedDate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 14,
                  color: Color(0xFF10B981),
                ),
                const SizedBox(width: 6),
                Text(
                  'Done ${_dateFmt.format(report.completedDate!)}',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: OutlinedButton(
                    onPressed: () => _toggleDone(report),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: status.isDone
                          ? const Color(0xFF6B7280)
                          : const Color(0xFF10B981),
                      side: BorderSide(
                        color: status.isDone
                            ? const Color(0xFFE5E7EB)
                            : const Color(0xFF10B981),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      status.isDone ? 'Undo' : 'Mark done',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _uploadResult(report),
                    icon: const Icon(Icons.upload_file_rounded, size: 15),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3898EC),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    label: Text(
                      'Add result',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconForCategory(String? category) => switch (category) {
    'blood' => Icons.bloodtype_outlined,
    'urine' => Icons.science_outlined,
    'screening' => Icons.health_and_safety_outlined,
    'monitoring' => Icons.monitor_heart_outlined,
    _ => Icons.description_outlined,
  };
}
