import 'dart:io';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:get/get.dart' show Obx;
import 'package:intl/intl.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart' show darkCard;
import 'package:allomom/features/allobot/widgets/allobot_home_view.dart'
    show AlloBotGeminiOrb;
import 'package:allomom/features/pregnancy/baby_care_track_page.dart';
import 'package:allomom/features/pregnancy/widgets/baby_care_carousel.dart';
import 'package:allomom/features/pregnancy/widgets/baby_feature_row.dart';
import 'package:allomom/features/pregnancy/widgets/baby_growth_track.dart';
import 'package:allomom/features/pregnancy/widgets/baby_profile_card.dart';
import 'package:allomom/features/pregnancy/widgets/baby_size_card.dart';
import 'package:allomom/features/pregnancy/widgets/weekly_summary_card.dart';
import 'package:allomom/features/pregnancy/widgets/pregnancy_month_track.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/baby_db_service.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/services/sq_lite/services/pregnancy_care_db_service.dart';
import 'package:allomom/features/baby/baby_form_sheet.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';
import 'package:allomom/features/pregnancy/widgets/welcome_baby_sheet.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/background_audio/widgets/narration_on_visible.dart';

class PregnancyJourneyPage extends StatefulWidget {
  const PregnancyJourneyPage({super.key});

  @override
  State<PregnancyJourneyPage> createState() => _PregnancyJourneyPageState();
}

class _PregnancyJourneyPageState extends State<PregnancyJourneyPage>
    with TickerProviderStateMixin {
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
  Color get _card => _p.card;
  Color get _hair => _p.pick(const Color(0xFFF0F1F5), _p.border);
  Color get _chipGrey => _p.pick(const Color(0xFFF3F4F6), _p.surface);

  bool _isLoading = true;
  bool _isPregnant = false;
  int? _selectedPregnancyMonth;
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
      // The new selection says its own week, even one said before.
      _silenceWeeklySummary();
      _weeklyWeek = null;
    });
    _playWeeklySummary();
    if (id != _pregnancyEntity) {
      await _loadSelectedBabySchedule();
      if (mounted) setState(() {});
    }
  }

  /// Whose record the page last loaded. Opened on a family member's, the
  /// record can arrive from the server a moment after the page does, so the
  /// page reloads when it does.
  String _loadedHealthId = '';
  String _loadedViewing = '';

  void _onSessionChanged() {
    final session = MainController.instance;
    if (session.pregnancyHealthDataId != _loadedHealthId ||
        (session.viewingUserId ?? '') != _loadedViewing) {
      _loadAllPregnancyData();
    }
  }

  @override
  void initState() {
    super.initState();
    MainController.instance.addListener(_onSessionChanged);
    _loadAllPregnancyData();
  }

  @override
  void dispose() {
    MainController.instance.removeListener(_onSessionChanged);
    _weeklyRun++;
    // Only the week's own lines: a page this one pushed may already be
    // talking.
    final base = _weeklyBase;
    if (base != null && BackgroundAudioController.isReady) {
      final audio = BackgroundAudioController.to;
      if (audio.currentKey.value.startsWith(base)) audio.stop();
    }
    super.dispose();
  }

  // ─── WEEKLY SUMMARY VOICE ───
  // On open, and whenever the selection changes, the week's AlloBot flow is
  // said — the pregnancy's week, or the selected baby's (weeks 41–142) — the
  // same words home starts with and the Weekly Summary card shows, with a
  // Stop Speaking bar under it.

  /// Bumped to cut off whatever run is saying its lines: on Stop, on a new
  /// selection, and when the page goes.
  int _weeklyRun = 0;
  bool _weeklyPlaying = false;

  /// The week last started, so a reload does not say it again.
  int? _weeklyWeek;

  /// `pregnancy_week_<n>_info` for the week being said; each line plays as
  /// `<base>#<i>`.
  String? _weeklyBase;

  /// The week the selection is in: the pregnancy's, or the selected baby's
  /// while inside the 1000 days. Null when there is none.
  int? get _selectedWeek {
    if (_isPregnancySelected) {
      final weeks = _pregnancyInfo?['gestationAgeWeeks'] as int?;
      return _isPregnant && weeks != null
          ? WeeklyBabyTalk.pregnancyWeek(weeks)
          : null;
    }
    return WeeklyBabyTalk.babyWeekOf(_selectedBaby?.deliveryDate);
  }

  Future<void> _playWeeklySummary() async {
    final week = _selectedWeek;
    if (week == null || week == _weeklyWeek) return;
    if (!BackgroundAudioController.isReady) return;
    final audio = BackgroundAudioController.to;
    if (!audio.isVoiceEnabled.value) return;
    _weeklyWeek = week;
    final run = ++_weeklyRun;

    final lines = await WeeklyBabyTalk.lines(week);
    if (!mounted || run != _weeklyRun || lines.isEmpty) return;

    final base = WeeklyBabyTalk.intentKey(week);
    setState(() {
      _weeklyBase = base;
      _weeklyPlaying = true;
    });
    for (var i = 0; i < lines.length; i++) {
      if (!mounted || run != _weeklyRun) return;
      final key = '$base#$i';
      audio.registerText(key, lines[i].text, audioUrl: lines[i].audioUrl);
      // Every visit: home has usually said these already this session.
      await audio.playByKey(key, force: true);
      // Something else took the voice over mid-line.
      if (audio.currentKey.value.isNotEmpty &&
          !audio.currentKey.value.startsWith(base)) {
        break;
      }
    }
    if (mounted && run == _weeklyRun) setState(() => _weeklyPlaying = false);
  }

  /// Cuts the week's lines off, if they are playing.
  void _silenceWeeklySummary() {
    _weeklyRun++;
    final base = _weeklyBase;
    if (_weeklyPlaying && base != null && BackgroundAudioController.isReady) {
      final audio = BackgroundAudioController.to;
      if (audio.currentKey.value.startsWith(base)) audio.stop();
    }
    _weeklyPlaying = false;
  }

  void _stopWeeklySummary() => setState(_silenceWeeklySummary);

  /// Whether the week's lines are sounding right now — the baby's mouth
  /// follows it. Read inside an [Obx].
  bool get _weeklySpeaking {
    if (!BackgroundAudioController.isReady) return false;
    final audio = BackgroundAudioController.to;
    // Both observables are read on every build, before the week's key is
    // known too — an Obx that reads none of them throws.
    final playing = audio.isPlaying.value;
    final key = audio.currentKey.value;
    final base = _weeklyBase;
    return playing && base != null && key.startsWith(base);
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

      final healthId = session.pregnancyHealthDataId;
      _loadedHealthId = healthId;
      _loadedViewing = session.viewingUserId ?? '';
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
        final pregnancyMonth = daysElapsed <= 0
            ? 1
            : ((daysElapsed / 30.44).floor() + 1).clamp(1, 9);

        info = {
          'id': active.id,
          'status': active.status,
          'lmpDate': lmp?.toIso8601String(),
          'estimatedDueDate': edd?.toIso8601String(),
          'gestationAgeWeeks': weeks.clamp(0, 42),
          'pregnancyMonth': pregnancyMonth,
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
        _playWeeklySummary();
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
    final pregnancyMonth = _pregnancyInfo?['pregnancyMonth'] as int? ?? 1;
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
          // The baby's name is on the card right below.
          _isPregnancySelected ? 'My Pregnancy' : 'My Baby',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _ink,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: _ink, size: 22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) async {
              switch (val) {
                case 'register':
                  final created = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PregnancyConfirmationPage(),
                    ),
                  );
                  if (created == true) _loadAllPregnancyData();
                  break;
                case 'edit_baby':
                  final baby = _selectedBaby;
                  if (baby != null) await _editBaby(baby);
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
              // Where the baby info card's pencil used to be.
              if (_selectedEntityId != _pregnancyEntity &&
                  _selectedBaby != null)
                const PopupMenuItem(
                  value: 'edit_baby',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: Color(0xFFFF3B5C),
                      ),
                      SizedBox(width: 10),
                      Text('Edit Baby'),
                    ],
                  ),
                ),
              if (_selectedEntityId != _pregnancyEntity &&
                  _selectedBaby != null)
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
                        'Delete Current Pregnancy',
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
                      _expandIn(
                        key: _selectedEntityId ?? '',
                        child: _isPregnancySelected
                            ? (_isPregnant
                                  ? _buildActivePregnancyView(
                                      context: context,
                                      gestationalWeek: week,
                                      pregnancyMonth: pregnancyMonth,
                                      trimester: trimesterText,
                                      daysLeft: daysLeft,
                                      eddFormatted: eddFormatted,
                                      progressFraction: progressFraction,
                                      progressPercent: progressPercent,
                                    )
                                  : _buildUnregisteredPregnancyView(context))
                            : _buildBabyJourneyView(context),
                      ),
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
    required int pregnancyMonth,
    required String trimester,
    required int daysLeft,
    required String eddFormatted,
    required double progressFraction,
    required int progressPercent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── PREGNANCY TRAIN ───
        // The nine months as wagons; under the train the pregnancy info, then
        // the picked month's ANC, vaccinations and lab reports, then a box
        // for each full schedule. Replaces the banner and the old list.
        // The page opens on the week's summary, spoken by the baby, rather
        // than the old journey-open narration.
        PregnancyMonthTrack(
            onChanged: _loadAllPregnancyData,
            onMonthSelected: (m) => setState(() => _selectedPregnancyMonth = m),
            aboveTrain: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPregnancyInfoCard(
                  context: context,
                  gestationalWeek: gestationalWeek,
                  trimester: trimester,
                  daysLeft: daysLeft,
                  eddFormatted: eddFormatted,
                  progressFraction: progressFraction,
                  progressPercent: progressPercent,
                ),
                // Only while the baby is saying the week; stops the voice.
                if (_weeklyPlaying) ...[
                  const SizedBox(height: 10),
                  _buildStopSpeakingButton(),
                ],
                const SizedBox(height: 16),
                // What the baby says first on home, then this week's size,
                // between the overview and the tallies.
                WeeklySummaryCard(
                  week: WeeklyBabyTalk.pregnancyWeek(gestationalWeek),
                ),
                BabySizeCard(gestationalWeek: gestationalWeek),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // ─── COMPLETE PREGNANCY SECTION ───
        // Only visible when viewing month 7 onwards (or if current gestational month >= 7).
        if ((_selectedPregnancyMonth ?? pregnancyMonth) >= 7) ...[
          NarrationOnVisible(
            narrationKey: NarrationKeys.pgJourneyComplete,
            child: _buildCompletePregnancySection(context),
          ),
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
  /// Where the pregnancy stands, compact and plain: the week with a small
  /// progress ring, then the due date, the days left and the weeks to go.
  Widget _buildPregnancyInfoCard({
    required BuildContext context,
    required int gestationalWeek,
    required String trimester,
    required int daysLeft,
    required String eddFormatted,
    required double progressFraction,
    required int progressPercent,
  }) {
    final weeksToGo = (40 - gestationalWeek).clamp(0, 40);
    // The stat cards set the card's height; the baby then fills the left
    // half at that height, 16px in from the card's edge like the cards.
    const gap = 12.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _hair, width: 1.1),
      ),
      child: Stack(
        // The glow's blur spreads past the baby's box; let it into the
        // padding instead of cutting it off square.
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  // Home's baby on its glow, talking while it says the week.
                  // Empty while the switcher's avatar flies in to it.
                  child: AnimatedOpacity(
                    key: _cardAvatarKey,
                    opacity: _flyingEntityId == _pregnancyEntity ? 0 : 1,
                    duration: const Duration(milliseconds: 200),
                    child: FittedBox(
                      child: BackgroundAudioController.isReady
                          ? Obx(
                              () => AlloBotGeminiOrb(
                                isSpeaking: _weeklySpeaking,
                                isThinking: false,
                                babySize: 190,
                              ),
                            )
                          : const AlloBotGeminiOrb(
                              isSpeaking: false,
                              isThinking: false,
                              babySize: 190,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: gap),
                const Spacer(),
              ],
            ),
          ),
          Row(
            children: [
              const Spacer(),
              const SizedBox(width: gap),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoStat(
                      icon: Icons.event_available_rounded,
                      label: 'Due Date',
                      value: eddFormatted,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoStat(
                      icon: Icons.child_friendly_rounded,
                      label: 'Weeks to go',
                      value: '$weeksToGo',
                    ),
                    const SizedBox(height: 8),
                    _buildInfoStat(
                      icon: Icons.timelapse_rounded,
                      label: 'Trimester',
                      value: trimester.replaceFirst('Trimester ', ''),
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

  /// A frosted-glass bar under the baby, as on the kick counter: the page
  /// shows through a blurred, tinted fill, with the accent red on the label.
  Widget _buildStopSpeakingButton() {
    const accent = Color(0xFFFF4E6A);
    final radius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: _p.isDark ? 0.08 : 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: _p.isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : accent.withValues(alpha: 0.25),
            ),
          ),
          child: InkWell(
            onTap: _stopWeeklySummary,
            child: const SizedBox(
              width: double.infinity,
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded, size: 18, color: accent),
                  SizedBox(width: 6),
                  Text(
                    'Stop Speaking',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// One small card in the overview's right half: an icon, then the label
  /// over its value.
  Widget _buildInfoStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: _chipGrey,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: _card, shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: _inkSec2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: _inkMuted3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ink,
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

  /// Round avatars across the top: the pregnancy first, then each baby —
  /// all but the one selected, which is the card below.
  ///
  /// Always ends in a "+" that opens the add-baby sheet.
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
    ].where((e) => e.id != _selectedEntityId).toList();

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
          itemCount: entries.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            if (index == entries.length) return _buildAddBabyTile();
            final entry = entries[index];

            return GestureDetector(
              onTap: () => _flyEntityToCard(entry.id, entry.baby),
              child: SizedBox(
                width: 66,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      key: _switcherAvatarKey(entry.id),
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _p.pick(const Color(0xFFE9EAEF), _p.border),
                          width: 2,
                        ),
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
                        fontWeight: FontWeight.w500,
                        color: _inkSoft,
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

  /// Each avatar in the row, by entity id — where a flight starts from.
  final Map<String, GlobalKey> _switcherAvatarKeys = {};
  GlobalKey _switcherAvatarKey(String id) =>
      _switcherAvatarKeys.putIfAbsent(id, GlobalKey.new);

  /// The photo spot on the card below: the baby's photo, or the pregnancy's
  /// glowing baby. Only one of the two is ever built.
  final GlobalKey _cardAvatarKey = GlobalKey();

  /// The entity whose avatar is in flight; its card keeps the spot empty
  /// until it lands.
  String? _flyingEntityId;

  /// Selects [id] with its avatar lifting out of the row and settling into
  /// the card below as the card expands in.
  Future<void> _flyEntityToCard(String id, Baby? baby) async {
    if (_flyingEntityId != null) return;
    final source =
        _switcherAvatarKeys[id]?.currentContext?.findRenderObject()
            as RenderBox?;
    final from = source != null && source.hasSize
        ? source.localToGlobal(Offset.zero) & source.size
        : null;

    setState(() => _flyingEntityId = id);
    final selected = _selectEntity(id);
    await WidgetsBinding.instance.endOfFrame;

    final isPregnancy = id == _pregnancyEntity;

    // Where the photo spot is right now — read every frame, since the card is
    // still growing in while the avatar flies. The pregnancy's spot is the
    // whole glow; the baby sits in its middle.
    Rect? landing() {
      final box =
          _cardAvatarKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) return null;
      final rect = box.localToGlobal(Offset.zero) & box.size;
      if (!isPregnancy) return rect;
      final side = rect.shortestSide * 0.55;
      return Rect.fromCenter(center: rect.center, width: side, height: side);
    }

    var to = landing();
    if (!mounted || from == null || to == null) {
      if (mounted) setState(() => _flyingEntityId = null);
      await selected;
      return;
    }

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    final curve = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOutCubic,
    );
    final flight = OverlayEntry(
      builder: (_) => AnimatedBuilder(
        animation: curve,
        builder: (_, __) {
          to = landing() ?? to;
          final rect = Rect.lerp(from, to, curve.value)!;
          // The pregnancy's illustration hands over to the glowing baby, so
          // it fades as it lands; a baby's photo is the same picture.
          final opacity = isPregnancy
              ? 1 - ((controller.value - 0.65) / 0.35).clamp(0.0, 1.0)
              : 1.0;
          return Positioned.fromRect(
            rect: rect,
            child: IgnorePointer(
              child: Opacity(
                opacity: opacity,
                child: ClipOval(
                  child: Container(
                    color: _card,
                    padding: EdgeInsets.all(rect.width * 0.06),
                    child: _entityAvatar(baby),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );

    Overlay.of(context).insert(flight);
    await controller.forward();
    flight.remove();
    controller.dispose();
    if (mounted) setState(() => _flyingEntityId = null);
    await selected;
  }

  /// The card for the selection, growing in from its top edge — where the
  /// avatar that was tapped lands.
  Widget _expandIn({required Object key, required Widget child}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(key),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 460),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, -18 * (1 - t)),
          child: Transform.scale(
            scale: 0.94 + 0.06 * t,
            alignment: Alignment.topCenter,
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }

  /// The "+" that ends the avatar row; opens the add-baby sheet.
  Widget _buildAddBabyTile() {
    return GestureDetector(
      onTap: _addBabyFromHeader,
      child: SizedBox(
        width: 66,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _rose.withValues(alpha: 0.08),
                border: Border.all(color: _rose.withValues(alpha: 0.45)),
              ),
              child: Icon(Icons.add_rounded, color: _rose, size: 28),
            ),
            const SizedBox(height: 5),
            Text(
              'Add baby',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: _inkSoft,
              ),
            ),
          ],
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

  Widget _buildBabyJourneyView(BuildContext context) {
    final baby = _selectedBaby;
    if (baby == null) return _buildUnregisteredPregnancyView(context);
    final babyWeek = WeeklyBabyTalk.babyWeekOf(baby.deliveryDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // ─── BABY PROFILE ───
        BabyProfileCard(
          baby: baby,
          avatar: _entityAvatar(baby),
          avatarKey: _cardAvatarKey,
          avatarVisible: _flyingEntityId != baby.id,
          onEdit: () => _editBaby(baby),
        ),
        const SizedBox(height: 14),

        // ─── FEATURES ───
        // AlloCry, Feeding, and the full Vaccination and Milestones pages.
        BabyFeatureRow(onOpenTrack: (mode) => _openBabyCareTrack(baby, mode)),
        const SizedBox(height: 14),

        // ─── WEEKLY SUMMARY ───
        // The baby's week, said on selecting them, as for the pregnancy.
        if (babyWeek != null)
          WeeklySummaryCard(
            week: babyWeek,
            label: babyWeek == WeeklyBabyTalk.birthWeek
                ? 'Birth week'
                : 'Week ${babyWeek - WeeklyBabyTalk.birthWeek}',
          ),
        // Only while the week is being said; stops the voice.
        if (_weeklyPlaying) ...[
          _buildStopSpeakingButton(),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 4),

        // ─── VACCINATIONS ───
        // Every dose, swipeable: past to the left, still to come to the right,
        // opening on the latest one due.
        VaccinationCarousel(
          key: ValueKey('doses-${baby.id}'),
          doses: _selectedBabyDoses,
          onShowAll: () => _openBabyCareTrack(baby, BabyTrackMode.vaccinations),
          onDoseGiven: (dose, given) async {
            await BabyDbService.instance.markImmunizationGiven(
              dose.id,
              given ? DateTime.now() : null,
            );
            await _loadSelectedBabySchedule();
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 12),

        // ─── MILESTONES ───
        MilestoneCarousel(
          key: ValueKey('milestones-${baby.id}'),
          milestones: _selectedBabyMilestones,
          onShowAll: () => _openBabyCareTrack(baby, BabyTrackMode.milestones),
          onMilestoneReached: (milestone, reached) async {
            await BabyDbService.instance.setMilestoneAchieved(
              milestone.id,
              reached ? DateTime.now() : null,
            );
            await _loadSelectedBabySchedule();
            if (mounted) setState(() {});
          },
        ),
        const SizedBox(height: 20),

        // ─── MILESTONE TRAIN ───
        // In place of the talking banner: the baby rides a train of month
        // wagons, and the month picked shows its vaccinations and milestones
        // the way the ANC schedule lists visits.
        BabyGrowthTrack(
          baby: baby,
          doses: _selectedBabyDoses,
          milestones: _selectedBabyMilestones,
          showProgress: false,
          onDoseGiven: (dose, given) async {
            await BabyDbService.instance.markImmunizationGiven(
              dose.id,
              given ? DateTime.now() : null,
            );
            await _loadSelectedBabySchedule();
            if (mounted) setState(() {});
          },
          onMilestoneReached: (milestone, reached) async {
            await BabyDbService.instance.setMilestoneAchieved(
              milestone.id,
              reached ? DateTime.now() : null,
            );
            await _loadSelectedBabySchedule();
            if (mounted) setState(() {});
          },
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

  /// The full Vaccination or Milestones page; its changes show here on return.
  Future<void> _openBabyCareTrack(Baby baby, BabyTrackMode mode) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BabyCareTrackPage(babyId: baby.id, mode: mode),
      ),
    );
    await _loadSelectedBabySchedule();
    if (mounted) setState(() {});
  }

  Future<void> _editBaby(Baby baby) async {
    final id = await showBabyFormSheet(
      context,
      existing: baby,
      title: 'Edit baby',
    );
    if (id != null) await _loadAllPregnancyData();
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
