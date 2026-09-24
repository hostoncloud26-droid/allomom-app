// Ported from AlloConnect
// lib/features/health_section/vitals/body_composition/body_composition_summary_screen.dart
//
// Data comes from Allomom's local vitals store via HealthVitalsController.
// BMI history is synthesised from weight + height entries (Allomom stores the
// BMI inside each weight entry's `data` rather than as separate `bmi` rows;
// any legacy `bmi` rows are still shown when present).
import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/body_composition/body_composition_entry_sheet.dart';
import 'package:allomom/features/my_health/vitals/body_composition/models/body_composition_models.dart';
import 'package:allomom/features/my_health/vitals/body_composition/views/bmi_gauge_widget.dart';
import 'package:allomom/features/my_health/vitals/body_composition/views/body_composition_chart_card.dart';
import 'package:allomom/features/my_health/vitals/body_composition/views/pregnancy_weight_gain_card.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';

class BodyCompositionSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;
  final double initialHeight;
  final double initialWeight;

  const BodyCompositionSummaryScreen({
    super.key,
    this.userId,
    this.initialHeight = 0,
    this.initialWeight = 0,
  });

  @override
  State<BodyCompositionSummaryScreen> createState() =>
      _BodyCompositionSummaryScreenState();
}

class _BodyCompositionSummaryScreenState
    extends State<BodyCompositionSummaryScreen> {
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;
  String _historyError = '';
  List<VitalsStreamResponse> _heightHistory = [];
  List<VitalsStreamResponse> _weightHistory = [];
  List<VitalsStreamResponse> _bmiHistory = [];

  BodyCompositionDateFilter _bmiFilter = BodyCompositionDateFilter.monthly;
  BodyCompositionDateFilter _weightFilter = BodyCompositionDateFilter.monthly;
  BodyCompositionDateFilter _heightFilter = BodyCompositionDateFilter.monthly;

  String get _userId {
    final explicit = widget.userId?.trim() ?? '';
    if (explicit.isNotEmpty) return explicit;
    return MainController.instance.userId.trim();
  }

  @override
  void initState() {
    super.initState();
    _loadFromLocalDb();
    _syncInBackground();
  }

  Future<void> _loadFromLocalDb() async {
    final targetUserId = _userId;
    if (targetUserId.isEmpty) {
      if (mounted) {
        setState(() {
          _historyError = 'User id is missing';
        });
      }
      return;
    }

    try {
      final results = await Future.wait([
        _vitalsController.getVitalsHistory(targetUserId, 'height'),
        _vitalsController.getVitalsHistory(targetUserId, 'weight'),
        _vitalsController.getVitalsHistory(targetUserId, 'bmi'),
      ]);

      final heightHistory =
          results[0].where((vital) => vital.value > 0).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      final weightHistory =
          results[1].where((vital) => vital.value > 0).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      List<VitalsStreamResponse> bmiHistory =
          results[2].where((vital) => vital.value > 0).toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Synthesize BMI history with exact timestamps if direct BMI entries are missing
      if (bmiHistory.isEmpty && weightHistory.isNotEmpty) {
        final synthList = <VitalsStreamResponse>[];
        for (final w in weightHistory) {
          double heightVal = 0.0;
          final heightsBefore = heightHistory
              .where((h) => !h.createdAt.isAfter(w.createdAt))
              .toList();
          if (heightsBefore.isNotEmpty) {
            heightVal = heightsBefore.last.value;
          } else if (heightHistory.isNotEmpty) {
            heightVal = heightHistory.first.value;
          } else if (widget.initialHeight > 0) {
            heightVal = widget.initialHeight;
          } else {
            final dataHeight = w.data?['height'];
            if (dataHeight is num && dataHeight > 0) {
              heightVal = dataHeight.toDouble();
            }
          }

          if (heightVal > 0 && w.value > 0) {
            final hM = heightVal / 100;
            final bmiVal = w.value / (hM * hM);
            synthList.add(
              VitalsStreamResponse(
                id: 'synth_${w.id}',
                key: 'bmi',
                value: double.parse(bmiVal.toStringAsFixed(1)),
                unit: 'kg/m²',
                createdAt: w.createdAt,
              ),
            );
          }
        }
        bmiHistory = synthList;
      }

      if (!mounted) return;

      setState(() {
        _heightHistory = heightHistory;
        _weightHistory = weightHistory;
        _bmiHistory = bmiHistory;
        _historyError = '';
      });
    } catch (e) {
      debugPrint('Error loading body composition from local db: $e');
    }
  }

  Future<void> _syncInBackground() async {
    if (_userId.isEmpty) return;

    try {
      await _vitalsController.fetchLatestVitals(showLoading: false);
      if (mounted) {
        await _loadFromLocalDb();
      }
    } catch (_) {}
  }

  Future<void> _refreshScreenData() async {
    await _syncInBackground();
  }

  double _resolveHeight() {
    final fromController = _vitalsController.heightVital?.value;
    if (fromController != null && fromController > 0) {
      return fromController;
    }

    if (_heightHistory.isNotEmpty) {
      return _heightHistory.last.value;
    }

    if (widget.initialHeight > 0) return widget.initialHeight;

    // Allomom weight entries carry the height they were logged with.
    final dataHeight = _vitalsController.weightVital?.data?['height'];
    if (dataHeight is num && dataHeight > 0) return dataHeight.toDouble();

    return 0;
  }

  double _resolveWeight() {
    final fromController = _vitalsController.weightVital?.value;
    if (fromController != null && fromController > 0) {
      return fromController;
    }

    if (_weightHistory.isNotEmpty) {
      return _weightHistory.last.value;
    }

    return widget.initialWeight > 0 ? widget.initialWeight : 0;
  }

  double _calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) {
      return 0;
    }
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  Future<void> _openUpdateBottomSheet(BodyCompositionMetric metric) async {
    final didUpdate = await showBodyCompositionEntrySheet(
      context,
      metric: metric,
      currentValue: metric == BodyCompositionMetric.weight
          ? _resolveWeight()
          : _resolveHeight(),
      currentHeightCm: _resolveHeight(),
      userId: _userId,
    );

    if (didUpdate == true && mounted) {
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await _refreshScreenData();
      }
    }
  }

  _BmiCategoryInfo _getBmiCategoryInfo(double bmi) {
    if (bmi <= 0) {
      return _BmiCategoryInfo(
        label: 'No data',
        color: const Color(0xFF90A4AE),
        icon: Icons.info_outline_rounded,
      );
    }
    if (bmi < 18.5) {
      return _BmiCategoryInfo(
        label: 'Underweight',
        color: const Color(0xFF00D2FF),
        icon: Icons.trending_down_rounded,
      );
    }
    if (bmi <= 24.9) {
      return _BmiCategoryInfo(
        label: 'Normal',
        color: const Color(0xFF00C853),
        icon: Icons.check_circle_rounded,
      );
    }
    if (bmi < 30) {
      return _BmiCategoryInfo(
        label: 'Overweight',
        color: const Color(0xFFFFB300),
        icon: Icons.trending_up_rounded,
      );
    }
    return _BmiCategoryInfo(
      label: 'Obese',
      color: const Color(0xFFFF5252),
      icon: Icons.warning_amber_rounded,
    );
  }

  void _showInfoDialog(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF151D2A) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF6539F4).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: Color(0xFF6539F4),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'About BMI & Composition',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Body Mass Index (BMI) is a screening tool that uses height and weight to estimate body fat.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: textColor.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  label: 'Underweight',
                  range: '< 18.5',
                  color: const Color(0xFF00D2FF),
                  textColor: textColor,
                ),
                _buildInfoRow(
                  label: 'Normal / Healthy',
                  range: '18.5 – 24.9',
                  color: const Color(0xFF00C853),
                  textColor: textColor,
                ),
                _buildInfoRow(
                  label: 'Overweight',
                  range: '25.0 – 29.9',
                  color: const Color(0xFFFFB300),
                  textColor: textColor,
                ),
                _buildInfoRow(
                  label: 'Obese',
                  range: '≥ 30.0',
                  color: const Color(0xFFFF5252),
                  textColor: textColor,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Got It',
                style: const TextStyle(
                  color: Color(0xFF6539F4),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String range,
    required Color color,
    required Color textColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          Text(
            range,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  List<VitalsStreamResponse> _filterHistory(
    List<VitalsStreamResponse> list,
    BodyCompositionDateFilter filter,
  ) {
    if (filter == BodyCompositionDateFilter.allTime) {
      return list;
    }
    final now = DateTime.now();
    final start = filter.rangeStart(now);
    if (start == null) {
      return list;
    }
    return list.where((e) {
      return e.createdAt.isAfter(start) || e.createdAt.isAtSameMomentAs(start);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0A111F)
        : const Color(0xFFF7F9FC);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    final height = _resolveHeight();
    final weight = _resolveWeight();
    final bmi = _calculateBmi(height, weight);
    final bmiCategory = _getBmiCategoryInfo(bmi);

    final filteredBmiHistory = _filterHistory(_bmiHistory, _bmiFilter);
    final filteredWeightHistory = _filterHistory(_weightHistory, _weightFilter);
    final filteredHeightHistory = _filterHistory(_heightHistory, _heightFilter);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Body Composition',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Icons.info_outline_rounded,
              color: textColor.withValues(alpha: 0.8),
              size: 22,
            ),
            onPressed: () => _showInfoDialog(context),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshScreenData,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VitalBabyBanner(),
              if (_historyError.isNotEmpty &&
                  _heightHistory.isEmpty &&
                  _weightHistory.isEmpty &&
                  height <= 0 &&
                  weight <= 0)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 80),
                  child: VitalsEmptyState(
                    title: 'Unable to load body composition',
                    subtitle: _historyError,
                    icon: Icons.monitor_weight_rounded,
                    iconColor: const Color(0xFFFF8A65),
                    onAction: _refreshScreenData,
                    actionLabel: 'Retry',
                  ),
                )
              else ...[
                // 1. BMI Overview Purple Gradient Card with Speedometer Gauge
                _buildBmiOverviewCard(bmi: bmi, bmiCategory: bmiCategory),

                const SizedBox(height: 16),

                // 2. Side-by-side Height & Weight Cards
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Height',
                        value: height > 0 ? height.toStringAsFixed(1) : '--',
                        unit: 'cm',
                        icon: Icons.swap_vert_rounded,
                        accentColor: const Color(0xFF2F80ED),
                        bgColor: const Color(0xFFEBF3FF),
                        buttonBgColor: isDarkMode
                            ? const Color(0xFF1E293B)
                            : const Color(0xFFEFF5FF),
                        isDarkMode: isDarkMode,
                        textColor: textColor,
                        onUpdate: () => _openUpdateBottomSheet(
                          BodyCompositionMetric.height,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _buildMetricCard(
                        label: 'Weight',
                        value: weight > 0 ? weight.toStringAsFixed(1) : '--',
                        unit: 'kg',
                        icon: Icons.monitor_weight_outlined,
                        accentColor: const Color(0xFFFF7A45),
                        bgColor: const Color(0xFFFFF2EC),
                        buttonBgColor: isDarkMode
                            ? const Color(0xFF2D1F1C)
                            : const Color(0xFFFFF4EE),
                        isDarkMode: isDarkMode,
                        textColor: textColor,
                        onUpdate: () => _openUpdateBottomSheet(
                          BodyCompositionMetric.weight,
                        ),
                      ),
                    ),
                  ],
                ),

                // Allomom extra: pregnancy weight-gain insight
                if (MainController.instance.isPregnant) ...[
                  const SizedBox(height: 16),
                  PregnancyWeightGainCard(
                    weightHistory: _weightHistory,
                    heightCm: height,
                    gestationalWeek:
                        MainController.instance.currentGestationalWeek,
                    // No onLogWeight: the Weight card's "Update Weight"
                    // button above already opens the same sheet.
                  ),
                ],

                const SizedBox(height: 24),

                // 3. BMI Trend Graph Card
                BodyCompositionChartCard(
                  title: 'BMI Trend',
                  metricLabel: 'BMI',
                  values: filteredBmiHistory.isNotEmpty
                      ? filteredBmiHistory.map((e) => e.value).toList()
                      : (bmi > 0 ? [bmi] : []),
                  dates: filteredBmiHistory.isNotEmpty
                      ? filteredBmiHistory.map((e) => e.createdAt).toList()
                      : [DateTime.now()],
                  unit: 'kg/m²',
                  color: const Color(0xFF6539F4),
                  filter: _bmiFilter,
                  latestValue: bmi,
                  onFilterChanged: (newFilter) {
                    setState(() {
                      _bmiFilter = newFilter;
                    });
                  },
                  height: 180,
                ),

                const SizedBox(height: 20),

                // 4. Weight Trend Graph Card
                BodyCompositionChartCard(
                  title: 'Weight Trend',
                  metricLabel: 'Weight',
                  values: filteredWeightHistory.isNotEmpty
                      ? filteredWeightHistory.map((e) => e.value).toList()
                      : (weight > 0 ? [weight] : []),
                  dates: filteredWeightHistory.isNotEmpty
                      ? filteredWeightHistory.map((e) => e.createdAt).toList()
                      : [DateTime.now()],
                  unit: 'kg',
                  color: const Color(0xFFFF7A45),
                  filter: _weightFilter,
                  latestValue: weight,
                  onFilterChanged: (newFilter) {
                    setState(() {
                      _weightFilter = newFilter;
                    });
                  },
                  height: 180,
                ),

                const SizedBox(height: 20),

                // 5. Height Trend Graph Card
                BodyCompositionChartCard(
                  title: 'Height Trend',
                  metricLabel: 'Height',
                  values: filteredHeightHistory.isNotEmpty
                      ? filteredHeightHistory.map((e) => e.value).toList()
                      : (height > 0 ? [height] : []),
                  dates: filteredHeightHistory.isNotEmpty
                      ? filteredHeightHistory.map((e) => e.createdAt).toList()
                      : [DateTime.now()],
                  unit: 'cm',
                  color: const Color(0xFF2F80ED),
                  filter: _heightFilter,
                  latestValue: height,
                  onFilterChanged: (newFilter) {
                    setState(() {
                      _heightFilter = newFilter;
                    });
                  },
                  height: 180,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBmiOverviewCard({
    required double bmi,
    required _BmiCategoryInfo bmiCategory,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6539F4), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6539F4).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left side: User icon, BMI Overview, Value, Status badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'BMI Overview',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      bmi > 0 ? bmi.toStringAsFixed(1) : '--',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'kg/m²',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: bmiCategory.color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(bmiCategory.icon, color: Colors.white, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        bmiCategory.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right side: Speedometer Arc Gauge
          BmiGaugeWidget(bmi: bmi, size: 145),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required IconData icon,
    required Color accentColor,
    required Color bgColor,
    required Color buttonBgColor,
    required bool isDarkMode,
    required Color textColor,
    required VoidCallback onUpdate,
  }) {
    final cardBg = isDarkMode ? const Color(0xFF151D2A) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDarkMode)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Icon & Label
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? accentColor.withValues(alpha: 0.18)
                      : bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Value & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: textColor.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Update Button
          Material(
            color: buttonBgColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onUpdate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Update $label',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.edit_rounded, color: accentColor, size: 13),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BmiCategoryInfo {
  final String label;
  final Color color;
  final IconData icon;

  const _BmiCategoryInfo({
    required this.label,
    required this.color,
    required this.icon,
  });
}
