import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
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
import 'package:allomom/controllers/baby_controller.dart';
import 'package:allomom/features/home/widgets/pregnancy_home_cards.dart';
import 'package:allomom/features/home/allobaby_flow_controller.dart';
import 'package:allomom/features/allobot/allobot_page.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/allobot/widgets/allobot_home_view.dart';
import 'package:allomom/features/allobot/widgets/allobot_welcome_view.dart'
    show GradientText;
import 'package:allomom/services/speech_activity.dart';
import 'package:allomom/services/tts_service.dart';
import 'package:allomom/features/allobot/data/allobot_feature_catalog.dart';
import 'package:allomom/features/cycle_tracker/cycle_tracker_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart' as health;
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/allobot/home_voice_controller.dart';
import 'package:allomom/features/pregnancy/data/weekly_baby_talk.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';

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

  /// Today's Care, which the "right now" card scrolls down to.
  final GlobalKey _todaysCareKey = GlobalKey();

  /// AlloBot's proactive companion: greets her on open and works through the
  /// day's questions. Owned here so it lives as long as the screen.
  final HomeVoiceController _voice = HomeVoiceController();

  /// Whether the carousel has already slid off AlloBot onto the summary.
  bool _hasAdvancedToDailySummary = false;

  /// Ask Allo's opening flow, run in the AlloBaby card once the week has been
  /// said. Static so the card keeps its last line when she comes back to Home.
  static final AlloBabyFlowController _alloBaby = AlloBabyFlowController();

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

  /// The last line the baby said while Home was in front — the bubble only
  /// ever shows what she actually said, never a canned greeting. Static so a
  /// revisit picks up her last line instead of an empty bubble.
  static String _lastSpokenText = '';

  /// Ask Allo's "Try asking" questions, drawn once the catalogue is ready.
  List<String> _trySuggestions = const [];

  /// Keeps [_lastSpokenText] and the bubble in step with the player.
  final List<Worker> _audioWorkers = [];

  /// Whether the greeting is going to play on this visit.
  bool get _greetingWillPlay =>
      !_homeGreetingPlayed &&
      BackgroundAudioController.isReady &&
      BackgroundAudioController.to.isVoiceEnabled.value;

  /// This week's AlloBot flow, `pregnancy_week_<n>_info`, as keys the global
  /// voice can play — one per step, each with its text registered for the
  /// bubble and the clip the flow named for it (Amma's or Appa's, by who is
  /// signed in). Empty when there is no week or the catalogue lacks the intent.
  Future<List<String>> _weeklyInfoKeys() async {
    final week = WeeklyBabyTalk.currentWeek();
    if (week == null) return const [];
    final lines = await WeeklyBabyTalk.lines(week);
    final audio = BackgroundAudioController.to;
    final base = WeeklyBabyTalk.intentKey(week);
    return [
      for (var i = 0; i < lines.length; i++)
        () {
          final key = '$base#$i';
          audio.registerText(key, lines[i].text, audioUrl: lines[i].audioUrl);
          return key;
        }(),
    ];
  }

  Future<void> _playHomeGreeting() async {
    if (!_greetingWillPlay) return;
    _homeGreetingPlayed = true;

    // Only what the AlloBot flows say, in their own recordings (or TTS when
    // a clip will not play) — none of the bundled asset narration: the week's
    // flow while its card is on screen, then AlloBaby's opening flow.
    final weeklyKeys = await _weeklyInfoKeys();
    for (final key in weeklyKeys) {
      if (!mounted || _greetingCancelled) return;
      setState(() => _homeNarrationKey = key);
      await BackgroundAudioController.to.playByKey(key);
      // The week has been said: AlloBaby picks up in her own card, and the
      // page turns to today once she has finished.
      if (key == weeklyKeys.last) {
        await _runAlloBabyFlow();
        if (!mounted || _greetingCancelled) return;
        _advanceToTodayOnce(const Duration(milliseconds: 800));
      }
    }
    if (_greetingCancelled) return;

    if (mounted) setState(() => _homeNarrationKey = null);
  }

  Future<void> _loadTrySuggestions() async {
    final chatbot = OfflineChatbotController.instance;
    await chatbot.ready;
    if (!mounted) return;
    setState(() => _trySuggestions = alloBotOpeningSuggestions(chatbot));
  }

  /// A "Try asking" chip: whatever is talking stands down and AlloBaby
  /// answers the question in the hero, as Ask Allo would.
  void _askAlloBaby(String question) {
    _greetingCancelled = true;
    if (BackgroundAudioController.isReady) BackgroundAudioController.to.stop();
    _voice.dismiss();
    setState(() {
      _homeNarrationKey = null;
      _lastSpokenText = '';
    });
    _alloBaby.answer(question);
  }

  /// Runs AlloBaby's opening flow in the hero, returning once it has been said
  /// (or stopped).
  Future<void> _runAlloBabyFlow() async {
    if (!mounted || !_hasWeekCards) return;
    // AlloBaby's words take over the hero; the week's last line would
    // otherwise come back once she finishes.
    setState(() {
      _homeNarrationKey = null;
      _lastSpokenText = '';
    });
    await _alloBaby.start();
  }

  /// Redraws the hero as AlloBaby starts and stops talking.
  void _onAlloBabyChanged() {
    if (mounted) setState(() {});
  }

  /// Whether AlloBaby's voice is sounding right now — the baby card's mouth
  /// follows it.
  bool get _alloBabySpeaking => _alloBaby.isRunning && TtsService().isSpeaking;

  /// The docked mic was tapped to silence her: the rest of the greeting, the
  /// AlloBaby flow and AlloBot all stand down.
  void _onStopRequested() {
    if (!mounted) return;
    _greetingCancelled = true;
    _alloBaby.stop();
    if (_voice.isSpeaking) _voice.toggleSpeech();
    setState(() => _homeNarrationKey = null);
  }

  @override
  void initState() {
    super.initState();
    SpeechActivity.instance.stopRequests.addListener(_onStopRequested);
    _alloBaby.addListener(_onAlloBabyChanged);
    TtsService().isSpeakingNotifier.addListener(_onAlloBabyChanged);
    final reopen = _weekShownThisSession && _hasWeekCards;
    _currentCarouselPage = reopen ? _todayPageIndex : 0;
    _hasAdvancedToDailySummary = reopen;
    _carouselController = PageController(initialPage: _currentCarouselPage);
    _scrollController.addListener(_updateDateSelectorVisibility);
    _voice.addListener(_onVoiceChanged);
    _loadTrySuggestions();
    if (BackgroundAudioController.isReady) {
      final audio = BackgroundAudioController.to;
      _audioWorkers
        ..add(ever<String>(audio.currentText, _onNarrationText))
        ..add(ever<bool>(audio.isPlaying, (_) => _onNarrationState()));
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // The baby says hello first, in her own recorded voice; AlloBot picks up
      // where it leaves off.
      // Long enough to take in the week, short enough that today is still
      // the first thing she really reads.
      //
      // When the baby is about to read the week out, the page waits for her
      // instead; the greeting turns it once the week's line is done.
      final holdForWeek = _greetingWillPlay;
      if (!holdForWeek) _advanceToTodayOnce(const Duration(seconds: 8));
      await _playHomeGreeting();
      // No weekly line after all, or she closed the bubble: move on anyway.
      if (holdForWeek) _advanceToTodayOnce(const Duration(seconds: 2));
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
    SpeechActivity.instance.stopRequests.removeListener(_onStopRequested);
    _alloBaby.removeListener(_onAlloBabyChanged);
    TtsService().isSpeakingNotifier.removeListener(_onAlloBabyChanged);
    // Leaving Home for another tab: the card's voice should not follow her.
    _alloBaby.stop();
    _carouselController.dispose();
    _scrollController.removeListener(_updateDateSelectorVisibility);
    _scrollController.dispose();
    _voice.removeListener(_onVoiceChanged);
    _voice.dispose();
    for (final worker in _audioWorkers) {
      worker.dispose();
    }
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

  /// When AlloBot runs out of questions, move on from the week to today —
  /// its last word is the natural moment to turn the page.
  void _syncCarouselWithVoice() {
    if (!_voice.isVisible || _voice.prompt != null) return;
    _advanceToTodayOnce(const Duration(milliseconds: 1800));
  }

  /// Her LMP, for the week and day cards. Worked back from the due date when
  /// only that was entered; null when she is not pregnant or gave neither.
  DateTime? get _guideLmp {
    final session = MainController.instance;
    if (!session.isPregnant) return null;
    return session.lmpDate ??
        session.eddDate?.subtract(const Duration(days: 280));
  }

  /// The baby's week (41–142) when she is not pregnant but has a baby in the
  /// 1000 days; null otherwise.
  int? get _babyWeek => WeeklyBabyTalk.currentBabyWeek();

  /// Whether the carousel opens on a week card — her pregnancy's, or her
  /// baby's once it is born.
  bool get _hasWeekCards => _guideLmp != null || _babyWeek != null;

  /// The carousel opens on this week, then turns to today.
  static const _weekPageIndex = 0;

  /// Pregnancy: the week itself, while the Right now card is commented out
  /// (set back to 1 when it returns). Baby: the postpartum summary.
  int get _todayPageIndex => _babyWeek != null ? 1 : _weekPageIndex;

  /// Set once the week has had its moment on screen. Later visits in the same
  /// session open straight on today, which is what she comes back to check.
  static bool _weekShownThisSession = false;

  /// Slides from this week to today after [delay], once, and only if she is
  /// still looking at the week — never out from under a page she chose.
  void _advanceToTodayOnce(Duration delay) {
    if (_hasAdvancedToDailySummary || !_hasWeekCards) return;
    _hasAdvancedToDailySummary = true;
    _weekShownThisSession = true;
    Future.delayed(delay, () {
      if (!mounted) return;
      if (_currentCarouselPage != _weekPageIndex) return;
      _animateCarouselTo(_todayPageIndex);
    });
  }

  /// Brings Today's Care into view, where she can log what the card lists.
  // ignore: unused_element — used by the Right now card, hidden for now.
  void _scrollToTodaysCare() {
    final target = _todaysCareKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      // Just under the sticky date strip, which covers the top of the page.
      alignment: 0.05,
    );
  }

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

  /// Remembers a line when it starts, if Home is the screen she is saying it
  /// on.
  ///
  /// Only a change of line counts. Stopping does not: a page pushed over Home
  /// stops its own clip as it is popped, by which time Home is back on top —
  /// and treating that as Home's line left the other page's words in this
  /// bubble.
  void _onNarrationText(String line) {
    if (!mounted) return;
    final text = line.trim();
    final onTop = ModalRoute.of(context)?.isCurrent ?? true;
    if (text.isNotEmpty && onTop) _lastSpokenText = text;
    setState(() {});
  }

  /// Playing and stopping only redraw the card (speaking or not).
  void _onNarrationState() {
    if (mounted) setState(() {});
  }

  /// Set when the docked mic stops her mid-greeting, so the rest of the
  /// welcome is not played at her.
  bool _greetingCancelled = false;

  /// Whether one of the recorded narrations is playing.
  bool get _narrating {
    if (!BackgroundAudioController.isReady) return false;
    final audio = BackgroundAudioController.to;
    return audio.isPlaying.value && audio.currentKey.value.isNotEmpty;
  }

  /// Whether the baby in the orb is talking, whoever gave her the line.
  bool get _heroSpeaking =>
      _narrating || _alloBabySpeaking || _voice.isSpeaking;

  /// What the hero shows under the orb: only ever a line that was spoken.
  ///
  /// AlloBaby's step while her flow runs; otherwise a recorded narration (the
  /// week's lines) while it plays, AlloBot's current line while it is
  /// talking, and then the last thing said here — falling back to AlloBaby's
  /// last word. Empty before anything has been said.
  String _heroLine() {
    if (_alloBaby.isRunning) return _alloBaby.line;
    final spoken = !_narrating && _voice.isVisible
        ? (_voice.prompt?.question ?? _voice.message)
        : _lastSpokenText;
    return spoken.isNotEmpty ? spoken : _alloBaby.line;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: MainController.instance,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: context.palette.scaffoldSoft,
          body: SafeArea(
            bottom: false,
            child: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, viewport) => CustomScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ─── FIRST SCREEN, AS ON ASK ALLO ───
                            // The baby and her line centred in the room above,
                            // Try asking and Quick Actions resting just over the
                            // docked mic; Today's Care is a scroll away.
                            _buildFirstScreen(context, viewport.maxHeight),

                            // ─── SWIPEABLE CAROUSEL (THIS WEEK, RIGHT NOW) ───
                            //
                            // Each section says what it is the first time it is
                            // actually on screen, and never over the top of the one
                            // before it. Scrolling straight past says nothing.
                            // Hidden for now — the hero carries the week's
                            // lines. Restore with the carousel builder below.
                            // _buildSummaryCarousel(context),
                            // const SizedBox(height: 20),

                            // ─── TODAY'S CARE ───
                            KeyedSubtree(
                              key: _todaysCareKey,
                              child: _buildTodaysCareSection(context),
                            ),
                            const SizedBox(height: 24),

                            // ─── OVERVIEW (VITALS & NUTRITION TILES) ───
                            // Everything in here reports on the selected day; the
                            // date strip that drives it rides above as an overlay.
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
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
  // ─── FIRST SCREEN ──────────────────────────────────────────
  /// At least a screen tall: the hero centred in the space above, Try asking
  /// and Quick Actions at the bottom, clear of the bar and the docked mic.
  Widget _buildFirstScreen(BuildContext context, double viewportHeight) {
    // The body runs under the bar (the layout extends it), which the bottom
    // padding carries; the mic stands about 50px above the bar on top of that.
    final micClearance = MediaQuery.paddingOf(context).bottom + 56;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: viewportHeight),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Center(child: _buildAlloBabyHero(context)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              _buildTryAsking(context),
              const SizedBox(height: 32),
              _buildQuickActionsCard(context),
              SizedBox(height: micClearance),
            ],
          ),
        ],
      ),
    );
  }

  // ─── ALLOBABY HERO ─────────────────────────────────────────
  /// Ask Allo's orb and gradient line, with AlloBaby's choices under it once
  /// her flow is waiting on one, and a way to hear her or keep talking.
  Widget _buildAlloBabyHero(BuildContext context) {
    final line = _heroLine().trim();
    final speaking = _heroSpeaking;
    final busy = speaking || _alloBaby.isRunning || _homeNarrationKey != null;
    final options = busy ? const <String>[] : _alloBaby.options;

    final Widget text = line.isEmpty
        ? GradientText(
            key: const ValueKey('hello'),
            text: 'Hello! I am AlloBaby',
            gradient: alloBotHeroGradient,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          )
        : AlloBotHeroLine(key: ValueKey(line), text: line, maxHeight: 180);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            width: 200,
            height: 200,
            child: FittedBox(
              child: AlloBotGeminiOrb(
                isSpeaking: speaking,
                isThinking: _alloBaby.isRunning && !speaking,
                babySize: 190,
              ),
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: text,
            ),
          ),
          if (options.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final option in options)
                  AlloBotSuggestionChip(text: option, onTap: _alloBaby.answer),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ─── TRY ASKING ────────────────────────────────────────────
  /// Ask Allo's "Try asking" row; a chip is answered in the hero above.
  Widget _buildTryAsking(BuildContext context) {
    if (_trySuggestions.isEmpty) return const SizedBox.shrink();
    final isDark = context.palette.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Try asking:',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final text in _trySuggestions)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: AlloBotSuggestionChip(text: text, onTap: _askAlloBaby),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ignore: unused_element — the week carousel, hidden for now.
  Widget _buildSummaryCarousel(BuildContext context) {
    final session = MainController.instance;
    final lmp = _guideLmp;
    final babyWeek = lmp == null ? _babyWeek : null;
    final babyBirth = babyWeek == null ? null : WeeklyBabyTalk.youngestBirth();
    final pages = <Widget>[
      if (babyWeek != null && babyBirth != null) ...[
        // Her pregnancy's week card, carried on after the birth.
        BabyWeekCard(
          week: babyWeek,
          birth: babyBirth,
          babyName: BabyController.instance.youngest?.name,
          onOpenJourney: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PregnancyJourneyPage()),
          ),
        ),
        _buildDailySummaryCard(),
      ] else if (lmp != null) ...[
        PregnancyWeekCard(
          week: session.currentGestationalWeek,
          trimester: session.currentTrimester,
          daysLeft: session.daysLeftUntilEdd,
          onOpenJourney: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PregnancyJourneyPage()),
          ),
        ),
        // Right now card hidden for now. Restore it together with
        // `_todayPageIndex = 1` below.
        // RightNowCareCard(onOpenCare: _scrollToTodaysCare),
      ] else
        _buildDailySummaryCard(),
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
        // Dots only when there is somewhere to swipe to.
        if (pages.length > 1) ...[
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
                    const SizedBox(width: 8),

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
                    const SizedBox(width: 8),

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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: context.palette.card,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: context.palette.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
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
        ? _quickAction(
            id: 'kick_counter',
            title: 'Kick Count',
            subtitle: 'Fetal Tracker',
            icon: Icons.pregnant_woman_rounded,
            color: const Color(0xFFFF4E6A),
            image: 'assets/Quick Actions/Kick Count.png',
            page: const KickCounterPage(),
          )
        : _quickAction(
            id: 'journey',
            title: session.hasKids ? 'Baby Journey' : 'My Journey',
            subtitle: session.hasKids ? 'Care & Growth' : 'Pregnancy Care',
            icon: session.hasKids
                ? Icons.child_friendly_rounded
                : Icons.pregnant_woman_rounded,
            color: const Color(0xFFFF8A5B),
            image: session.hasKids
                ? 'assets/allobaby/BabyCare.png'
                : 'assets/allobaby/Pregnancy Care.png',
            page: const PregnancyJourneyPage(),
          );

    // Illustrations from assets/Quick Actions/. The journey slot, which only
    // shows for a mother who is not pregnant, keeps its AlloBaby artwork.
    final features = [
      _quickAction(
        id: 'my_health',
        title: 'My Health',
        subtitle: 'Vitals & Care',
        icon: Icons.monitor_heart_rounded,
        color: const Color(0xFFFF4E6A),
        image: 'assets/Quick Actions/Health.png',
        page: const MyHealthPage(),
      ),
      _quickAction(
        id: 'allocry',
        title: 'AlloCry',
        subtitle: 'Cry Analyzer',
        icon: Icons.hearing_rounded,
        color: const Color(0xFF8B5CF6),
        image: 'assets/Quick Actions/AlloCry.png',
        page: const AlloCryPage(),
      ),
      journeyOrKicks,
      _quickAction(
        id: 'reports',
        title: 'Reports',
        subtitle: 'Lab & Scans',
        icon: Icons.biotech_rounded,
        color: const Color(0xFF3B82F6),
        image: 'assets/Quick Actions/Reports.png',
        page: const ReportsPage(),
      ),
      _quickAction(
        id: 'feeding_tracker',
        title: 'Feeding',
        subtitle: 'Baby Nutrition',
        icon: Icons.local_drink_rounded,
        color: const Color(0xFFF59E0B),
        image: 'assets/Quick Actions/Feeding.png',
        page: const FeedingTrackerPage(),
      ),
      _quickAction(
        id: 'prescriptions',
        title: 'Prescription',
        subtitle: 'Medications',
        icon: Icons.medication_rounded,
        color: const Color(0xFF6366F1),
        image: 'assets/Quick Actions/Prescriptions.png',
        page: const PrescriptionsPage(),
      ),
      // The trackers, straight from AlloBot's catalogue so they open the same
      // pages and carry the same art as the Agents tab.
      for (final id in _trackerActionIds) ?AlloBotFeatureCatalog.byId(id),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Color(0xFF6366F1), size: 16),
              SizedBox(width: 6),
              Text(
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
        ),
        const SizedBox(height: 16),

        // AlloConnect's Home slider: a row of small square boxes she swipes
        // through, about three on screen at a time.
        SizedBox(
          height: _quickActionSize,
          child: ListView.separated(
            clipBehavior: Clip.none,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: features.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: _quickActionSize,
              child: _QuickActionBox(
                feature: features[index],
                onTap: () =>
                    AlloBotFeatureCatalog.open(context, features[index]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Width and height of each Quick Actions box.
  static const _quickActionSize = 112.0;

  /// Trackers added after the headline features, in the order shown.
  static const _trackerActionIds = [
    'daily_activity',
    'heart_rate',
    'hrv',
    'sleep',
    'hemoglobin',
    'water',
    'breakfast',
    'dinner',
    'snacks',
    'drinks',
  ];

  /// One Quick Actions entry. AlloBot's feature type, so it opens the same way
  /// and carries the same illustration.
  AlloBotFeature _quickAction({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget page,
    String? image,
  }) => AlloBotFeature(
    id: id,
    title: title,
    subtitle: subtitle,
    category: FeatureCategory.care,
    icon: icon,
    color: color,
    image: image,
    pageBuilder: (_) => page,
  );

  // ─── TODAY'S CARE ─────────────────────────────────────────
  Widget _buildTodaysCareSection(BuildContext context) {
    return const TodocareSection(compact: true);
  }
}

/// One Quick Actions box: the illustration (or a tinted icon where there is
/// none) over a one-line name, on a soft square card.
class _QuickActionBox extends StatelessWidget {
  const _QuickActionBox({required this.feature, required this.onTap});

  final AlloBotFeature feature;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final image = feature.image;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        boxShadow: [
          BoxShadow(
            color: p.pick(Colors.black.withValues(alpha: 0.03), p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: image != null
                      ? Image.asset(image, fit: BoxFit.contain)
                      : Container(
                          decoration: BoxDecoration(
                            color: p.tint(
                              feature.color,
                              feature.color.withValues(alpha: 0.10),
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            feature.icon,
                            size: 30,
                            color: feature.color,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    feature.title,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
