import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/features/baby/baby_detail_page.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class PregnancyJourneyPage extends StatefulWidget {
  const PregnancyJourneyPage({super.key});

  @override
  State<PregnancyJourneyPage> createState() => _PregnancyJourneyPageState();
}

class _PregnancyJourneyPageState extends State<PregnancyJourneyPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _shortDateFmt = DateFormat('dd MMM');

  bool _isLoading = true;
  bool _isPregnant = false;
  Map<String, dynamic>? _pregnancyInfo;
  List<Map<String, dynamic>> _completedPregnancies = [];
  List<BirthRecord> _babies = [];

  /// The baby whose schedule the postpartum view is showing. Null until the
  /// first load, then the newest baby unless the mother picks another.
  String? _selectedBabyId;
  List<BabyImmunizationRecord> _selectedBabyDoses = [];
  List<BabyMilestone> _selectedBabyMilestones = [];

  BirthRecord? get _selectedBaby => _babies
      .cast<BirthRecord?>()
      .firstWhere((b) => b?.id == _selectedBabyId, orElse: () => null);

  @override
  void initState() {
    super.initState();
    _loadAllPregnancyData();
  }

  /// Loads the active pregnancy and past records from the local Drift
  /// database, deriving the gestation figures the API used to return.
  Future<void> _loadAllPregnancyData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final session = UserSessionManager.instance;
      await session.refresh();
      _babies = await BabyRepository.instance.getBabies();
      await _loadSelectedBabySchedule();

      final healthId = session.healthDataId;
      final active = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      Map<String, dynamic>? info;
      if (active != null) {
        final lmp = active.lmpDate;
        final edd = active.edDate ?? lmp?.add(const Duration(days: 280));
        final now = DateTime.now();
        final daysElapsed = lmp == null ? 0 : now.difference(lmp).inDays;
        final weeks = daysElapsed <= 0 ? 1 : (daysElapsed ~/ 7) + 1;
        final trimester = weeks <= 12 ? 1 : (weeks <= 26 ? 2 : 3);

        info = {
          'id': active.id,
          'status': active.status,
          'lmpDate': lmp?.toIso8601String(),
          'estimatedDueDate': edd?.toIso8601String(),
          'gestationAgeWeeks': weeks.clamp(1, 42),
          'trimesters': trimester,
          'daysRemaining': edd == null
              ? 0
              : edd.difference(now).inDays.clamp(0, 280),
          'riskStatus': active.riskStatus,
          'gravidity': active.gravidity,
          'parity': active.parity,
        };
      }

      final completedRows = await HealthDbService.instance
          .getCompletedPregnancies(healthId.isEmpty ? null : healthId);
      final completed = completedRows
          .map(
            (p) => {
              'id': p.id,
              'status': p.status,
              'lmpDate': p.lmpDate?.toIso8601String(),
              'edDate': p.edDate?.toIso8601String(),
              'deliveryDate': p.deliveryDate?.toIso8601String(),
              'completedAt': p.completedAt?.toIso8601String(),
              'csectionDeliveries': p.csectionDeliveries,
              'deliveryConductedAt': p.deliveryConductedAt,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _pregnancyInfo = info;
          _isPregnant = active != null && active.status == 'active';
          _completedPregnancies = completed;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading pregnancy data from local database: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatEdd(String? isoString) {
    if (isoString == null || isoString.isEmpty) return '--';
    try {
      final dt = DateTime.parse(isoString);
      return _shortDateFmt.format(dt);
    } catch (_) {
      return '--';
    }
  }

  @override
  Widget build(BuildContext context) {
    final week = _pregnancyInfo?['gestationAgeWeeks'] as int? ?? 1;
    final trimesters = _pregnancyInfo?['trimesters'] as int? ?? 1;
    final trimesterText = 'Trimester $trimesters';
    final daysLeft = _pregnancyInfo?['daysRemaining'] as int? ?? 0;
    final eddFormatted = _formatEdd(
      _pregnancyInfo?['estimatedDueDate'] as String?,
    );
    final progressFraction = (week / 40.0).clamp(0.0, 1.0);
    final progressPercent = (progressFraction * 100).toInt();

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
          !_isPregnant && _babies.isNotEmpty
              ? 'My Baby Journey'
              : 'My Pregnancy Journey',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'ANC Schedule',
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Color(0xFFFF3B5C),
              size: 22,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AncSchedulePage()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert_rounded,
              color: Color(0xFF1E2024),
              size: 22,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) async {
              switch (val) {
                case 'anc':
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AncSchedulePage()),
                  );
                  break;
                case 'vaccine':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VaccinationSchedulePage(),
                    ),
                  );
                  break;
                case 'labs':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LabReportsSchedulePage(),
                    ),
                  );
                  break;
                case 'register':
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PregnancyConfirmationPage(),
                    ),
                  );
                  if (created == true) _loadAllPregnancyData();
                  break;
                case 'complete':
                  _showCompletePregnancyModal(context);
                  break;
                case 'delete':
                  _showDeletePregnancyDialog(context);
                  break;
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'anc',
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: Color(0xFFFF3B5C),
                    ),
                    SizedBox(width: 10),
                    Text('ANC Schedule'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'vaccine',
                child: Row(
                  children: [
                    Icon(
                      Icons.vaccines_rounded,
                      size: 18,
                      color: Color(0xFF8B5CF6),
                    ),
                    SizedBox(width: 10),
                    Text('Vaccination Schedule'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'labs',
                child: Row(
                  children: [
                    Icon(
                      Icons.science_rounded,
                      size: 18,
                      color: Color(0xFF3898EC),
                    ),
                    SizedBox(width: 10),
                    Text('Lab Reports & Scans'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              if (_isPregnant) ...[
                const PopupMenuItem(
                  value: 'complete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFF10B981),
                      ),
                      SizedBox(width: 10),
                      Text('Complete Pregnancy'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Color(0xFFEF4444),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Delete Pregnancy Card',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                const PopupMenuItem(
                  value: 'register',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                        color: Color(0xFFFF3B5C),
                      ),
                      SizedBox(width: 10),
                      Text('Register Pregnancy'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFFF3B5C)),
              )
            : RefreshIndicator(
                color: const Color(0xFFFF3B5C),
                onRefresh: _loadAllPregnancyData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: _isPregnant
                      ? _buildActivePregnancyView(
                          context: context,
                          gestationalWeek: week,
                          trimester: trimesterText,
                          daysLeft: daysLeft,
                          eddFormatted: eddFormatted,
                          progressFraction: progressFraction,
                          progressPercent: progressPercent,
                        )
                      : _babies.isNotEmpty
                      ? _buildBabyJourneyView(context)
                      : _buildUnregisteredPregnancyView(context),
                ),
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIVE PREGNANCY VIEW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildActivePregnancyView({
    required BuildContext context,
    required int gestationalWeek,
    required String trimester,
    required int daysLeft,
    required String eddFormatted,
    required double progressFraction,
    required int progressPercent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── BABY HERO CARD ───
        BabyHeroBanner(
          speechText:
              "Am $gestationalWeek weeks, Amma! 💕\nWe're growing so strong together.",
          bubblePosition: SpeechBubblePosition.topCenter,
          height: 270,
          greetingText: "",
        ),
        const SizedBox(height: 18),

        // ─── PREGNANCY INFO SECTION CARD ───
        _buildPregnancyInfoCard(
          context: context,
          gestationalWeek: gestationalWeek,
          trimester: trimester,
          daysLeft: daysLeft,
          eddFormatted: eddFormatted,
          progressFraction: progressFraction,
          progressPercent: progressPercent,
        ),
        const SizedBox(height: 16),

        // ─── UPCOMING CARE & SCHEDULE SECTION CARD ───
        _buildUpcomingScheduleCard(context),
        const SizedBox(height: 20),

        // ─── MY BABIES SECTION ───
        _buildMyBabiesSection(),
        const SizedBox(height: 20),

        // ─── COMPLETE PREGNANCY SECTION ───
        _buildCompletePregnancySection(context),
        const SizedBox(height: 20),

        // ─── DELETE PREGNANCY CARD SECTION ───
        _buildDeletePregnancyCardSection(context),
        const SizedBox(height: 24),

        // ─── COMPLETED PREGNANCIES HISTORY (IF ANY) ───
        if (_completedPregnancies.isNotEmpty) ...[
          _buildCompletedPregnanciesSection(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UNREGISTERED PREGNANCY VIEW (REGISTER PREGNANCY FLOW)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUnregisteredPregnancyView(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ─── REGISTER PREGNANCY HERO CARD ───
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F4), Color(0xFFFFFAFB), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFDCE4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
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
                        color: Color(0xFFFF3B5C),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                'Start Your Pregnancy Journey',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your LMP date to unlock week-by-week baby development, doctor visit schedules, vaccination reminders, and daily care tracking.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: const Color(0xFF6B7280),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),

              // REGISTER PREGNANCY CTA BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final created = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PregnancyConfirmationPage(),
                      ),
                    );
                    if (created == true) {
                      _loadAllPregnancyData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B5C),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: const Color(
                      0xFFFF3B5C,
                    ).withValues(alpha: 0.35),
                  ),
                  icon: const Icon(
                    Icons.favorite_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: Text(
                    'Register Pregnancy',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ─── WHY REGISTER SECTION ───
        Text(
          'WHAT YOU GET',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: const Color(0xFF8E95A5),
          ),
        ),
        const SizedBox(height: 12),

        _buildBenefitTile(
          icon: Icons.auto_graph_rounded,
          iconBg: const Color(0xFFFFF0F4),
          iconColor: const Color(0xFFFF3B5C),
          title: 'Weekly Baby Growth Milestones',
          subtitle:
              'Track your baby’s size, weight, and key developments from week 1 to 40.',
        ),
        const SizedBox(height: 10),
        _buildBenefitTile(
          icon: Icons.calendar_today_rounded,
          iconBg: const Color(0xFFEDF6FF),
          iconColor: const Color(0xFF3898EC),
          title: 'Doctor & ANC Schedules',
          subtitle:
              'Automated trimester antenatal checkup planner and reminder schedules.',
        ),
        const SizedBox(height: 10),
        _buildBenefitTile(
          icon: Icons.vaccines_rounded,
          iconBg: const Color(0xFFF3E8FF),
          iconColor: const Color(0xFF8B5CF6),
          title: 'Maternal Vaccinations',
          subtitle:
              'Never miss TT-1, TT-2, Tdap, and seasonal influenza protective doses.',
        ),
        const SizedBox(height: 10),
        _buildBenefitTile(
          icon: Icons.science_rounded,
          iconBg: const Color(0xFFECFDF5),
          iconColor: const Color(0xFF10B981),
          title: 'Lab Reports & Scans',
          subtitle:
              'Keep all ultrasound sonographies, glucose tests, and blood counts organized.',
        ),
        const SizedBox(height: 24),

        // ─── COMPLETED PREGNANCIES HISTORY (IF ANY) ───
        _buildMyBabiesSection(),
        const SizedBox(height: 20),

        if (_completedPregnancies.isNotEmpty) ...[
          _buildCompletedPregnanciesSection(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _buildBenefitTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0F1F5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PREGNANCY INFO CARD (WITH EDIT & DELETE ACTIONS)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildPregnancyInfoCard({
    required BuildContext context,
    required int gestationalWeek,
    required String trimester,
    required int daysLeft,
    required String eddFormatted,
    required double progressFraction,
    required int progressPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'PREGNANCY INFO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trimester,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B5C),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _showDeletePregnancyDialog(context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        size: 14,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Week Title & Edit Timeline Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week $gestationalWeek of 40',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PregnancyConfirmationPage(),
                    ),
                  );
                  if (created == true) _loadAllPregnancyData();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.edit_calendar_rounded,
                        size: 12,
                        color: Color(0xFF4B5563),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change LMP',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFFFE6ED),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFFF3B5C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Metric Stat Chips
          Row(
            children: [
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFFFF0F4),
                  icon: Icons.event_available_rounded,
                  iconColor: const Color(0xFFFF4E6A),
                  value: eddFormatted,
                  label: 'Due Date',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFEDF6FF),
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: const Color(0xFF3898EC),
                  value: '$daysLeft',
                  label: 'Days Left',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFF3E8FF),
                  icon: Icons.child_care_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  value: 'W $gestationalWeek',
                  label: 'Week',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMetricChip({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A90A0),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPCOMING SCHEDULE SECTION CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildUpcomingScheduleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'UPCOMING SCHEDULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                'Next 30 Days',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildScheduleRow(
            icon: Icons.medical_services_rounded,
            iconBg: const Color(0xFFFFF0F4),
            iconColor: const Color(0xFFFF3B5C),
            title: 'Doctor Appointment',
            date: '12 Sep 2026 · 10:30 AM',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AncSchedulePage()),
              );
            },
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 20, thickness: 1),
          _buildScheduleRow(
            icon: Icons.vaccines_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Tetanus Toxoid (TT-2)',
            date: '18 Sep 2026',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const VaccinationSchedulePage(),
                ),
              );
            },
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 20, thickness: 1),
          _buildScheduleRow(
            icon: Icons.science_rounded,
            iconBg: const Color(0xFFEDF6FF),
            iconColor: const Color(0xFF3898EC),
            title: 'Glucose (75g OGTT) & Hemoglobin',
            date: '25 Sep 2026 · 8:00 AM',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LabReportsSchedulePage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Center(child: Icon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFFBDC3CE),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETE PREGNANCY SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletePregnancySection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_roseSoft, Color(0xFFFFF7F9), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _roseBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _rose.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: _rose,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.celebration_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'COMPLETE PREGNANCY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFD11742),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _roseSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Delivered ✨',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFD11742),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Delivered your little one? 👶🎉',
            style: GoogleFonts.outfit(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Celebrate your delivery! Mark this pregnancy journey as completed to record birth milestones and transition to newborn care.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF4B5563),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              onPressed: () => _showCompletePregnancyModal(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: _rose,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(
                Icons.check_circle_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Complete Pregnancy Journey',
                style: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DELETE PREGNANCY CARD SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildDeletePregnancyCardSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFEE2E2), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delete Pregnancy Card',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Remove this record and reset timeline',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showDeletePregnancyDialog(context),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETED PREGNANCIES HISTORY SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCompletedPregnanciesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.history_edu_rounded,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              'PAST PREGNANCY JOURNEYS (${_completedPregnancies.length})',
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ..._completedPregnancies.map((p) => _buildCompletedPregnancyCard(p)),
      ],
    );
  }

  Widget _buildCompletedPregnancyCard(Map<String, dynamic> p) {
    final delivStr = p['deliveryDate'] ?? p['completedAt'];
    String formattedDeliv = 'Delivered';
    if (delivStr != null) {
      try {
        formattedDeliv = _dateFmt.format(DateTime.parse(delivStr.toString()));
      } catch (_) {}
    }

    final lmpStr = p['lmpDate'];
    String formattedLmp = '—';
    if (lmpStr != null) {
      try {
        formattedLmp = _dateFmt.format(DateTime.parse(lmpStr.toString()));
      } catch (_) {}
    }

    final isCsec = (p['csectionDeliveries'] as int? ?? 0) > 0;
    final hospital = p['deliveryConductedAt']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Color(0xFF10B981),
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Journey Completed',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCsec ? 'C-Section' : 'Delivered',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDeliv,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'LMP Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9CA3AF),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedLmp,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                  ],
                ),
              ),
              if (hospital.isNotEmpty)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hospital',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E2024),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MODALS & DIALOGS (COMPLETE & DELETE)
  // ═══════════════════════════════════════════════════════════════════════════

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPLETE PREGNANCY (DELIVERY) MODAL
  // ═══════════════════════════════════════════════════════════════════════════

  static const _rose = Color(0xFFFF3B5C);
  static const _roseSoft = Color(0xFFFFF0F4);
  static const _roseBorder = Color(0xFFFFD3DC);

  void _showCompletePregnancyModal(BuildContext context) {
    final pregId = _pregnancyInfo?['id']?.toString();
    if (pregId == null || pregId.isEmpty) return;

    DateTime deliveryDate = DateTime.now();
    String deliveryType = 'Normal Delivery';
    String babyGender = 'Baby Boy 👦';
    String? babyPhotoPath;
    final weightController = TextEditingController();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isTwins = babyGender.startsWith('Twins');

          return Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 14,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EAEF),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── HEADER ───
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: _roseSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.celebration_rounded,
                          color: _rose,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome your baby',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E2024),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'A few details to complete your journey 🎉',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: const Color(0xFF8E95A5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ─── BABY PHOTO ───
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: () async {
                            final path = await _pickBabyPhoto();
                            if (path != null) {
                              setModalState(() => babyPhotoPath = path);
                            }
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _roseSoft,
                                  border: Border.all(
                                    color: _roseBorder,
                                    width: 2,
                                  ),
                                  image: babyPhotoPath == null
                                      ? null
                                      : DecorationImage(
                                          image: FileImage(
                                            File(babyPhotoPath!),
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                child: babyPhotoPath != null
                                    ? null
                                    : const Icon(
                                        Icons.child_care_rounded,
                                        size: 40,
                                        color: Color(0xFFFF9DB1),
                                      ),
                              ),
                              Positioned(
                                right: -2,
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _rose,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: Icon(
                                    babyPhotoPath == null
                                        ? Icons.add_a_photo_rounded
                                        : Icons.edit_rounded,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          babyPhotoPath == null
                              ? 'Add first photo'
                              : 'Tap to change',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _rose,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── DELIVERY DATE ───
                  _modalLabel('DELIVERY DATE'),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: deliveryDate,
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 90),
                        ),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setModalState(() => deliveryDate = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: _roseSoft,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_available_rounded,
                            size: 19,
                            color: _rose,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _dateFmt.format(deliveryDate),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Change',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: _rose,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ─── DELIVERY TYPE ───
                  _modalLabel('DELIVERY TYPE'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Normal Delivery', 'Cesarean (C-Section)', 'Assisted']
                        .map(
                          (type) => _choiceChip(
                            label: type,
                            selected: deliveryType == type,
                            onTap: () =>
                                setModalState(() => deliveryType = type),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // ─── BABY ───
                  _modalLabel('BABY'),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['Baby Boy 👦', 'Baby Girl 👧', 'Twins 👶👶']
                        .map(
                          (gender) => _choiceChip(
                            label: gender,
                            selected: babyGender == gender,
                            onTap: () =>
                                setModalState(() => babyGender = gender),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 20),

                  // ─── BIRTH WEIGHT ───
                  _modalLabel('BIRTH WEIGHT'),
                  TextField(
                    controller: weightController,
                    // Twins would need one weight each, and this form has room
                    // for a single number, so it is skipped for them entirely
                    // rather than recorded against the wrong baby.
                    enabled: !isTwins,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E2024),
                    ),
                    decoration: InputDecoration(
                      hintText: isTwins ? 'Add for each baby later' : '3.2',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: const Color(0xFFB6BAC5),
                      ),
                      prefixIcon: const Icon(
                        Icons.monitor_weight_rounded,
                        size: 19,
                        color: _rose,
                      ),
                      suffixText: isTwins ? null : 'kg',
                      suffixStyle: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF8E95A5),
                      ),
                      filled: true,
                      fillColor: isTwins
                          ? const Color(0xFFF6F7FA)
                          : _roseSoft,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: _rose, width: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ─── WHAT HAPPENS NEXT ───
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: Color(0xFFB6BAC5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isTwins
                                ? "We'll add both babies with their own "
                                      'vaccination schedule and milestones.'
                                : "We'll set up your baby's vaccination "
                                      'schedule and milestones from this date.',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              height: 1.45,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ─── SUBMIT ───
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setModalState(() => isSubmitting = true);

                              try {
                                // Local-only: written to SQLite with synced = 0.
                                await HealthDbService.instance
                                    .completePregnancy(
                                      pregId,
                                      deliveryDate: deliveryDate,
                                    );

                                // The delivery produces the baby: a birth
                                // record linked to this pregnancy, with its
                                // own health record and a vaccination and
                                // milestone schedule anchored on the DOB.
                                final babyIds = await BabyRepository.instance
                                    .recordBirthsForPregnancy(
                                      pregnancyId: pregId,
                                      deliveryDate: deliveryDate,
                                      gender: _genderValueFor(babyGender),
                                      deliveryType: _deliveryTypeValueFor(
                                        deliveryType,
                                      ),
                                      weight: double.tryParse(
                                        weightController.text.trim(),
                                      ),
                                      photo: babyPhotoPath,
                                      babyCount: _babyCountFor(babyGender),
                                    );

                                // She is no longer pregnant. 'new_mom' is a
                                // non-pregnant status that also tells the app
                                // she is postpartum rather than never-pregnant.
                                await UserSessionManager.instance
                                    .setPregnancyStatus('new_mom');
                                await _loadAllPregnancyData();

                                if (context.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        babyIds.length > 1
                                            ? 'Congratulations Amma! ${babyIds.length} babies added to your family! 👶👶🎉'
                                            : 'Congratulations Amma! Baby added to your family! 👶🎉',
                                      ),
                                      backgroundColor: _rose,
                                      behavior: SnackBarBehavior.floating,
                                      action: SnackBarAction(
                                        label: 'Add details',
                                        textColor: Colors.white,
                                        onPressed: _openMyBabies,
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint(
                                  'Error completing pregnancy $pregId: $e',
                                );
                                setModalState(() => isSubmitting = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Failed to complete pregnancy',
                                      ),
                                      backgroundColor: Color(0xFFEF4444),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _rose,
                        disabledBackgroundColor: _roseBorder,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Complete Journey',
                              style: GoogleFonts.outfit(
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _modalLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
        color: const Color(0xFF8E95A5),
      ),
    ),
  );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? _rose : _roseSoft,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected ? _rose : _roseBorder,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xFF6B707B),
          ),
        ),
      ),
    );
  }

  /// Lets the mother snap or choose the baby's first photo.
  ///
  /// Resolves the local file path, or null if she backed out. The path is
  /// stored as-is in `birth_records.photo`; nothing is uploaded.
  Future<String?> _pickBabyPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EAEF),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                "Baby's first photo",
                style: GoogleFonts.outfit(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _photoSourceTile(
                      icon: Icons.photo_camera_rounded,
                      label: 'Camera',
                      onTap: () =>
                          Navigator.pop(sheetCtx, ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _photoSourceTile(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      onTap: () =>
                          Navigator.pop(sheetCtx, ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (source == null) return null;

    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1440,
      );
      return picked?.path;
    } catch (e) {
      debugPrint('Error picking baby photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add photo: $e')),
        );
      }
      return null;
    }
  }

  Widget _photoSourceTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _roseSoft,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _roseBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 26, color: _rose),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BABY JOURNEY VIEW (delivered — no active pregnancy, but a baby exists)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Loads the schedule for the currently selected baby.
  ///
  /// Falls back to the newest baby whenever the selection is gone — deleted,
  /// or never made because this is the first load.
  Future<void> _loadSelectedBabySchedule() async {
    if (_babies.isEmpty) {
      _selectedBabyId = null;
      _selectedBabyDoses = [];
      _selectedBabyMilestones = [];
      return;
    }

    if (!_babies.any((b) => b.id == _selectedBabyId)) {
      _selectedBabyId = _babies.first.id;
    }

    final babyId = _selectedBabyId!;
    _selectedBabyDoses = await BabyDbService.instance.getImmunizations(babyId);
    _selectedBabyMilestones = await BabyDbService.instance.getMilestones(
      babyId,
    );
  }

  /// The next dose that has not been given, or null once all are done.
  BabyImmunizationRecord? get _nextDose {
    for (final dose in _selectedBabyDoses) {
      if (dose.vaccinationDate == null) return dose;
    }
    return null;
  }

  /// The next milestone not yet ticked off, or null once all are.
  BabyMilestone? get _nextMilestone {
    for (final milestone in _selectedBabyMilestones) {
      if (!milestone.achieved) return milestone;
    }
    return null;
  }

  Future<void> _openBabyDetail({int tab = 0}) async {
    final babyId = _selectedBabyId;
    if (babyId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BabyDetailPage(birthRecordId: babyId, initialTab: tab),
      ),
    );
    if (mounted) await _loadAllPregnancyData();
  }

  Widget _buildBabyJourneyView(BuildContext context) {
    final baby = _selectedBaby;
    if (baby == null) return _buildUnregisteredPregnancyView(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ─── BABY SWITCHER (only when there is more than one) ───
        if (_babies.length > 1) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _babies.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final b = _babies[i];
                return _choiceChip(
                  label: b.babyName ?? 'Baby ${i + 1}',
                  selected: b.id == _selectedBabyId,
                  onTap: () async {
                    setState(() => _selectedBabyId = b.id);
                    await _loadSelectedBabySchedule();
                    if (mounted) setState(() {});
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // ─── BABY HERO CARD ───
        // The same banner the home screen and the pregnant view lead with, so
        // the journey looks like one story either side of the birth. The baby
        // does the talking here, as she does on home.
        BabyHeroBanner(
          speechText: _babyBannerText(baby),
          bubblePosition: SpeechBubblePosition.topCenter,
          height: 270,
          greetingText: "",
          onTap: () => _openBabyDetail(),
        ),
        const SizedBox(height: 18),

        // ─── BABY INFO SECTION CARD ───
        _buildBabyInfoCard(baby),
        const SizedBox(height: 16),

        // ─── CARE SCHEDULE ───
        _buildBabyScheduleCard(),
        const SizedBox(height: 20),

        // ─── MY BABIES ───
        _buildMyBabiesSection(),
        const SizedBox(height: 20),

        // ─── START A NEW PREGNANCY ───
        _buildNewPregnancyPrompt(context),
        const SizedBox(height: 24),

        if (_completedPregnancies.isNotEmpty) ...[
          _buildCompletedPregnanciesSection(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// What the baby says from the banner.
  ///
  /// First person, like the pregnant view's "Am 24 weeks, Amma!" — same voice,
  /// the other side of the birth.
  String _babyBannerText(BirthRecord baby) {
    final name = baby.babyName?.trim() ?? '';
    if (baby.dob == null) {
      return "Hi Amma! 💕\nAdd my birthday and I will show you my schedule.";
    }

    final age = babyAgeLabel(baby.dob);
    final opener = age == 'Newborn' ? "Am here, Amma! 💕" : "Am $age old, Amma! 💕";
    return name.isEmpty
        ? "$opener\nGrowing a little more every day."
        : "$opener\nThank you for looking after me.";
  }

  /// Name, age and how far through the schedule they are.
  ///
  /// Styled as the pregnancy info card is, and sits under the banner in the
  /// same place: the banner is the picture, this is the record.
  Widget _buildBabyInfoCard(BirthRecord baby) {
    final photo = baby.photo;
    final hasPhoto = photo != null && photo.isNotEmpty && File(photo).existsSync();
    final gender = baby.gender;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.child_care_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'BABY INFO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (gender != null && gender.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        labelForGender(gender),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF3B5C),
                        ),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _editBaby(baby),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: Color(0xFF4B5563),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Photo, name and age. The photo is the one thing the banner cannot
          // carry, so it stays here rather than being dropped.
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: _roseBorder, width: 2),
                  image: hasPhoto
                      ? DecorationImage(
                          image: FileImage(File(photo)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: hasPhoto
                    ? null
                    : const Icon(
                        Icons.child_care_rounded,
                        size: 26,
                        color: Color(0xFFFF9DB1),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      baby.babyName ?? 'Your little one',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      baby.dob == null
                          ? 'Add a date of birth to build their schedule'
                          : '${babyAgeLabel(baby.dob)} old  ·  Born ${_dateFmt.format(baby.dob!)}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B707B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── PROGRESS ───
          Row(
            children: [
              Expanded(
                child: _buildBabyProgressTile(
                  icon: Icons.vaccines_rounded,
                  label: 'Vaccines given',
                  done: _selectedBabyDoses
                      .where((d) => d.vaccinationDate != null)
                      .length,
                  total: _selectedBabyDoses.length,
                  color: const Color(0xFF8B5CF6),
                  background: const Color(0xFFF3E8FF),
                  onTap: () => _openBabyDetail(tab: 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBabyProgressTile(
                  icon: Icons.emoji_events_rounded,
                  label: 'Milestones hit',
                  done: _selectedBabyMilestones
                      .where((m) => m.achieved)
                      .length,
                  total: _selectedBabyMilestones.length,
                  color: const Color(0xFFF59E0B),
                  background: const Color(0xFFFEF3C7),
                  onTap: () => _openBabyDetail(tab: 1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _editBaby(BirthRecord baby) async {
    final id = await showBabyFormSheet(
      context,
      existing: baby,
      title: 'Edit baby',
    );
    if (id != null) await _loadAllPregnancyData();
  }

  Widget _buildBabyProgressTile({
    required IconData icon,
    required String label,
    required int done,
    required int total,
    required Color color,
    required Color background,
    required VoidCallback onTap,
  }) {
    final fraction = total == 0 ? 0.0 : done / total;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F1F5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: background,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const Spacer(),
                Text(
                  '$done/$total',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: const Color(0xFFF0F1F5),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mirrors the pregnancy "Upcoming Schedule" card, but for the baby: the
  /// next vaccine dose and the next developmental milestone.
  Widget _buildBabyScheduleCard() {
    final dose = _nextDose;
    final milestone = _nextMilestone;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.child_friendly_rounded,
                color: _rose,
                size: 15,
              ),
              SizedBox(width: 6),
              Text(
                "BABY'S CARE PLAN",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _rose,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildScheduleRow(
            icon: Icons.vaccines_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF8B5CF6),
            title: dose?.vaccineName ?? 'All vaccines up to date 🎉',
            date: dose == null
                ? 'Nothing due right now'
                : dose.expectedDate == null
                ? 'No due date set'
                : 'Due ${_dateFmt.format(dose.expectedDate!)}',
            onTap: () => _openBabyDetail(tab: 0),
          ),
          const Divider(color: Color(0xFFF3F4F6), height: 20, thickness: 1),
          _buildScheduleRow(
            icon: Icons.emoji_events_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFF59E0B),
            title: milestone?.milestone ?? 'Every milestone reached 🎉',
            date: milestone == null
                ? 'Nothing pending right now'
                : milestone.expectedDate == null
                ? 'No expected date set'
                : 'Around ${_dateFmt.format(milestone.expectedDate!)}',
            onTap: () => _openBabyDetail(tab: 1),
          ),
        ],
      ),
    );
  }

  /// She is postpartum, not out of the app — this keeps registering the next
  /// pregnancy one tap away without dominating the screen.
  Widget _buildNewPregnancyPrompt(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: _roseSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: _rose,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expecting again?',
                  style: GoogleFonts.outfit(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                Text(
                  'Register a new pregnancy journey',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              final created = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => const PregnancyConfirmationPage(),
                ),
              );
              if (created == true && mounted) await _loadAllPregnancyData();
            },
            style: TextButton.styleFrom(
              foregroundColor: _rose,
              textStyle: GoogleFonts.outfit(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MY BABIES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Entry point to the babies feature.
  ///
  /// Shown whether or not a pregnancy is active: a mother can add a previous
  /// child at any time, and after delivery this is where the newborn lives.
  Widget _buildMyBabiesSection() {
    final count = _babies.length;
    final names = _babies
        .map((b) => b.babyName)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEEFF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: _roseSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.child_care_rounded,
                  color: _rose,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Babies',
                      style: GoogleFonts.outfit(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      count == 0
                          ? 'Add your newborn or an older child'
                          : names.isEmpty
                          ? '$count ${count == 1 ? 'baby' : 'babies'} recorded'
                          : names.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B707B),
                      ),
                    ),
                  ],
                ),
              ),
              if (count > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _roseSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _rose,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _addBabyFromJourney,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _rose,
                      side: const BorderSide(color: _roseBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(
                      'Add baby',
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _openMyBabies,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _rose,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(
                      count == 0 ? 'Open' : 'Vaccines & milestones',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 13.5,
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

  Future<void> _addBabyFromJourney() async {
    final id = await showBabyFormSheet(context);
    if (id != null) await _loadAllPregnancyData();
  }

  /// Maps the modal's baby chip onto `birth_records.gender`. "Twins" says
  /// how many babies there are, not what they are, so it carries no gender.
  static String? _genderValueFor(String label) {
    if (label.startsWith('Baby Boy')) return 'male';
    if (label.startsWith('Baby Girl')) return 'female';
    return null;
  }

  /// Twins get one birth record each — each baby needs its own immunisation
  /// schedule and milestone checklist.
  static int _babyCountFor(String label) => label.startsWith('Twins') ? 2 : 1;

  /// Maps the modal's delivery chip onto `birth_records.delivery_type`.
  static String? _deliveryTypeValueFor(String label) {
    if (label.startsWith('Normal')) return 'normal';
    if (label.startsWith('Cesarean')) return 'c-section';
    if (label.startsWith('Assisted')) return 'assisted';
    return null;
  }

  Future<void> _openMyBabies() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const MyBabiesPage()));
    if (mounted) await _loadAllPregnancyData();
  }

  void _showDeletePregnancyDialog(BuildContext context) {
    final pregId = _pregnancyInfo?['id']?.toString();
    if (pregId == null || pregId.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Color(0xFFEF4444),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete Pregnancy Card?',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this pregnancy record? This will permanently remove your gestational timeline from the database.',
          style: TextStyle(
            fontSize: 13.5,
            color: Color(0xFF4B5563),
            height: 1.45,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // Local-only delete, cascading to the care schedule rows.
                await PregnancyCareDbService.instance.deleteAllForPregnancy(
                  pregId,
                );
                await HealthDbService.instance.deletePregnancy(pregId);
                await UserSessionManager.instance.setPregnancyStatus(
                  'notpregnant',
                );
                await _loadAllPregnancyData();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pregnancy card deleted successfully.'),
                      backgroundColor: Color(0xFFEF4444),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Error deleting pregnancy $pregId: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
