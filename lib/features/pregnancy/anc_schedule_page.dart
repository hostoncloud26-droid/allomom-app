import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/pregnancy_care_plan.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';

/// The ANC visits booked locally when the pregnancy was registered.
class AncSchedulePage extends StatefulWidget {
  const AncSchedulePage({super.key});

  @override
  State<AncSchedulePage> createState() => _AncSchedulePageState();
}

class _AncSchedulePageState extends State<AncSchedulePage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  int _trimesterFilter = 0; // 0: All, 1..3: trimester
  bool _isLoading = true;
  String? _pregnancyId;
  List<PregnancyAncScheduleData> _visits = const [];

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

      final visits = pregnancy == null
          ? const <PregnancyAncScheduleData>[]
          : await PregnancyCareDbService.instance.getAncVisits(pregnancy.id);

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _visits = visits;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading ANC schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(PregnancyAncScheduleData visit) async {
    final wasDone = visit.status == 'done';
    try {
      await PregnancyCareDbService.instance.updateAncVisit(
        PregnancyAncScheduleCompanion(
          id: Value(visit.id),
          status: Value(wasDone ? 'pending' : 'done'),
          actualDate: Value(wasDone ? null : DateTime.now()),
        ),
      );
      await _load();
    } catch (e) {
      debugPrint('Error updating ANC visit ${visit.id}: $e');
    }
  }

  List<PregnancyAncScheduleData> get _filtered => _trimesterFilter == 0
      ? _visits
      : _visits.where((v) => v.trimester == _trimesterFilter).toList();

  int get _doneCount => _visits.where((v) => v.status == 'done').length;

  @override
  Widget build(BuildContext context) {
    final week = UserSessionManager.instance.currentGestationalWeek;

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
          'ANC Schedule',
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
                          "Am $week weeks, Amma! 💕\nLet's check our doctor visits.",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 270,
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
                      CareProgressHeader(
                        done: _doneCount,
                        total: _visits.length,
                        label: 'ANC check-ups',
                      ),
                      const SizedBox(height: 14),
                      CareFilterTabs(
                        labels: [
                          'All (${_visits.length})',
                          'Tri 1',
                          'Tri 2',
                          'Tri 3',
                        ],
                        selected: _trimesterFilter,
                        onSelected: (i) => setState(() => _trimesterFilter = i),
                      ),
                      const SizedBox(height: 14),
                      if (_filtered.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Text(
                            'No visits in this trimester.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        )
                      else
                        for (final visit in _filtered) ...[
                          _buildVisitCard(visit),
                          const SizedBox(height: 14),
                        ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVisitCard(PregnancyAncScheduleData visit) {
    final status = CareStatus.resolve(
      status: visit.status,
      date: visit.scheduledDate,
    );
    final month = visit.pregnancyMonth;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: status.needsAttention ? status.color : const Color(0xFFF0F1F5),
          width: status.needsAttention ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: status.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  '${visit.visitNumber}',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: status.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANC Visit ${visit.visitNumber}',
                      style: GoogleFonts.outfit(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    Text(
                      [
                        if (month != null) monthLabel(month),
                        if (visit.trimester != null)
                          'Trimester ${visit.trimester}',
                      ].join(' · '),
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              CareStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 14),

          _DetailRow(
            icon: Icons.event_rounded,
            label: 'Scheduled',
            value: _dateFmt.format(visit.scheduledDate),
          ),
          if (visit.actualDate != null)
            _DetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Attended',
              value: _dateFmt.format(visit.actualDate!),
            ),
          if (visit.bp != null)
            _DetailRow(
              icon: Icons.monitor_heart_outlined,
              label: 'Blood pressure',
              value: visit.bp!,
            ),
          if (visit.weightKg != null)
            _DetailRow(
              icon: Icons.monitor_weight_outlined,
              label: 'Weight',
              value: '${visit.weightKg} kg',
            ),
          if (visit.fetalHeartRate != null)
            _DetailRow(
              icon: Icons.favorite_outline_rounded,
              label: 'Fetal heart rate',
              value: '${visit.fetalHeartRate} bpm',
            ),

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _toggleDone(visit),
              icon: Icon(
                status.isDone
                    ? Icons.undo_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
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
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              label: Text(
                status.isDone ? 'Mark as pending' : 'Mark as attended',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
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

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1E2024),
            ),
          ),
        ],
      ),
    );
  }
}
