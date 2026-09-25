import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/day_date_selector.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/my_health/health_profile_page.dart';
import 'package:allomom/features/my_health/widgets/my_health_profile_card.dart';
import 'package:allomom/features/my_health/widgets/advanced_health_summary_card.dart';
import 'package:allomom/features/my_health/widgets/step_target_tile.dart';
import 'package:allomom/features/my_health/widgets/fitness_summary_card.dart';
import 'package:allomom/features/my_health/widgets/calories_tracker_tile.dart';
import 'package:allomom/features/my_health/widgets/nutrition_tiles.dart';
import 'package:allomom/features/my_health/widgets/fitness_tiles.dart';
import 'package:allomom/features/my_health/tiles/step_tile.dart';
import 'package:allomom/features/my_health/tiles/sleep_tile.dart';
import 'package:allomom/features/my_health/tiles/heart_rate_tile.dart';
import 'package:allomom/features/my_health/tiles/blood_oxygen_tile.dart';
import 'package:allomom/features/my_health/tiles/blood_pressure_tile.dart';
import 'package:allomom/features/my_health/tiles/stress_tile.dart';
import 'package:allomom/features/my_health/tiles/bmi_tile.dart';
import 'package:allomom/features/my_health/tiles/hrv_tile.dart';
import 'package:allomom/features/my_health/tiles/hemoglobin_tile.dart';
import 'package:allomom/features/my_health/tiles/blood_glucose_tile.dart';
import 'package:allomom/features/my_health/tiles/kick_count_tile.dart';
import 'package:allomom/features/my_health/tiles/feeding_tile.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_trend_card.dart';
import 'package:allomom/features/home/widgets/cycle_summary_card.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';

class _HealthTabItem {
  final IconData icon;
  final String label;

  const _HealthTabItem({required this.icon, required this.label});
}

class MyHealthPage extends StatefulWidget {
  final int initialTab;
  const MyHealthPage({super.key, this.initialTab = 0});

  @override
  State<MyHealthPage> createState() => _MyHealthPageState();
}

class _MyHealthPageState extends State<MyHealthPage> {
  late int _currentIndex;
  late final PageController _pageController;
  bool _isSyncingAllowear = false;

  // Accent colours stay fixed; surfaces and neutral text follow light / dark.
  AppPalette get _p => context.palette;
  Color get _titleColor => _p.pick(const Color(0xFF2D3142), _p.textPrimary);
  Color get _textSoft => _p.pick(const Color(0xFF8E95A5), _p.textMuted);

  final List<_HealthTabItem> _tabs = const [
    _HealthTabItem(icon: Icons.health_and_safety_rounded, label: 'Health'),
    _HealthTabItem(icon: Icons.description_rounded, label: 'Reports'),
    _HealthTabItem(icon: Icons.medication_rounded, label: 'Prescription'),
    _HealthTabItem(icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _pageController = PageController(initialPage: _currentIndex);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _syncAllowearDevice() async {
    setState(() => _isSyncingAllowear = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Syncing with Allowear device & cloud...'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await HealthVitalsController.instance.syncAllVitals();

    if (mounted) {
      setState(() => _isSyncingAllowear = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vitals synced and stored successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: _p.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _titleColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _currentIndex == 0
              ? 'My Health'
              : _currentIndex == 1
              ? 'My Reports'
              : _currentIndex == 2
              ? 'My Prescriptions'
              : 'My Profile',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _titleColor,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        heroTag: 'my_health_allowear_fab',
        onPressed: _isSyncingAllowear ? null : _syncAllowearDevice,
        backgroundColor: const Color(0xFFFF3B5C),
        elevation: 6,
        shape: const CircleBorder(),
        // AlloConnect's band icon: it turns while a sync runs, and is dimmed
        // until a band has been paired.
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _RotatingAllowearIcon(
            spinning: _isSyncingAllowear,
            paired:
                (MainController.instance.allowearMacAddress ?? '').isNotEmpty,
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: _p.card,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        elevation: 12,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTabButton(0, _tabs[0]),
              _buildTabButton(1, _tabs[1]),
              const SizedBox(width: 48), // Notch space for FAB
              _buildTabButton(2, _tabs[2]),
              _buildTabButton(3, _tabs[3]),
            ],
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        onPageChanged: (idx) {
          if (_currentIndex != idx) {
            setState(() => _currentIndex = idx);
          }
        },
        children: [
          // Tab 0: Health Section — owns its own scroll view, pull-to-refresh
          // and collapsing profile header.
          MyHealthSection(onOpenProfile: () => _goToTab(3)),

          // Tab 1: Reports
          const ReportsPage(showAppBar: false),

          // Tab 2: Prescriptions
          const PrescriptionsPage(showAppBar: false),

          // Tab 3: Profile
          const HealthProfilePage(),
        ],
      ),
    );
  }

  void _goToTab(int index) {
    if (_currentIndex != index) {
      setState(() => _currentIndex = index);
      _pageController.jumpToPage(index);
    }
  }

  Widget _buildTabButton(int index, _HealthTabItem tab) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFFFF3B5C);
    final inactiveColor = _textSoft;

    return InkWell(
      onTap: () => _goToTab(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tab.icon,
              size: 22,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              tab.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The Health tab: a collapsing profile header, the day's summary cards, one
/// tile per vital and the nutrition / fitness blocks — laid out as
/// AlloConnect's HealthSection. Everything from the calories tile down reports
/// on [_selectedDate], picked from a date strip that rides over the scroll view
/// once that stretch reaches the app bar.
class MyHealthSection extends StatefulWidget {
  /// Tapping the profile header; the page switches to its Profile tab.
  final VoidCallback? onOpenProfile;

  const MyHealthSection({super.key, this.onOpenProfile});

  @override
  State<MyHealthSection> createState() => _MyHealthSectionState();
}

class _MyHealthSectionState extends State<MyHealthSection> {
  static const _tilePadding = EdgeInsets.only(
    left: 16.0,
    right: 16.0,
    top: 12.0,
    bottom: 4.0,
  );

  final HealthVitalsController _vitals = HealthVitalsController.instance;
  late final ScrollController _scrollController;
  bool _showTitle = false;

  /// Day the section below the summary card reports on.
  DateTime _selectedDate = DateUtils.dateOnly(DateTime.now());

  /// Latest vital per key as it stood on [_selectedDate]. Only consulted for
  /// past days — today keeps reading the controller so live syncs still land.
  Map<String, VitalsStreamResponse?> _dayVitals =
      <String, VitalsStreamResponse?>{};

  /// The date strip is an overlay, never part of the scrolled content: it
  /// shows only once the date-scoped stretch has reached the app bar.
  bool _showDateSelector = false;

  /// Sits on the first date-scoped card, so the overlay triggers off real
  /// layout rather than a guessed scroll offset.
  final GlobalKey _dateScopeAnchorKey = GlobalKey();

  /// The section's own box: the page's app bar sits above it, so the anchor is
  /// measured against this rather than the screen.
  final GlobalKey _sectionKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    // Keep a past day's snapshot in step with fresh syncs and manual entries.
    _vitals.addListener(_onVitalsChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _vitals.fetchLatestVitals();
    });
    _loadDayVitals();
  }

  @override
  void dispose() {
    _vitals.removeListener(_onVitalsChanged);
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  bool get _isToday => DateUtils.isSameDay(_selectedDate, DateTime.now());

  void _onVitalsChanged() {
    if (!_isToday) _loadDayVitals();
  }

  Future<void> _loadDayVitals() async {
    final date = _selectedDate;
    final snapshot = await _vitals.fetchVitalsForDate(date);
    if (!mounted || !DateUtils.isSameDay(date, _selectedDate)) return;
    setState(() => _dayVitals = snapshot);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _updateDateSelectorVisibility();
    });
  }

  void _onDateSelected(DateTime date) {
    final normalized = DateUtils.dateOnly(date);
    if (DateUtils.isSameDay(normalized, _selectedDate)) return;
    setState(() {
      _selectedDate = normalized;
      _dayVitals = <String, VitalsStreamResponse?>{};
    });
    _loadDayVitals();
  }

  /// Today reads straight from the controller; any other day comes from the
  /// day snapshot.
  VitalsStreamResponse? _vitalFor(String key, VitalsStreamResponse? today) {
    return _isToday ? today : _dayVitals[key];
  }

  int get _stepsForSelectedDate {
    if (_isToday) return _vitals.stepsValue;
    return _dayVitals['steps']?.value.round() ?? 0;
  }

  /// There is no typed getter for glucose, so today's reading is the newest
  /// row under either key.
  VitalsStreamResponse? get _todayGlucoseVital {
    VitalsStreamResponse? latest;
    for (final v in _vitals.vitals) {
      final key = v.key.toLowerCase();
      if (key != 'glucose' && key != 'blood_glucose') continue;
      if (latest == null || v.createdAt.isAfter(latest.createdAt)) latest = v;
    }
    return latest;
  }

  void _onScroll() {
    final showTitle = _scrollController.offset > 160;
    if (showTitle != _showTitle) {
      setState(() => _showTitle = showTitle);
    }
    _updateDateSelectorVisibility();
  }

  void _updateDateSelectorVisibility() {
    final anchorBox =
        _dateScopeAnchorKey.currentContext?.findRenderObject() as RenderBox?;
    final sectionBox =
        _sectionKey.currentContext?.findRenderObject() as RenderBox?;
    if (anchorBox == null || !anchorBox.hasSize || sectionBox == null) return;

    final anchorTop = anchorBox
        .localToGlobal(Offset.zero, ancestor: sectionBox)
        .dy;
    final show = anchorTop <= _appBarBottom;

    if (show != _showDateSelector) {
      setState(() => _showDateSelector = show);
    }
  }

  /// Bottom of the collapsed sliver app bar, in the section's coordinates.
  double get _appBarBottom => MediaQuery.of(context).padding.top + kToolbarHeight;

  Future<void> _refresh() async {
    await _vitals.syncAllVitals();
    await _loadDayVitals();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isDark = p.isDark;
    final titleColor = isDark ? Colors.white : Colors.black87;

    return Stack(
      key: _sectionKey,
      children: [
        // Speaks the tab's intro — or, with nothing recorded yet, the line
        // that asks for a first reading — while the tab is on screen.
        GetBuilder<HealthVitalsController>(
          init: _vitals,
          builder: (c) => BabyNarration(
            narrationKey: c.hasAnyVital
                ? NarrationKeys.pgVitalsOpen
                : NarrationKeys.pgVitalsEmpty,
            bindText: false,
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ),
        RefreshIndicator(
          color: Theme.of(context).primaryColor,
          onRefresh: _refresh,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── App bar ──────────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 230,
                floating: false,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: _showTitle
                    ? (isDark ? Colors.black : Colors.white)
                    : p.scaffoldSoft,
                surfaceTintColor: Colors.transparent,
                elevation: _showTitle ? 2 : 0,
                title: AnimatedOpacity(
                  opacity: _showTitle ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AnimatedBuilder(
                    animation: MainController.instance,
                    builder: (context, _) => Text(
                      MainController.instance.userName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                  ),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
                  collapseMode: CollapseMode.parallax,
                  background: MyHealthProfileCard(onTap: widget.onOpenProfile),
                ),
              ),

              // ── Health Summary Card ──────────────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: AdvancedHealthSummaryCard(),
                ),
              ),

              // ── Cycle tracker (not pregnant) ─────────────────────────────
              SliverToBoxAdapter(child: _buildCycleCard()),

              // ── Calories Tracker ─────────────────────────────────────────
              // Everything from here down reports on the selected day; the
              // date strip that drives it rides above as an overlay.
              SliverToBoxAdapter(
                child: Padding(
                  key: _dateScopeAnchorKey,
                  padding: _tilePadding,
                  child: CaloriesTrackerTile(
                    date: _selectedDate,
                    stepsForDate: _stepsForSelectedDate,
                  ),
                ),
              ),

              // ── Step Target Tile ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: GetBuilder<HealthVitalsController>(
                  init: _vitals,
                  builder: (c) {
                    // A step target is a standing setting, not day data, so
                    // it is only offered while today is selected.
                    if (!_isToday ||
                        c.targetVital?.data?['stepTarget'] != null) {
                      return const SizedBox.shrink();
                    }
                    return const Padding(
                      padding: _tilePadding,
                      child: StepTargetTile(),
                    );
                  },
                ),
              ),

              // ── Fitness Summary Card ─────────────────────────────────────
              SliverToBoxAdapter(
                child: GetBuilder<HealthVitalsController>(
                  init: _vitals,
                  builder: (_) => Padding(
                    padding: _tilePadding,
                    child: FitnessSummaryCard(
                      date: _selectedDate,
                      stepsForDate: _stepsForSelectedDate,
                    ),
                  ),
                ),
              ),

              // ── Vital tiles ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: GetBuilder<HealthVitalsController>(
                  init: _vitals,
                  builder: _buildVitalTiles,
                ),
              ),

              // ── Nutrition (NutritionTiles draws its own heading) ─────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: NutritionTiles(date: _selectedDate),
                ),
              ),

              // ── Intake trends (Allomom extra) ────────────────────────────
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: NutritionTrendCard(),
                ),
              ),

              // ── Fitness (FitnessTiles draws its own heading) ─────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: FitnessTiles(date: _selectedDate),
                ),
              ),

              // Clears the docked FAB and bottom bar.
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),

        // ── Sticky date selector (overlay only) ──────────────────────────
        StickyDateSelectorOverlay(
          visible: _showDateSelector,
          top: _appBarBottom,
          selectedDate: _selectedDate,
          onDateSelected: _onDateSelected,
        ),
      ],
    );
  }

  /// Where AlloConnect shows its menstruation tracker: Allomom's cycle card,
  /// for a woman who is not pregnant. The card pads itself horizontally.
  Widget _buildCycleCard() {
    return AnimatedBuilder(
      animation: MainController.instance,
      builder: (context, _) {
        final session = MainController.instance;
        if (session.isPregnant || session.gender.toLowerCase() != 'female') {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 12.0, bottom: 4.0),
          child: CycleSummaryCard(
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
          ),
        );
      },
    );
  }

  Widget _buildVitalTiles(HealthVitalsController c) {
    final date = _selectedDate;
    final today = _isToday;
    void onLogged() => _loadDayVitals();

    final sleepVital = today
        ? c.sleepVital
        : (_dayVitals['sleep'] ?? _dayVitals['sleep_data']);
    final glucoseVital = today
        ? _todayGlucoseVital
        : (_dayVitals['glucose'] ?? _dayVitals['blood_glucose']);

    final tiles = <Widget>[
      StepTile(
        vital: _vitalFor('steps', c.stepsVital),
        steps: today ? c.stepsValue : null,
        targetSteps: c.currentStepTarget,
        date: date,
        onLogged: onLogged,
      ),
      SleepTile(
        vital: sleepVital,
        sleepHours: today && c.hasSleep ? c.sleepHoursValue : null,
        date: date,
        onLogged: onLogged,
      ),
      HeartRateTile(
        vital: _vitalFor('heart_rate', c.heartRateVital),
        date: date,
        onLogged: onLogged,
      ),
      BloodOxygenTile(
        vital: _vitalFor('blood_oxygen', c.bloodOxygenVital),
        date: date,
        onLogged: onLogged,
      ),
      BloodPressureTile(
        vital: _vitalFor('blood_pressure', c.bloodPressureVital),
        date: date,
        onLogged: onLogged,
      ),
      StressTile(
        vital: _vitalFor('stress', c.stressVital),
        date: date,
        onLogged: onLogged,
      ),
      BMITile(
        weightVital: _vitalFor('weight', c.weightVital),
        heightVital: _vitalFor('height', c.heightVital),
        date: date,
        onLogged: onLogged,
      ),
      HrvTile(
        vital: _vitalFor('hrv', c.hrvVital),
        date: date,
        onLogged: onLogged,
      ),
      HemoglobinTile(
        vital: _vitalFor('hemoglobin', c.hemoglobinVital),
        date: date,
        onLogged: onLogged,
      ),
      BloodGlucoseTile(vital: glucoseVital, date: date, onLogged: onLogged),
      // Kicks only mean something during a pregnancy (the tile would render
      // nothing anyway); leaving it out also drops its padding.
      if (MainController.instance.isPregnant)
        KickCountTile(
          vital: _vitalFor('kick_count', c.kickCountVital),
          date: date,
          isPregnant: true,
          onLogged: onLogged,
        ),
      FeedingTile(
        vital: _vitalFor('feeding', c.feedingVital),
        date: date,
        onLogged: onLogged,
      ),
    ];

    return Column(
      children: [
        for (final tile in tiles) Padding(padding: _tilePadding, child: tile),
      ],
    );
  }
}

/// The Allowear band, as AlloConnect's My Health button shows it.
class _RotatingAllowearIcon extends StatefulWidget {
  const _RotatingAllowearIcon({required this.spinning, required this.paired});

  final bool spinning;
  final bool paired;

  @override
  State<_RotatingAllowearIcon> createState() => _RotatingAllowearIconState();
}

class _RotatingAllowearIconState extends State<_RotatingAllowearIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _RotatingAllowearIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.spinning == oldWidget.spinning) return;
    if (widget.spinning) {
      _controller.repeat();
    } else {
      _controller
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Image.asset(
        'assets/allowear/bracelet_white.png',
        color: widget.paired || widget.spinning
            ? Colors.white
            : Colors.white.withValues(alpha: 0.6),
      ),
    );
  }
}
