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

/// The maternal vaccine doses booked locally when the pregnancy was registered.
class VaccinationSchedulePage extends StatefulWidget {
  const VaccinationSchedulePage({super.key});

  @override
  State<VaccinationSchedulePage> createState() =>
      _VaccinationSchedulePageState();
}

class _VaccinationSchedulePageState extends State<VaccinationSchedulePage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');

  bool _isLoading = true;
  String? _pregnancyId;
  List<Vaccination> _vaccines = const [];

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

      final vaccines = pregnancy == null
          ? const <Vaccination>[]
          : await PregnancyCareDbService.instance.getVaccinations(
              session.userId,
              pregnancyId: pregnancy.id,
            );

      if (!mounted) return;
      setState(() {
        _pregnancyId = pregnancy?.id;
        _vaccines = vaccines;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vaccination schedule: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleDone(Vaccination vaccine) async {
    final wasDone = vaccine.status == 'done';
    try {
      await PregnancyCareDbService.instance.updateVaccination(
        VaccinationsCompanion(
          id: Value(vaccine.id),
          status: Value(wasDone ? 'pending' : 'done'),
          administeredDate: Value(wasDone ? null : DateTime.now()),
        ),
      );
      await _load();
    } catch (e) {
      debugPrint('Error updating vaccination ${vaccine.id}: $e');
    }
  }

  int get _doneCount => _vaccines.where((v) => v.status == 'done').length;

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
          'Vaccination Schedule',
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
                          "Am $week weeks, Amma! 💉\nOur vaccines keep us both safe.",
                      bubblePosition: SpeechBubblePosition.topCenter,
                      height: 270,
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
                      CareProgressHeader(
                        done: _doneCount,
                        total: _vaccines.length,
                        label: 'Maternal vaccines',
                      ),
                      const SizedBox(height: 14),
                      for (final vaccine in _vaccines) ...[
                        _buildVaccineCard(vaccine),
                        const SizedBox(height: 14),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildVaccineCard(Vaccination vaccine) {
    final status = CareStatus.resolve(
      status: vaccine.status,
      date: vaccine.scheduledDate,
    );
    final month = vaccine.pregnancyMonth;

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
                child: Icon(
                  Icons.vaccines_rounded,
                  size: 18,
                  color: status.color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccine.vaccineName,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                        height: 1.25,
                      ),
                    ),
                    Text(
                      [
                        'Dose ${vaccine.doseNumber}',
                        if (month != null) monthLabel(month),
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

          if (vaccine.notes != null && vaccine.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    size: 15,
                    color: Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vaccine.notes!,
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: const Color(0xFF475569),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          Row(
            children: [
              Icon(
                Icons.event_rounded,
                size: 15,
                color: const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Text(
                vaccine.administeredDate != null
                    ? 'Given ${_dateFmt.format(vaccine.administeredDate!)}'
                    : 'Due ${_dateFmt.format(vaccine.scheduledDate)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E2024),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton.icon(
              onPressed: () => _toggleDone(vaccine),
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
                status.isDone ? 'Mark as pending' : 'Mark as taken',
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
