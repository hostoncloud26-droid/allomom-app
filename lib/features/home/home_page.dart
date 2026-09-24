import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/overview_section/daily_summary/daily_summary_section.dart';
import 'package:allomom/features/overview_section/day_overview_section.dart';
import 'package:allomom/components/day_date_selector.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/overview_section/todays_care/todocare_section.dart';
import 'package:allomom/features/home/widgets/cycle_summary_card.dart';
import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart' as health;
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/allobot/home_voice_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/narration_on_visible.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _carouselController;
  int _currentCarouselPage = 0;

  final ScrollController _scrollController = ScrollController();

  /// Day the overview section (vitals and nutrition) reports on.
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  /// The date strip is an overlay, never part of the scrolled content: it
  /// shows only once the overview section has reached the top.
  bool _showDateSelector = false;

  /// Sits on the overview section, so the overlay triggers off real layout
  /// rather than a guessed scroll offset.
  final GlobalKey _dateScopeAnchorKey = GlobalKey();

  /// AlloBot's proactive companion: greets her on open and works through the
  /// day's questions. Owned here so it lives as long as the screen.
  final HomeVoiceController _voice = HomeVoiceController();

  /// Whether the carousel has already slid off AlloBot onto the summary.
  bool _hasAdvancedToDailySummary = false;

  /// The baby's own line while the home greeting runs, then null.
  ///
  /// The hero card is AlloBot's mouthpiece for the rest of the session, so the
  /// greeting borrows it rather than owning it: three recorded lines on first
  /// arrival, and then the bubble goes back to whatever AlloBot is saying.
  String? _homeNarrationKey;

  /// Set once the greeting has run, so coming back to the tab does not replay
  /// it. The controller also skips keys it has already spoken; this keeps the
  /// card from flickering through them a second time.
  static bool _homeGreetingPlayed = false;

  /// Which journey's greeting to play.
  NarrationFlow get _flow {
    final session = MainController.instance;
    if (session.isPregnant) return NarrationFlow.pregnant;
    if (session.isNewMom) return NarrationFlow.newMom;
    return NarrationFlow.prePregnancy;
  }

  /// Welcome, the line that follows it, then the first question.
  ///
  /// Awaited line by line so the card's text keeps step with the audio, and
  /// AlloBot is held back until it finishes — two voices talking over each
  /// other on the first screen she sees is worse than a short wait.
  Future<void> _playHomeGreeting() async {
    if (_homeGreetingPlayed || !BackgroundAudioController.isReady) return;
    // Muted: hand straight over to AlloBot rather than flickering the card
    // through three lines nobody will hear.
    if (!BackgroundAudioController.to.isVoiceEnabled.value) return;
    _homeGreetingPlayed = true;

    final flow = _flow;
    for (final key in [
      flow.homeWelcome,
      flow.homeFollowUp,
      // What this screen is for, said once she has been welcomed to it.
      NarrationKeys.pgHomeOpen,
      flow.homeFirstQuestion,
    ]) {
      if (!mounted) return;
      setState(() => _homeNarrationKey = key);
      await BackgroundAudioController.to.playByKey(key);
    }

    if (mounted) setState(() => _homeNarrationKey = null);
  }

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _scrollController.addListener(_updateDateSelectorVisibility);
    _voice.addListener(_onVoiceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The baby says hello first, in her own recorded voice; AlloBot picks up
      // where it leaves off.
      await _playHomeGreeting();
      if (!mounted) return;
      final currentUserId = MainController.instance.userId;
      if (currentUserId.isNotEmpty &&
          HealthVitalsController.instance.userId != currentUserId) {
        HealthVitalsController.instance.setUserId(currentUserId);
      } else {
        HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
      }
    });
  }

  @override
  void dispose() {
    _carouselController.dispose();
    _scrollController.removeListener(_updateDateSelectorVisibility);
    _scrollController.dispose();
    _voice.removeListener(_onVoiceChanged);
    _voice.dispose();
    super.dispose();
  }

  void _updateDateSelectorVisibility() {
    final anchorContext = _dateScopeAnchorKey.currentContext;
    if (anchorContext == null) return;

    final box = anchorContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;

    final anchorTop = box.localToGlobal(Offset.zero).dy;
    final show = anchorTop <= MediaQuery.of(context).padding.top;

    if (show != _showDateSelector) {
      setState(() => _showDateSelector = show);
    }
  }

  void _onDateSelected(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    if (DateUtils.isSameDay(normalized, _selectedDate)) return;
    setState(() => _selectedDate = normalized);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDateSelectorVisibility();
    });
  }

  /// Rebuilds for the card, moves the carousel on when AlloBot is finished,
  /// and performs any navigation an answer asked for.
  void _onVoiceChanged() {
    if (!mounted) return;
    setState(() {});

    _syncCarouselWithVoice();

    final destination = _voice.consumeDestination();
    if (destination == null) return;

    // Deferred to after the frame: this fires from inside the controller's
    // notify, which can land mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _goTo(destination);
    });
  }

  /// Keeps the carousel in step with the conversation.
  ///
  /// A new question brings her back to AlloBot — which is what makes the ANC
  /// calendar's hand-off work, since that pops back here and the questions
  /// need to be in front of her. When the questions run out it slides on to
  /// the Daily Summary instead: a visible card with nothing left to ask means
  /// AlloBot has said its last word, and parking her there would hide the
  /// summary behind a finished conversation.
  void _syncCarouselWithVoice() {
    if (!_voice.isVisible) return;

    if (_voice.prompt != null) {
      _hasAdvancedToDailySummary = false;
      // Only when she is not already looking at it, so answering a question
      // does not animate the page she is on.
      if (_currentCarouselPage != _alloBotPageIndex) {
        _animateCarouselTo(_alloBotPageIndex);
      }
      return;
    }

    // Once only: otherwise every later rebuild would drag her off whatever
    // page she had swiped to.
    if (_hasAdvancedToDailySummary) return;
    _hasAdvancedToDailySummary = true;

    // The delay lets the last line be read, and spoken, before the page moves.
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (!mounted) return;
      // Nothing to move on from if she dismissed the card meanwhile.
      if (!_voice.isVisible) return;
      _animateCarouselTo(_dailySummaryPageIndex);
    });
  }

  /// AlloBot's page, which leads the carousel while it is visible.
  int get _alloBotPageIndex => 0;

  /// The Daily Summary's page, which shifts by one when AlloBot is showing.
  int get _dailySummaryPageIndex => _voice.isVisible ? 1 : 0;

  void _animateCarouselTo(int page) {
    if (!_carouselController.hasClients) return;
    _carouselController.animateToPage(
      page,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _goTo(HomeVoiceDestination destination) {
    final Widget page = switch (destination) {
      HomeVoiceDestination.kickCounter => const KickCounterPage(),
      HomeVoiceDestination.reportUpload => const ReportsPage(),
      // Sleep and symptoms are both logged from My Health.
      HomeVoiceDestination.sleepLog => const health.MyHealthPage(),
      HomeVoiceDestination.symptomLog => const health.MyHealthPage(),
    };
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// What the baby card's bubble says.
  ///
  /// AlloBot's current line while it is talking, and the plain greeting
  /// otherwise. Long lines are trimmed: the bubble is a fixed shape over the
  /// illustration, and the full text is on the card below it anyway.
  String _babyBubbleText(MainController session, bool isPregnant, String name) {
    if (_voice.isVisible) {
      final spoken = _voice.prompt?.question ?? _voice.message;
      return spoken.length > 90 ? '${spoken.substring(0, 88)}…' : spoken;
    }

    if (isPregnant) return "Good Morning, $name ❤️";
    if (session.isNewMom) {
      return "Hello, $name 💕\nHow are you and baby doing?";
    }
    return "Welcome, $name 💕\nReady to start your care journey?";
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MainController.instance,
      builder: (context, child) {
        final session = MainController.instance;
        final isPregnant = session.isPregnant;
        final name = session.userName;

        return Scaffold(
          backgroundColor: context.palette.scaffoldSoft,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
            CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // No name-and-due-date header. Week, trimester and the
                      // due date are all spelled out on the Daily Summary card
                      // a scroll below, and saying them twice pushed the baby
                      // — the thing she actually talks to — down the screen.
                      const SizedBox(height: 10),

                      // ─── HERO BABY CARD ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BabyHeroBanner(
                          // The bubble carries whatever AlloBot is saying, so
                          // the words come from the baby that is speaking them
                          // rather than from a card elsewhere on the page.
                          //
                          // While the recorded greeting runs, `narrationKey`
                          // takes the bubble over; the controller plays the
                          // lines, so the card itself does not autoplay.
                          narrationKey: _homeNarrationKey,
                          autoPlayNarration: false,
                          speechText: _babyBubbleText(
                            session,
                            isPregnant,
                            name,
                          ),
                          greetingText: "",
                          bubblePosition: SpeechBubblePosition.topCenter,
                          height: 270,
                          showBackground: false,
                          onSpeakerTap: _homeNarrationKey != null
                              ? null
                              : (_voice.isVisible ? _voice.toggleSpeech : null),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const KickCounterPage(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ─── SWIPEABLE CAROUSEL (DAILY SUMMARY, QUICK ACTIONS) ───
                      //
                      // Each section says what it is the first time it is
                      // actually on screen, and never over the top of the one
                      // before it. Scrolling straight past says nothing.
                      NarrationOnVisible(
                        narrationKey: NarrationKeys.pgHomeSummary,
                        child: _buildSummaryCarousel(context),
                      ),
                      const SizedBox(height: 20),

                      // ─── TODAY'S CARE ───
                      NarrationOnVisible(
                        narrationKey: NarrationKeys.pgHomeCare,
                        child: _buildTodaysCareSection(context),
                      ),
                      const SizedBox(height: 24),

                      // ─── OVERVIEW (VITALS & NUTRITION TILES) ───
                      // Everything in here reports on the selected day; the
                      // date strip that drives it rides above as an overlay.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DayOverviewSection(
                          key: _dateScopeAnchorKey,
                          date: _selectedDate,
                        ),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),

            // ─── Sticky date selector (overlay only) ───
            // SafeArea already keeps the status bar clear, so the strip
            // starts at the top of the safe area with no scrim.
            StickyDateSelectorOverlay(
              visible: _showDateSelector,
              top: 0,
              selectedDate: _selectedDate,
              onDateSelected: _onDateSelected,
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HEADER / APP BAR ─────────────────────────────────────
  // ─── SWIPEABLE SUMMARY CAROUSEL ────────────────────────────
  Widget _buildSummaryCarousel(BuildContext context) {
    final pages = <Widget>[
      _buildDailySummaryCard(),
      _buildQuickActionsCard(context),
    ];

    return Column(
      children: [
        SizedBox(
          height: 345,
          child: PageView(
            controller: _carouselController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            children: pages,
          ),
        ),
        const SizedBox(height: 16),

        // Carousel Dot Indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pages.length, (index) {
            final isActive = _currentCarouselPage == index;
            return GestureDetector(
              onTap: () {
                _carouselController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                height: 6,
                width: isActive ? 24 : 6,
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFFF3B5C)
                      : context.palette.pick(
                          const Color(0xFFE2E4E9),
                          const Color(0xFF3A3A40),
                        ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─── GENERAL SUMMARY CARD (pregnancy completed / deleted) ──
  Widget _buildGeneralSummaryCard(MainController session) {
    final isNewMom = session.isNewMom;
    final days = session.daysSinceDelivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: context.palette.pick(
              const Color(0xFFF0F1F5),
              context.palette.border,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.palette.pick(
                Colors.black.withValues(alpha: 0.03),
                context.palette.shadow,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isNewMom
                      ? Icons.child_friendly_rounded
                      : Icons.favorite_rounded,
                  color: const Color(0xFFFF3B5C),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  isNewMom ? 'POSTPARTUM CARE' : 'MY HEALTH',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF3B5C),
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                if (isNewMom && days != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.palette.tint(
                        const Color(0xFFFF3B5C),
                        const Color(0xFFFFF0F4),
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      days == 0 ? 'Day 1' : 'Day $days',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF3B5C),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            const DailySummarySection(showHeading: false),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _buildGeneralAction(
                    icon: Icons.monitor_heart_rounded,
                    label: 'Health',
                    color: const Color(0xFF3898EC),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyHealthPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Periods return after delivery, so postpartum is exactly when
                // she starts wondering about her cycle again.
                Expanded(
                  child: _buildGeneralAction(
                    icon: Icons.water_drop_rounded,
                    label: 'Cycle',
                    color: const Color(0xFFFF4E6A),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CycleTrackerPage(),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGeneralAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: isNewMom ? 'Pregnancy' : 'Register',
                    color: const Color(0xFFFF3B5C),
                    onTap: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PregnancyConfirmationPage(),
                        ),
                      );
                      if (created == true && mounted) setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGeneralAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DAILY SUMMARY CARD ────────────────────────────────────
  Widget _buildDailySummaryCard() {
    final session = MainController.instance;
    final isPregnant = session.isPregnant;
    final gestationalWeek = session.currentGestationalWeek;
    final trimester = session.currentTrimester;
    final daysLeft = session.daysLeftUntilEdd;
    final eddFormatted = session.formattedEddDate;
    final eddFormattedFull = session.formattedEddDateFull;

    // Three distinct states: pregnant, a finished journey (general summary),
    // and not pregnant (her cycle).
    if (!isPregnant && session.hasPregnancyHistory) {
      return _buildGeneralSummaryCard(session);
    }

    if (!isPregnant) {
      // There is no pregnancy to count down, so the slot goes to the thing
      // that does move week to week for her — her cycle. Registering a
      // pregnancy stays one tap away inside the card.
      return CycleSummaryCard(
        prediction: session.cyclePrediction,
        onChanged: () {
          if (mounted) setState(() {});
        },
        onRegisterPregnancy: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const PregnancyConfirmationPage(),
            ),
          );
          if (created == true && mounted) setState(() {});
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: context.palette.pick(
              const Color(0xFFF0F1F5),
              context.palette.border,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.palette.pick(
                Colors.black.withValues(alpha: 0.03),
                context.palette.shadow,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Red Star
                Row(
                  children: const [
                    Icon(
                      Icons.star_rounded,
                      color: Color(0xFFFF3B5C),
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'DAILY SUMMARY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF3B5C),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Title & Subtitle (Static wording filled with pregnancy data)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "You're doing well today.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You are in Week $gestationalWeek of your pregnancy ($trimester). Your estimated delivery is on $eddFormattedFull.",
                      style: TextStyle(
                        fontSize: 13,
                        color: context.palette.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 3 Rounded Stat Cards Row (Pregnancy Data)
                Row(
                  children: [
                    // Week of 40
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PregnancyJourneyPage(),
                            ),
                          );
                        },
                        child: _buildSummaryMetricChip(
                          bg: context.palette.tint(
                            const Color(0xFFFF4E6A),
                            const Color(0xFFFFF0F4),
                          ),
                          icon: Icons.favorite_rounded,
                          iconColor: const Color(0xFFFF4E6A),
                          value: 'Week $gestationalWeek',
                          label: 'Of 40 weeks',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Due Date
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PregnancyJourneyPage(),
                            ),
                          );
                        },
                        child: _buildSummaryMetricChip(
                          bg: context.palette.tint(
                            const Color(0xFF3898EC),
                            const Color(0xFFEDF6FF),
                          ),
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF3898EC),
                          value: eddFormatted,
                          label: 'Due Date',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Days Remaining
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PregnancyJourneyPage(),
                            ),
                          );
                        },
                        child: _buildSummaryMetricChip(
                          bg: context.palette.tint(
                            const Color(0xFFFF9438),
                            const Color(0xFFFFF6ED),
                          ),
                          icon: Icons.hourglass_bottom_rounded,
                          iconColor: const Color(0xFFFF9438),
                          value: '$daysLeft days',
                          label: 'Remaining',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Bottom CTA Button: My Pregnancy Journey
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PregnancyJourneyPage(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: context.palette.tint(
                    const Color(0xFFFF4E6A),
                    const Color(0xFFFFF0F4),
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_rounded,
                      color: Color(0xFFFF4E6A),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'My Pregnancy Journey',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.palette.textPrimary,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFFFF4E6A),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetricChip({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: context.palette.card,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textMuted,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── QUICK ACTIONS CARD (GRID OF ALL FEATURES) ─────────────
  Widget _buildQuickActionsCard(BuildContext context) {
    final session = MainController.instance;
    final isPregnant = session.isPregnant;

    // Kick counting is a pregnancy tool: there is nothing to count once the
    // baby is born, so its slot goes to the journey — which is the only place
    // a mother who is not pregnant can reach it from home, the summary card
    // beside this one having turned into her cycle.
    final journeyOrKicks = isPregnant
        ? {
            'title': 'Kick Count',
            'subtitle': 'Fetal Tracker',
            'icon': Icons.pets_rounded,
            'color': const Color(0xFFFF4E6A),
            'bg': const Color(0xFFFFF0F4),
            'page': const KickCounterPage(),
          }
        : {
            'title': session.hasKids ? 'Baby Journey' : 'My Journey',
            'subtitle': session.hasKids ? 'Care & Growth' : 'Pregnancy Care',
            'icon': Icons.child_care_rounded,
            'color': const Color(0xFFFF4E6A),
            'bg': const Color(0xFFFFF0F4),
            'page': const PregnancyJourneyPage(),
          };

    final features = [
      {
        'title': 'AlloCry',
        'subtitle': 'Cry Analyzer',
        'icon': Icons.graphic_eq_rounded,
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF7F4FF),
        'page': const AlloCryPage(),
      },
      journeyOrKicks,
      {
        'title': 'Prescription',
        'subtitle': 'Medications',
        'icon': Icons.medication_rounded,
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
        'page': const PrescriptionsPage(),
      },
      {
        'title': 'Reports',
        'subtitle': 'Lab & Scans',
        'icon': Icons.description_rounded,
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'page': const ReportsPage(),
      },
      {
        'title': 'Feeding',
        'subtitle': 'Baby Nutrition',
        'icon': Icons.child_care_rounded,
        'color': const Color(0xFFF59E0B),
        'bg': const Color(0xFFFFF7ED),
        'page': const FeedingTrackerPage(),
      },
      {
        'title': 'My Health',
        'subtitle': 'Vitals & Care',
        'icon': Icons.favorite_rounded,
        'color': const Color(0xFFFF3B5C),
        'bg': const Color(0xFFFFF0F4),
        'page': const MyHealthPage(),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.palette.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: context.palette.pick(
              const Color(0xFFF0F1F5),
              context.palette.border,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: context.palette.pick(
                Colors.black.withValues(alpha: 0.03),
                context.palette.shadow,
              ),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Grid Icon
            Row(
              children: [
                const Icon(
                  Icons.grid_view_rounded,
                  color: Color(0xFF6366F1),
                  size: 16,
                ),
                const SizedBox(width: 6),
                const Text(
                  'QUICK ACTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6366F1),
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 3-column x 2-row Grid
            Expanded(
              child: Column(
                children: [
                  for (int row = 0; row < 2; row++) ...[
                    if (row > 0) const SizedBox(height: 12),
                    Expanded(
                      child: Row(
                        children: [
                          for (int col = 0; col < 3; col++) ...[
                            if (col > 0) const SizedBox(width: 10),
                            Expanded(
                              child: _buildFullGridFeatureItem(
                                context,
                                features[row * 3 + col],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullGridFeatureItem(
    BuildContext context,
    Map<String, dynamic> f,
  ) {
    final title = f['title'] as String;
    final subtitle = f['subtitle'] as String;
    final icon = f['icon'] as IconData;
    final color = f['color'] as Color;
    final bg = f['bg'] as Color;
    final page = f['page'] as Widget?;

    return GestureDetector(
      onTap: () {
        if (page != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        }
      },
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: context.palette.pick(
            bg.withValues(alpha: 0.5),
            color.withValues(alpha: 0.12),
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: context.palette.pick(bg, color.withValues(alpha: 0.25)),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.palette.card,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, color: color, size: 22)),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.palette.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: context.palette.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TODAY'S CARE ─────────────────────────────────────────
  Widget _buildTodaysCareSection(BuildContext context) {
    return const TodocareSection();
  }
}
