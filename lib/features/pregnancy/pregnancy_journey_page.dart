import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart' show darkCard;
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/widgets/care_schedule_common.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/schedule_status.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/features/baby/baby_detail_page.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/baby_options.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/pregnancy/widgets/welcome_baby_sheet.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/background_audio/widgets/narration_on_visible.dart';

class PregnancyJourneyPage extends StatefulWidget {
  const PregnancyJourneyPage({super.key});

  @override
  State<PregnancyJourneyPage> createState() => _PregnancyJourneyPageState();
}

class _PregnancyJourneyPageState extends State<PregnancyJourneyPage> {
  static final _dateFmt = DateFormat('dd MMM yyyy');
  static final _shortDateFmt = DateFormat('dd MMM');

  // Neutral ink follows light / dark mode: the light value is kept exactly,
  // and dark mode swaps in the palette's readable greys.
  AppPalette get _p => context.palette;
  Color get _ink => _p.pick(const Color(0xFF1E2024), _p.textPrimary);
  Color get _inkSoft => _p.pick(const Color(0xFF6B707B), _p.textSecondary);
  Color get _inkSec => _p.textSecondary;
  Color get _inkSec2 => _p.pick(const Color(0xFF4B5563), _p.textSecondary);
  Color get _inkMuted => _p.pick(const Color(0xFF8E95A5), _p.textMuted);
  Color get _inkMuted2 => _p.textMuted;
  Color get _inkMuted3 => _p.pick(const Color(0xFF8A90A0), _p.textMuted);
  Color get _inkFaint2 => _p.pick(const Color(0xFFBDC3CE), _p.textMuted);
  Color get _inkFaint3 => _p.pick(const Color(0xFF9EA5B4), _p.textMuted);
  Color get _card => _p.card;
  Color get _hair => _p.pick(const Color(0xFFF0F1F5), _p.border);
  Color get _track => _p.pick(const Color(0xFFF0F1F5), _p.surface);
  Color get _chipGrey => _p.pick(const Color(0xFFF3F4F6), _p.surface);
  Color get _shadow3 =>
      _p.pick(Colors.black.withValues(alpha: 0.03), _p.shadow);

  bool _isLoading = true;
  bool _isPregnant = false;
  Map<String, dynamic>? _pregnancyInfo;
  List<Map<String, dynamic>> _completedPregnancies = [];
  List<Baby> _babies = [];

  /// Stands for the pregnancy in [_selectedEntityId], where every other value
  /// is a baby's id.
  static const String _pregnancyEntity = '__pregnancy__';

  /// Which card the avatar row at the top is on: the pregnancy, or one of the
  /// babies. Null until the first load picks one.
  ///
  /// The page used to choose for her — pregnant showed the pregnancy, delivered
  /// showed the newest baby, and the other one was simply unreachable. The row
  /// makes both hers to switch between.
  String? _selectedEntityId;

  /// The baby whose schedule the postpartum view is showing. Null until the
  /// first load, then the newest baby unless the mother picks another.
  String? _selectedBabyId;
  List<BabyImmunizationRecord> _selectedBabyDoses = [];
  List<BabyMilestone> _selectedBabyMilestones = [];

  Baby? get _selectedBaby => _babies.cast<Baby?>().firstWhere(
    (b) => b?.id == _selectedBabyId,
    orElse: () => null,
  );

  bool get _isPregnancySelected => _selectedEntityId == _pregnancyEntity;

  /// Whether the pregnancy gets a place in the avatar row.
  ///
  /// Only while one is running. Once it is over the row is her children, and
  /// registering the next is the prompt at the bottom of their card.
  bool get _showsPregnancyEntity => _isPregnant;

  /// Settles the selection after a load: whatever she was on, if it still
  /// exists, else the pregnancy, else her newest baby.
  void _resolveSelectedEntity() {
    final current = _selectedEntityId;
    final stillThere =
        (current == _pregnancyEntity && _showsPregnancyEntity) ||
        (current != null && _babies.any((b) => b.id == current));
    if (stillThere) return;

    if (_showsPregnancyEntity) {
      _selectedEntityId = _pregnancyEntity;
    } else if (_selectedBabyId != null) {
      _selectedEntityId = _selectedBabyId;
    } else {
      _selectedEntityId = _pregnancyEntity;
    }
  }

  Future<void> _selectEntity(String id) async {
    setState(() {
      _selectedEntityId = id;
      if (id != _pregnancyEntity) _selectedBabyId = id;
    });
    if (id != _pregnancyEntity) {
      await _loadSelectedBabySchedule();
      if (mounted) setState(() {});
    }
  }

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
      final session = MainController.instance;
      await session.reload();
      _babies = await BabyRepository.instance.getBabies();
      await _loadSelectedBabySchedule();

      final healthId = session.healthDataId;
      final active = healthId.isEmpty
          ? null
          : await HealthDbService.instance.getActivePregnancy(healthId);

      Map<String, dynamic>? info;
      if (active != null) {
        final lmp = active.lmpDate;
        final edd = active.eddDate ?? lmp?.add(const Duration(days: 280));
        final now = DateTime.now();
        final daysElapsed = lmp == null ? 0 : now.difference(lmp).inDays;

        // Completed weeks, exactly as `PregnancyController` counts them, and
        // the trimester off the same boundaries. This page used to add one and
        // break at 12 and 26, so at 44 days home said "Week 6" while this
        // screen said "Week 7", and week 27 was the second trimester here and
        // the third everywhere else.
        final weeks = daysElapsed <= 0 ? 0 : daysElapsed ~/ 7;
        final trimester = weeks < 13 ? 1 : (weeks < 28 ? 2 : 3);

        info = {
          'id': active.id,
          'status': active.status,
          'lmpDate': lmp?.toIso8601String(),
          'estimatedDueDate': edd?.toIso8601String(),
          'gestationAgeWeeks': weeks.clamp(0, 42),
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
          .getCompletedPregnancies(healthId);
      final completed = completedRows
          .map(
            (p) => {
              'id': p.id,
              'status': p.status,
              'lmpDate': p.lmpDate?.toIso8601String(),
              'edDate': p.eddDate?.toIso8601String(),
              'deliveryDate': p.deliveryDateTime?.toIso8601String(),
              'completedAt': p.deliveryDateTime?.toIso8601String(),
              'csectionDeliveries': p.csectionDeliveries,
              'deliveryConductedAt': p.status,
            },
          )
          .toList();

      if (mounted) {
        setState(() {
          _pregnancyInfo = info;
          _isPregnant = active != null && active.status == 'active';
          _completedPregnancies = completed;
          // After `_isPregnant` is known, so a pregnancy that has just ended
          // hands the row over to her babies rather than leaving it on a card
          // that is no longer there.
          _resolveSelectedEntity();
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
    final week = _pregnancyInfo?['gestationAgeWeeks'] as int? ?? 0;
    final trimesters = _pregnancyInfo?['trimesters'] as int? ?? 1;
    final trimesterText = 'Trimester $trimesters';
    final daysLeft = _pregnancyInfo?['daysRemaining'] as int? ?? 0;
    final eddFormatted = _formatEdd(
      _pregnancyInfo?['estimatedDueDate'] as String?,
    );
    final progressFraction = (week / 40.0).clamp(0.0, 1.0);
    final progressPercent = (progressFraction * 100).toInt();

    return Scaffold(
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: _p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: _ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isPregnancySelected
              ? 'My Pregnancy Journey'
              : (_selectedBaby?.name.trim().isNotEmpty ?? false)
              ? _selectedBaby!.name.trim()
              : 'My Baby Journey',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ink,
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
            icon: Icon(Icons.more_vert_rounded, color: _ink, size: 22),
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
                case 'add_baby':
                  await _addBabyFromHeader();
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
              // Always offered: the avatar row is only a way to move between
              // her children, not a way to record a new one.
              const PopupMenuItem(
                value: 'add_baby',
                child: Row(
                  children: [
                    Icon(
                      Icons.child_care_rounded,
                      size: 18,
                      color: Color(0xFFFF3B5C),
                    ),
                    SizedBox(width: 10),
                    Text('Add Baby'),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEntitySwitcher(),
                      if (_isPregnancySelected)
                        _isPregnant
                            ? _buildActivePregnancyView(
                                context: context,
                                gestationalWeek: week,
                                trimester: trimesterText,
                                daysLeft: daysLeft,
                                eddFormatted: eddFormatted,
                                progressFraction: progressFraction,
                                progressPercent: progressPercent,
                              )
                            : _buildUnregisteredPregnancyView(context)
                      else
                        _buildBabyJourneyView(context),
                    ],
                  ),
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
          // The tour of this screen, once; the card's own line counts the
          // weeks, which the recording cannot.
          narrationKey: NarrationKeys.pgJourneyOpen,
          bindNarrationText: false,
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
        //
        // Each section explains itself as it scrolls into view rather than all
        // at once on open — three lines back to back is a lecture.
        NarrationOnVisible(
          narrationKey: NarrationKeys.pgJourneyUpcoming,
          child: _buildUpcomingScheduleCard(context),
        ),
        const SizedBox(height: 20),

        // Her children are the avatar row at the top of this screen now, and
        // her finished journeys are their own history — neither belongs in the
        // middle of the pregnancy she is carrying.

        // ─── COMPLETE PREGNANCY SECTION ───
        NarrationOnVisible(
          narrationKey: NarrationKeys.pgJourneyComplete,
          child: _buildCompletePregnancySection(context),
        ),
        const SizedBox(height: 20),

        // ─── DELETE PREGNANCY CARD SECTION ───
        _buildDeletePregnancyCardSection(context),
        const SizedBox(height: 24),
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
            gradient: LinearGradient(
              colors: _p.pick(
                const [Color(0xFFFFF0F4), Color(0xFFFFFAFB), Colors.white],
                const [Color(0xFF2E1F24), Color(0xFF241C1F), darkCard],
              ),
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _p.pick(const Color(0xFFFFDCE4), _p.accentBorder),
              width: 1.2,
            ),
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
                      decoration: BoxDecoration(
                        color: _roseSoft,
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
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your LMP date to unlock week-by-week baby development, doctor visit schedules, vaccination reminders, and daily care tracking.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _inkSec, height: 1.45),
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
                    style: TextStyle(
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
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: _inkMuted,
          ),
        ),
        const SizedBox(height: 12),

        _buildBenefitTile(
          icon: Icons.auto_graph_rounded,
          iconBg: _roseSoft,
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
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _hair),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _p.tint(iconColor, iconBg),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: _inkSec, height: 1.35),
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
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hair, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _shadow3,
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
                      color: _roseSoft,
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
                        color: _p.tint(
                          const Color(0xFFEF4444),
                          const Color(0xFFFEE2E2),
                        ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _ink,
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
                    color: _chipGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_calendar_rounded,
                        size: 12,
                        color: _inkSec2,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Change LMP',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: _inkSec2,
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
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: _inkMuted,
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
                  backgroundColor: _p.pick(
                    const Color(0xFFFFE6ED),
                    _p.accentSoft,
                  ),
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
                  bg: _roseSoft,
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
        color: _p.tint(iconColor, bg),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: _inkMuted3,
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
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hair, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _shadow3,
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
                  color: _inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildScheduleRow(
            icon: Icons.medical_services_rounded,
            iconBg: _roseSoft,
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
          Divider(
            color: _p.pick(const Color(0xFFF3F4F6), _p.divider),
            height: 20,
            thickness: 1,
          ),
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
          Divider(
            color: _p.pick(const Color(0xFFF3F4F6), _p.divider),
            height: 20,
            thickness: 1,
          ),
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
              decoration: BoxDecoration(
                color: _p.tint(iconColor, iconBg),
                shape: BoxShape.circle,
              ),
              child: Center(child: Icon(icon, color: iconColor, size: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _inkSec,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 22, color: _inkFaint2),
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
        gradient: LinearGradient(
          colors: _p.pick(
            const [Color(0xFFFFF0F4), Color(0xFFFFF7F9), Colors.white],
            const [Color(0xFF2E1F24), Color(0xFF241C1F), darkCard],
          ),
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Celebrate your delivery! Mark this pregnancy journey as completed to record birth milestones and transition to newborn care.',
            style: TextStyle(fontSize: 12.5, color: _inkSec2, height: 1.4),
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
                style: TextStyle(
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
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _p.pick(
            const Color(0xFFFEE2E2),
            const Color(0xFFEF4444).withValues(alpha: 0.35),
          ),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _p.tint(const Color(0xFFEF4444), const Color(0xFFFEF2F2)),
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
                Text(
                  'Delete Pregnancy Card',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Remove this record and reset timeline',
                  style: TextStyle(fontSize: 11.5, color: _inkMuted2),
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
            Icon(Icons.history_edu_rounded, size: 16, color: _inkSec),
            const SizedBox(width: 6),
            Text(
              'PAST PREGNANCY JOURNEYS (${_completedPregnancies.length})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: _inkSec,
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
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _p.border),
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
                    decoration: BoxDecoration(
                      color: _p.tint(
                        const Color(0xFF10B981),
                        const Color(0xFFECFDF5),
                      ),
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
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _ink,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _chipGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCsec ? 'C-Section' : 'Delivered',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _inkSec2,
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
                    Text(
                      'Delivery Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: _inkMuted2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedDeliv,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LMP Date',
                      style: TextStyle(
                        fontSize: 11,
                        color: _inkMuted2,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formattedLmp,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _ink,
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
                      Text(
                        'Hospital',
                        style: TextStyle(
                          fontSize: 11,
                          color: _inkMuted2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hospital,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _ink,
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
  Color get _roseSoft => _p.tint(_rose, const Color(0xFFFFF0F4));
  Color get _roseBorder => _p.pick(const Color(0xFFFFD3DC), _p.accentBorder);

  /// "Welcome your baby": a three-step sheet — delivery date, then delivery
  /// type, gender and weight, then the first photo.
  Future<void> _showCompletePregnancyModal(BuildContext context) async {
    final pregId = _pregnancyInfo?['id']?.toString();
    if (pregId == null || pregId.isEmpty) return;

    var babyCount = 0;
    final saved = await WelcomeBabySheet.show(
      context,
      onSubmit: (d) async {
        // Local-only: written to SQLite with synced = 0.
        await HealthDbService.instance.completePregnancy(
          pregId,
          deliveredAt: d.deliveryDate,
        );

        // The delivery produces the baby: a birth record linked to this
        // pregnancy, with its own health record and a vaccination and
        // milestone schedule anchored on the DOB.
        final babyIds = await BabyRepository.instance.recordBirthsForPregnancy(
          pregnancyId: pregId,
          deliveryDate: d.deliveryDate,
          gender: d.gender,
          deliveryType: d.deliveryType,
          weight: d.weightKg,
          photo: d.photoPath,
          babyCount: 1,
        );
        babyCount = babyIds.length;

        // She is no longer pregnant. 'new_mom' is a non-pregnant status that
        // also tells the app she is postpartum rather than never-pregnant.
        await MainController.instance.setPregnancyStatus('new_mom');
      },
    );
    if (saved == null || !mounted) return;

    await _loadAllPregnancyData();
    if (!mounted) return;
    speak(NarrationKeys.pgConfJourneyDone, force: true);
    ScaffoldMessenger.of(this.context).showSnackBar(
      SnackBar(
        content: Text(
          babyCount > 1
              ? 'Congratulations Amma! $babyCount babies added to your family! 👶👶🎉'
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

  // ═══════════════════════════════════════════════════════════════════════════
  // ENTITY SWITCHER — the pregnancy and every baby, side by side
  // ═══════════════════════════════════════════════════════════════════════════

  /// Round avatars across the top: the pregnancy first, then each baby.
  ///
  /// Hidden when there is only one of them, because a row of one is not a
  /// choice.
  Widget _buildEntitySwitcher() {
    final entries = <({String id, String label, Baby? baby})>[
      if (_showsPregnancyEntity)
        (id: _pregnancyEntity, label: 'Pregnancy', baby: null),
      for (final baby in _babies)
        (
          id: baby.id,
          label: baby.name.trim().isEmpty ? 'Baby' : baby.name.trim(),
          baby: baby,
        ),
    ];

    if (entries.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 88,
      // Centred while they fit, scrolling from the left once they do not — a
      // row of two avatars pinned to the left edge reads as an overflow.
      child: Center(
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final entry = entries[index];
            final isSelected = _selectedEntityId == entry.id;

            return GestureDetector(
              onTap: () => _selectEntity(entry.id),
              child: SizedBox(
                width: 66,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? _rose
                              : _p.pick(const Color(0xFFE9EAEF), _p.border),
                          width: 2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: _rose.withValues(alpha: 0.28),
                                  blurRadius: 9,
                                  spreadRadius: 1,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: Container(
                          color: _card,
                          padding: const EdgeInsets.all(4),
                          child: _entityAvatar(entry.baby),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      entry.label.split(' ').first,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? _rose : _inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// A baby's own photo where there is one, otherwise the illustration that
  /// matches — the bump for the pregnancy, a boy or a girl for a baby.
  Widget _entityAvatar(Baby? baby) {
    if (baby == null) {
      return Image.asset(
        'assets/allobaby/BabyIllustration.png',
        fit: BoxFit.contain,
      );
    }

    final photo = baby.photo;
    if (photo != null && photo.isNotEmpty && File(photo).existsSync()) {
      return Image.file(File(photo), fit: BoxFit.cover);
    }

    final asset = switch (baby.gender?.toLowerCase()) {
      'male' => 'assets/allobaby/boybaby.png',
      'female' => 'assets/allobaby/girlbaby.png',
      _ => 'assets/allobaby/Baby3D.png',
    };
    return Image.asset(asset, fit: BoxFit.contain);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BABY JOURNEY VIEW (the card for one of her children)
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

  /// Records a new baby and moves the row onto them.
  Future<void> _addBabyFromHeader() async {
    final id = await showBabyFormSheet(context, title: 'Add baby');
    if (id == null || !mounted) return;
    await _loadAllPregnancyData();
    if (!mounted) return;
    await _selectEntity(id);
  }

  /// How many of what is still coming the card shows before it stops.
  static const int _upcomingLimit = 3;

  /// The doses still to be given, soonest first.
  List<BabyImmunizationRecord> get _upcomingDoses {
    final pending = _selectedBabyDoses
        .where((dose) => dose.vaccinationDate == null)
        .toList();
    pending.sort(_byDueDate((dose) => dose.expectedDate));
    return pending;
  }

  /// The milestones not yet reached, soonest first.
  List<BabyMilestone> get _upcomingMilestones {
    final pending = _selectedBabyMilestones
        .where((milestone) => !milestone.achieved)
        .toList();
    pending.sort(_byDueDate((milestone) => milestone.expectedDate));
    return pending;
  }

  /// Sorts by due date with the undated ones last, so a row with no date never
  /// jumps the queue ahead of one that is actually due.
  static int Function(T, T) _byDueDate<T>(DateTime? Function(T) dateOf) {
    return (a, b) {
      final dateA = dateOf(a);
      final dateB = dateOf(b);
      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateA.compareTo(dateB);
    };
  }

  Future<void> _openBabyDetail({int tab = 0}) async {
    final babyId = _selectedBabyId;
    if (babyId == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BabyDetailPage(babyId: babyId, initialTab: tab),
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

        // ─── VACCINATION ───
        _buildBabyRecordSection(
          label: 'VACCINATION',
          icon: Icons.vaccines_rounded,
          accent: const Color(0xFF8B5CF6),
          done: _selectedBabyDoses
              .where((d) => d.vaccinationDate != null)
              .length,
          total: _selectedBabyDoses.length,
          upcoming: _upcomingDoses,
          allDoneMessage: 'Every dose given 🎉',
          emptyMessage:
              'No doses scheduled yet. Editing the date of birth rebuilds the '
              'standard immunisation schedule.',
          onOpen: () => _openBabyDetail(tab: 0),
          rowBuilder: (dose) => _buildDoseRow(dose),
        ),
        const SizedBox(height: 16),

        // ─── MILESTONES ───
        _buildBabyRecordSection(
          label: 'MILESTONES',
          icon: Icons.emoji_events_rounded,
          accent: const Color(0xFFF59E0B),
          done: _selectedBabyMilestones.where((m) => m.achieved).length,
          total: _selectedBabyMilestones.length,
          upcoming: _upcomingMilestones,
          allDoneMessage: 'Every milestone reached 🎉',
          emptyMessage:
              'No milestones yet. Editing the date of birth rebuilds the '
              'standard developmental checklist.',
          onOpen: () => _openBabyDetail(tab: 1),
          rowBuilder: (milestone) => _buildMilestoneRow(milestone),
        ),
        const SizedBox(height: 20),

        // ─── START A NEW PREGNANCY ───
        // Only once this one is over — she is looking at her child's card, not
        // being asked to start the next while still carrying.
        if (!_isPregnant) ...[
          _buildNewPregnancyPrompt(context),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  /// What the baby says from the banner.
  ///
  /// First person, like the pregnant view's "Am 24 weeks, Amma!" — same voice,
  /// the other side of the birth.
  String _babyBannerText(Baby baby) {
    final name = baby.name.trim();
    final age = babyAgeLabel(baby.deliveryDate);
    final opener = age == 'Newborn'
        ? "Am here, Amma! 💕"
        : "Am $age old, Amma! 💕";
    return name.isEmpty
        ? "$opener\nGrowing a little more every day."
        : "$opener\nThank you for looking after me.";
  }

  /// Name, age and how far through the schedule they are.
  ///
  /// Styled as the pregnancy info card is, and sits under the banner in the
  /// same place: the banner is the picture, this is the record.
  Widget _buildBabyInfoCard(Baby baby) {
    final photo = baby.photo;
    final hasPhoto =
        photo != null && photo.isNotEmpty && File(photo).existsSync();
    final gender = baby.gender;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hair, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _shadow3,
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
                        color: _roseSoft,
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
                        color: _chipGrey,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.edit_rounded,
                        size: 14,
                        color: _inkSec2,
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
                  color: _card,
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
                      baby.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${babyAgeLabel(baby.deliveryDate)} old  ·  '
                      'Born ${_dateFmt.format(baby.deliveryDate)}',
                      style: TextStyle(fontSize: 12, color: _inkSoft),
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
                  done: _selectedBabyMilestones.where((m) => m.achieved).length,
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

  Future<void> _editBaby(Baby baby) async {
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
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _hair),
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
                    color: _p.tint(color, background),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const Spacer(),
                Text(
                  '$done/$total',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
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
                backgroundColor: _track,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            const SizedBox(height: 7),
            Text(label, style: TextStyle(fontSize: 11, color: _inkMuted)),
          ],
        ),
      ),
    );
  }

  /// What is still coming for this baby — the next few doses, or the next few
  /// milestones.
  ///
  /// Deliberately not the whole schedule: a newborn has twenty-four doses
  /// ahead of her and listing them all buries the two that matter this month.
  /// The counter and bar still say how far through she is, and the full list
  /// is one tap away on [BabyDetailPage].
  Widget _buildBabyRecordSection<T>({
    required String label,
    required IconData icon,
    required Color accent,
    required int done,
    required int total,
    required List<T> upcoming,
    required String allDoneMessage,
    required String emptyMessage,
    required VoidCallback onOpen,
    required Widget Function(T) rowBuilder,
  }) {
    final fraction = total == 0 ? 0.0 : done / total;
    final shown = upcoming.take(_upcomingLimit).toList();
    final hidden = upcoming.length - shown.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _hair, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: _shadow3,
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 15),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: accent,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              if (total > 0)
                Text(
                  '$done/$total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction,
                minHeight: 5,
                backgroundColor: _track,
                valueColor: AlwaysStoppedAnimation(accent),
              ),
            ),
          ],
          const SizedBox(height: 4),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                total == 0 ? emptyMessage : allDoneMessage,
                style: TextStyle(fontSize: 12, height: 1.4, color: _inkMuted),
              ),
            )
          else
            ...shown.map(rowBuilder),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                foregroundColor: accent,
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 17),
              label: Text(
                hidden > 0 ? 'View all ($total)' : 'Open full record',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoseRow(BabyImmunizationRecord dose) {
    final given = dose.vaccinationDate != null;
    final status = CareStatus.resolve(
      status: given ? 'done' : 'pending',
      date: dose.expectedDate,
    );

    return _buildBabyRecordRow(
      checked: given,
      activeColor: const Color(0xFF8B5CF6),
      title: dose.vaccineName,
      subtitle: given
          ? 'Given ${_dateFmt.format(dose.vaccinationDate!)}'
          : dose.expectedDate == null
          ? 'No due date set'
          : 'Due ${_dateFmt.format(dose.expectedDate!)}',
      status: status,
      // A dose is a date, so an overdue one is worth saying out loud.
      showStatus: true,
      onChanged: (value) async {
        await BabyDbService.instance.markImmunizationGiven(
          dose.id,
          value ? DateTime.now() : null,
        );
        await _loadSelectedBabySchedule();
        if (mounted) setState(() {});
      },
      onTap: () => _openBabyDetail(tab: 0),
    );
  }

  Widget _buildMilestoneRow(BabyMilestone milestone) {
    final status = CareStatus.resolve(
      status: milestone.achieved ? 'done' : 'pending',
      date: milestone.expectedDate,
    );

    return _buildBabyRecordRow(
      checked: milestone.achieved,
      activeColor: const Color(0xFFF59E0B),
      title: milestone.milestone,
      subtitle: milestone.completedAt != null
          ? 'Achieved ${_dateFmt.format(milestone.completedAt!)}'
          : milestone.expectedDate == null
          ? milestone.description
          : 'Usually around ${_dateFmt.format(milestone.expectedDate!)}',
      status: status,
      // Milestones are guides, not deadlines — a late one is not "overdue" and
      // should not be shouted at her.
      showStatus: milestone.achieved,
      onChanged: (value) async {
        await BabyDbService.instance.setMilestoneAchieved(
          milestone.id,
          value ? DateTime.now() : null,
        );
        await _loadSelectedBabySchedule();
        if (mounted) setState(() {});
      },
      onTap: () => _openBabyDetail(tab: 1),
    );
  }

  Widget _buildBabyRecordRow({
    required bool checked,
    required Color activeColor,
    required String title,
    required String subtitle,
    required CareStatus status,
    required bool showStatus,
    required ValueChanged<bool> onChanged,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: Checkbox(
                value: checked,
                activeColor: activeColor,
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                onChanged: (value) => onChanged(value ?? false),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _ink,
                      decoration: checked ? TextDecoration.lineThrough : null,
                      decorationColor: _inkFaint3,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: _inkMuted),
                  ),
                ],
              ),
            ),
            if (showStatus) ...[
              const SizedBox(width: 8),
              CareStatusChip(status: status),
            ],
          ],
        ),
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
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _p.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: _roseSoft, shape: BoxShape.circle),
            child: const Icon(Icons.favorite_rounded, color: _rose, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expecting again?',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                Text(
                  'Register a new pregnancy journey',
                  style: TextStyle(fontSize: 11.5, color: _inkMuted),
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
              textStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
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
        .map((b) => b.name)
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
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
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        color: _ink,
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
                      style: TextStyle(fontSize: 12, color: _inkSoft),
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
                    style: TextStyle(
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
                      side: BorderSide(color: _roseBorder),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    label: Text(
                      'Add baby',
                      style: TextStyle(
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
                      style: TextStyle(
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
    if (id == null) return;
    speak(NarrationKeys.pgConfBabyAdded, force: true);
    await _loadAllPregnancyData();
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

    // Read out every time, not once: this one undoes the whole record, and a
    // mother who has heard it before is exactly who might tap it by accident.
    speak(NarrationKeys.pgJourneyDelete, force: true);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _p.tint(
                  const Color(0xFFEF4444),
                  const Color(0xFFFEF2F2),
                ),
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to delete this pregnancy record? This will permanently remove your gestational timeline from the database.',
          style: TextStyle(fontSize: 13.5, color: _inkSec2, height: 1.45),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(color: _inkSec, fontWeight: FontWeight.w600),
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
                await MainController.instance.setPregnancyStatus('notpregnant');
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
