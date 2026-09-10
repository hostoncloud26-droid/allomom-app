import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/overview_section/daily_summary/daily_summary_section.dart';
import 'package:allomom/features/overview_section/overview_section_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/overview_section/todays_care/todocare_section.dart';
import 'package:allomom/features/home/widgets/allo_voice_prompt_card.dart';
import 'package:allomom/features/my_health/my_health_page.dart' as health;
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/allobot/home_voice_controller.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _carouselController;
  int _currentCarouselPage = 0;

  /// AlloBot's proactive companion: greets her on open and works through the
  /// day's questions. Owned here so it lives as long as the screen.
  final HomeVoiceController _voice = HomeVoiceController();

  /// Whether the carousel has already slid off AlloBot onto the summary.
  bool _hasAdvancedToDailySummary = false;

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  @override
  void initState() {
    super.initState();
    _carouselController = PageController();
    _voice.addListener(_onVoiceChanged);
    HomeVoiceLauncher.instance.ancFollowUpRequests
        .addListener(_onAncFollowUpRequested);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Greets and asks the first question. Deliberately not awaited: the
      // screen renders immediately and the card appears when it is ready.
      _voice.start();
      final currentUserId = UserSessionManager.instance.userId;
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
    _voice.removeListener(_onVoiceChanged);
    HomeVoiceLauncher.instance.ancFollowUpRequests
        .removeListener(_onAncFollowUpRequested);
    _voice.dispose();
    super.dispose();
  }

  /// Runs the post-visit questions when the ANC calendar asks for them.
  void _onAncFollowUpRequested() {
    if (!mounted) return;
    _voice.startAncFollowUp();
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
  String _babyBubbleText(
    UserSessionManager session,
    bool isPregnant,
    String name,
  ) {
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

  /// The AlloBot page of the carousel.
  ///
  /// Inline rather than a dialog: a mother opening the app should see her
  /// screen, not a stack of modals, and every one of these questions is about
  /// something the page behind it displays.
  ///
  /// `fillHeight` makes it the same size as the Daily Summary card next to it,
  /// rather than shrinking to its content and leaving a gap above the dots.
  /// The message inside scrolls if it is long, so the answer buttons stay put.
  Widget _buildVoicePromptCard() {
    return AlloVoicePromptCard(
      fillHeight: true,
      message: _voice.message,
      prompt: _voice.prompt,
      isSpeaking: _voice.isSpeaking,
      onYes: () => _voice.answerYesNo(true),
      onNo: () => _voice.answerYesNo(false),
      onPickDate: _voice.answerDate,
      onSubmitText: _voice.answerText,
      onDismiss: _voice.dismiss,
      onSpeakerTap: _voice.toggleSpeech,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserSessionManager.instance,
      builder: (context, child) {
        final session = UserSessionManager.instance;
        final isPregnant = session.isPregnant;
        final name = session.userName;
        final week = session.currentGestationalWeek;
        final trimester = session.currentTrimester;
        final edd =
            session.eddDate ?? DateTime.now().add(const Duration(days: 112));
        final dueDay = edd.day.toString();
        final dueMonth = _shortMonths[edd.month - 1].toUpperCase();

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFC),
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(
                        context,
                        session,
                        name,
                        isPregnant,
                        week,
                        trimester,
                        dueDay,
                        dueMonth,
                      ),
                      const SizedBox(height: 10),

                      // ─── HERO BABY CARD ───
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BabyHeroBanner(
                          // The bubble carries whatever AlloBot is saying, so
                          // the words come from the baby that is speaking them
                          // rather than from a card elsewhere on the page.
                          speechText: _babyBubbleText(session, isPregnant, name),
                          greetingText: "",
                          bubblePosition: SpeechBubblePosition.topCenter,
                          height: 270,
                          onSpeakerTap:
                              _voice.isVisible ? _voice.toggleSpeech : null,
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

                      // ─── SWIPEABLE CAROUSEL (ALLOBOT, DAILY SUMMARY, QUICK ACTIONS) ───
                      _buildSummaryCarousel(context),
                      const SizedBox(height: 20),

                      // ─── TODAY'S CARE ───
                      _buildTodaysCareSection(context),
                      const SizedBox(height: 24),

                      // ─── OVERVIEW (VITALS & NUTRITION TILES) ───
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: OverviewSectionPage(),
                      ),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── HEADER / APP BAR ─────────────────────────────────────
  Widget _buildHeader(
    BuildContext context,
    UserSessionManager session,
    String userName,
    bool isPregnant,
    int week,
    String trimester,
    String dueDay,
    String dueMonth,
  ) {
    final firstName = userName.split(' ').first;

    // Three states to describe: currently pregnant, recently delivered, and
    // no pregnancy on record. Only the last one should say "Register".
    final isNewMom = session.isNewMom;
    final daysSince = session.daysSinceDelivery;
    final postpartumDay = daysSince == null || daysSince == 0 ? 1 : daysSince;

    final subtitle = isPregnant
        ? 'Week $week · $trimester'
        : isNewMom
        ? 'Day $postpartumDay postpartum'
        : 'Maternal Care Journey';

    final badgeLabel = isPregnant
        ? 'DUE DATE'
        : isNewMom
        ? 'POSTPARTUM'
        : 'CARE';

    final badgeValue = isPregnant
        ? '$dueDay $dueMonth'
        : isNewMom
        ? 'Day $postpartumDay'
        : 'Register';

    // A finished journey still has a page worth opening (past pregnancies),
    // so only send a brand-new user straight to registration.
    Widget headerDestination() => isPregnant || session.hasPregnancyHistory
        ? const PregnancyJourneyPage()
        : const PregnancyConfirmationPage();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Profile Avatar with green online dot
          Stack(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF0E1013),
                ),
                child: Center(
                  child: Text(
                    firstName.isNotEmpty ? firstName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User Name & Trimester in one line
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => headerDestination()),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF8E95A5),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Due Date / Register Badge Card
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => headerDestination()),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    badgeLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E95A5),
                      letterSpacing: 0.6,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    badgeValue,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF3B5C),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── SWIPEABLE SUMMARY CAROUSEL ────────────────────────────
  Widget _buildSummaryCarousel(BuildContext context) {
    // AlloBot leads the carousel while it has something to say, so the first
    // thing she swipes through is the conversation about her day; the summary
    // and the shortcuts sit behind it.
    final pages = <Widget>[
      if (_voice.isVisible) _buildVoicePromptCard(),
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
                      : const Color(0xFFE2E4E9),
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
  Widget _buildGeneralSummaryCard(UserSessionManager session) {
    final isNewMom = session.isNewMom;
    final days = session.daysSinceDelivery;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                      color: const Color(0xFFFFF0F4),
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
                    label: 'My health',
                    color: const Color(0xFF3898EC),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MyHealthPage()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildGeneralAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: isNewMom ? 'New pregnancy' : 'Register',
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
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── DAILY SUMMARY CARD ────────────────────────────────────
  Widget _buildDailySummaryCard() {
    final session = UserSessionManager.instance;
    final isPregnant = session.isPregnant;
    final gestationalWeek = session.currentGestationalWeek;
    final trimester = session.currentTrimester;
    final daysLeft = session.daysLeftUntilEdd;
    final eddFormatted = session.formattedEddDate;
    final eddFormattedFull = session.formattedEddDateFull;

    // Three distinct states: pregnant, a finished journey (general summary),
    // and never registered (the invitation to register).
    if (!isPregnant && session.hasPregnancyHistory) {
      return _buildGeneralSummaryCard(session);
    }

    if (!isPregnant) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F4), Colors.white],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFFFDCE4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3B5C).withValues(alpha: 0.05),
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
                  Row(
                    children: const [
                      Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFFF3B5C),
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'PREGNANCY JOURNEY',
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
                  const Text(
                    "Start your care journey",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Register your pregnancy to track weekly baby development, doctor visits, and vaccination schedules.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFFFF0F4),
                          icon: Icons.child_care_rounded,
                          iconColor: const Color(0xFFFF4E6A),
                          value: '40 Weeks',
                          label: 'Timeline',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFEDF6FF),
                          icon: Icons.calendar_month_rounded,
                          iconColor: const Color(0xFF3898EC),
                          value: 'ANC Visits',
                          label: 'Schedules',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildSummaryMetricChip(
                          bg: const Color(0xFFECFDF5),
                          icon: Icons.vaccines_rounded,
                          iconColor: const Color(0xFF10B981),
                          value: 'Vaccines',
                          label: 'Alerts',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PregnancyConfirmationPage(),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B5C),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Register Pregnancy',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
                    const Text(
                      "You're doing well today.",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "You are in Week $gestationalWeek of your pregnancy ($trimester). Your estimated delivery is on $eddFormattedFull.",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
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
                          bg: const Color(0xFFFFF0F4),
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
                          bg: const Color(0xFFEDF6FF),
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
                          bg: const Color(0xFFFFF6ED),
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
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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
                        color: Color(0xFF1E2024),
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
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 15),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF8A90A0),
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
    final session = UserSessionManager.instance;
    final isPregnant = session.isPregnant;

    // Kick counting is a pregnancy tool: there is nothing to count once the
    // baby is born, so its slot goes to the journey — which is the only place
    // a mother who is not pregnant can reach it from home, the summary card
    // beside this one having turned into a "Register Pregnancy" prompt.
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
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
          color: bg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bg, width: 1.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF8E95A5),
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
