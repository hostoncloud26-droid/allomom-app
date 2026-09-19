import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';

/// One column of a [_BarChart].
class _Bar {
  final String label;
  final double value;
  final Color color;

  const _Bar({required this.label, required this.value, required this.color});
}

const _breakfastColor = Color(0xFFFBBF24);
const _lunchColor = Color(0xFF10B981);
const _dinnerColor = Color(0xFF8B5CF6);
const _snacksColor = Color(0xFFF472B6);
const _drinksColor = Color(0xFFF59E0B);
const _waterColor = Color(0xFF06B6D4);

/// Charts what she actually ate and drank.
///
/// Day breaks the calories down by meal so a glance says which meal is missing;
/// Week and Month put one column on each day against the daily goal. Water gets
/// the same treatment underneath, so "did I drink enough" is answered in the
/// same card.
class NutritionTrendCard extends StatefulWidget {
  const NutritionTrendCard({super.key});

  @override
  State<NutritionTrendCard> createState() => _NutritionTrendCardState();
}

class _NutritionTrendCardState extends State<NutritionTrendCard> {
  static const _periods = ['Day', 'Week', 'Month'];

  String _period = 'Day';
  NutritionSummary? _summary;
  bool _loading = true;

  int get _dayCount => switch (_period) {
    'Week' => 7,
    'Month' => 30,
    _ => 1,
  };

  @override
  void initState() {
    super.initState();
    _load();
    HealthVitalsController.instance.addListener(_load);
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final summary = await loadNutritionSummary(dayCount: _dayCount);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  void _selectPeriod(String period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intake Trends',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1B1C1A),
                ),
              ),
              Text(
                _rangeLabel(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPeriodTabs(),
          const SizedBox(height: 16),

          if (_loading && summary == null)
            const SizedBox(
              height: 150,
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
              ),
            )
          else if (summary != null) ...[
            _buildCaloriesBlock(summary),
            const SizedBox(height: 18),
            Container(height: 1, color: const Color(0xFFF1F2F5)),
            const SizedBox(height: 16),
            _buildWaterBlock(summary),
          ],
        ],
      ),
    );
  }

  String _rangeLabel() {
    final now = DateTime.now();
    return switch (_period) {
      'Week' =>
        '${DateFormat('dd MMM').format(now.subtract(const Duration(days: 6)))} - Today',
      'Month' => DateFormat('MMMM yyyy').format(now),
      _ => DateFormat('EEE, dd MMM').format(now),
    };
  }

  Widget _buildPeriodTabs() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: _periods.map((period) {
          final selected = _period == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => _selectPeriod(period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  period,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? const Color(0xFF1B1C1A)
                        : Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── CALORIES ────────────────────────────────────────────────

  Widget _buildCaloriesBlock(NutritionSummary summary) {
    final isDay = _period == 'Day';
    final bars = isDay ? _mealBars(summary.today) : _dailyCalorieBars(summary);

    // A day is measured against the goal; a stretch of days against its own
    // busiest day, so a quiet week still reads.
    final goal = isDay ? null : kDailyCalorieGoal;
    final total = isDay ? summary.today.totalKcal : summary.totalKcal;
    final logged = isDay ? summary.today.totalKcal > 0 : summary.totalKcal > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockHeader(
          title: 'Calories',
          value: logged ? '${total.round()}' : '--',
          unit: 'kcal',
          caption: isDay
              ? 'of ${kDailyCalorieGoal.round()} kcal goal'
              : '$_period total',
          color: const Color(0xFF1B1C1A),
        ),
        const SizedBox(height: 12),
        _BarChart(
          bars: bars,
          goal: goal,
          goalLabel: 'Goal',
          unit: 'kcal',
          height: 150,
          emptyMessage: isDay
              ? 'No meals logged today'
              : 'No meals logged in this period',
          maxLabels: isDay ? bars.length : 5,
        ),
        if (isDay) ...[
          const SizedBox(height: 12),
          _buildMealLegend(summary.today),
        ],
      ],
    );
  }

  List<_Bar> _mealBars(NutritionDay day) => [
    _Bar(label: 'Breakfast', value: day.breakfastKcal, color: _breakfastColor),
    _Bar(label: 'Lunch', value: day.lunchKcal, color: _lunchColor),
    _Bar(label: 'Dinner', value: day.dinnerKcal, color: _dinnerColor),
    _Bar(label: 'Snacks', value: day.snacksKcal, color: _snacksColor),
    _Bar(label: 'Drinks', value: day.drinksKcal, color: _drinksColor),
  ];

  List<_Bar> _dailyCalorieBars(NutritionSummary summary) {
    final last = summary.days.length - 1;
    return [
      for (var i = 0; i < summary.days.length; i++)
        _Bar(
          label: i == last
              ? 'Today'
              : DateFormat(
                  _period == 'Week' ? 'E' : 'd',
                ).format(summary.days[i].date),
          value: summary.days[i].totalKcal,
          color: i == last ? const Color(0xFFFF4E6A) : _lunchColor,
        ),
    ];
  }

  Widget _buildMealLegend(NutritionDay day) {
    final entries = [
      ('Breakfast', day.breakfastKcal, _breakfastColor),
      ('Lunch', day.lunchKcal, _lunchColor),
      ('Dinner', day.dinnerKcal, _dinnerColor),
      ('Snacks', day.snacksKcal, _snacksColor),
      ('Drinks', day.drinksKcal, _drinksColor),
    ];

    return Wrap(
      spacing: 14,
      runSpacing: 8,
      children: entries.map((e) {
        final (label, kcal, color) = e;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              '$label ${kcal > 0 ? '${kcal.round()} kcal' : '--'}',
              style: GoogleFonts.inter(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: kcal > 0 ? Colors.black54 : Colors.black26,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  // ─── WATER ───────────────────────────────────────────────────

  Widget _buildWaterBlock(NutritionSummary summary) {
    final goal = waterGoalGlasses();

    if (_period == 'Day') {
      final glasses = summary.today.waterGlasses;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _blockHeader(
            title: 'Water',
            value: '$glasses',
            unit: glasses == 1 ? 'glass' : 'glasses',
            caption: '${glasses * kGlassMl} ml of ${goal * kGlassMl} ml',
            color: _waterColor,
          ),
          const SizedBox(height: 12),
          _GlassRow(filled: glasses, goal: goal),
        ],
      );
    }

    final last = summary.days.length - 1;
    final bars = [
      for (var i = 0; i < summary.days.length; i++)
        _Bar(
          label: i == last
              ? 'Today'
              : DateFormat(
                  _period == 'Week' ? 'E' : 'd',
                ).format(summary.days[i].date),
          value: summary.days[i].waterGlasses.toDouble(),
          color: i == last ? const Color(0xFF0284C7) : _waterColor,
        ),
    ];

    final average = summary.days.isEmpty
        ? 0.0
        : summary.totalWaterGlasses / summary.days.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _blockHeader(
          title: 'Water',
          value: summary.totalWaterGlasses > 0
              ? average.toStringAsFixed(1)
              : '--',
          unit: 'glasses/day',
          caption: 'Goal $goal/day',
          color: _waterColor,
        ),
        const SizedBox(height: 12),
        _BarChart(
          bars: bars,
          goal: goal.toDouble(),
          goalLabel: 'Goal',
          unit: 'glasses',
          height: 120,
          emptyMessage: 'No water logged in this period',
          maxLabels: 5,
        ),
      ],
    );
  }

  Widget _blockHeader({
    required String title,
    required String value,
    required String unit,
    required String caption,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: value == '--' ? Colors.black26 : color,
            height: 1.0,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 1),
          child: Text(
            unit,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Colors.black38,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            caption,
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(fontSize: 10, color: Colors.black38),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─── GLASS ROW (today's hydration) ─────────────────────────────

/// Today's water as one mark per glass — easier to read at a glance than a
/// single bar, and it shows how many are still to go.
class _GlassRow extends StatelessWidget {
  const _GlassRow({required this.filled, required this.goal});

  final int filled;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final slots = math.max(goal, filled);

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final width = (constraints.maxWidth - gap * (slots - 1)) / slots;

        return Row(
          children: [
            for (var i = 0; i < slots; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Container(
                width: width,
                height: 34,
                decoration: BoxDecoration(
                  color: i < filled
                      ? _waterColor.withValues(alpha: i >= goal ? 0.45 : 1.0)
                      : _waterColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: i < filled
                    ? const Icon(
                        Icons.water_drop_rounded,
                        size: 13,
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ],
        );
      },
    );
  }
}

// ─── BAR CHART ─────────────────────────────────────────────────

/// A plain column chart over named categories.
///
/// Columns come straight from the readings — a category with nothing logged
/// draws no column at all rather than a placeholder stub.
class _BarChart extends StatelessWidget {
  const _BarChart({
    required this.bars,
    required this.unit,
    required this.height,
    required this.emptyMessage,
    required this.maxLabels,
    this.goal,
    this.goalLabel,
  });

  final List<_Bar> bars;
  final double? goal;
  final String? goalLabel;
  final String unit;
  final double height;
  final String emptyMessage;

  /// How many x labels to draw; the rest are thinned out so they stay legible.
  final int maxLabels;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _BarChartPainter(
          bars: bars,
          goal: goal,
          goalLabel: goalLabel,
          unit: unit,
          emptyMessage: emptyMessage,
          maxLabels: maxLabels,
        ),
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<_Bar> bars;
  final double? goal;
  final String? goalLabel;
  final String unit;
  final String emptyMessage;
  final int maxLabels;

  const _BarChartPainter({
    required this.bars,
    required this.goal,
    required this.goalLabel,
    required this.unit,
    required this.emptyMessage,
    required this.maxLabels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 20.0;
    const bottomPad = 20.0;
    final plot = Rect.fromLTRB(0, topPad, size.width, size.height - bottomPad);
    if (plot.width <= 0 || plot.height <= 0) return;

    final baseline = plot.bottom;
    final hasData = bars.any((b) => b.value > 0);

    // Baseline, always drawn so the chart keeps its shape when empty.
    canvas.drawLine(
      Offset(plot.left, baseline),
      Offset(plot.right, baseline),
      Paint()
        ..color = const Color(0xFFEDEFF3)
        ..strokeWidth = 1.2,
    );

    if (!hasData) {
      _paintEmpty(canvas, plot);
      _paintLabels(canvas, plot, baseline);
      return;
    }

    final peak = bars.map((b) => b.value).reduce(math.max);
    // Keep the goal on the scale so the columns can be read against it, unless
    // it towers so far over them that the bars would shrink to nothing.
    final top = goal != null && goal! <= peak * 2.5
        ? math.max(peak, goal!)
        : peak;
    final scale = top <= 0 ? 0.0 : plot.height / (top * 1.12);

    // Goal line.
    final g = goal;
    if (g != null && g > 0 && g * scale <= plot.height) {
      final y = baseline - g * scale;
      _dashedLine(
        canvas,
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()
          ..color = const Color(0xFF94A3B8).withValues(alpha: 0.7)
          ..strokeWidth = 1,
      );
      final tag = TextPainter(
        text: TextSpan(
          text: goalLabel ?? 'Goal',
          style: const TextStyle(
            fontSize: 8.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF94A3B8),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tag.paint(canvas, Offset(plot.right - tag.width, y - tag.height - 2));
    }

    // Columns.
    final step = plot.width / bars.length;
    final barWidth = math.min(26.0, math.max(6.0, step * 0.52));

    for (var i = 0; i < bars.length; i++) {
      final bar = bars[i];
      if (bar.value <= 0) continue;

      final cx = plot.left + step * (i + 0.5);
      final barTop = math.max(plot.top, baseline - bar.value * scale);
      final rect = Rect.fromLTRB(
        cx - barWidth / 2,
        math.min(barTop, baseline - 3),
        cx + barWidth / 2,
        baseline,
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(8),
          topRight: const Radius.circular(8),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, rect.top),
            Offset(0, rect.bottom),
            [bar.color, bar.color.withValues(alpha: 0.35)],
          ),
      );

      // Value above the column, while there is room for it to be read.
      if (bars.length <= 8) {
        final text = TextPainter(
          text: TextSpan(
            text: _format(bar.value),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: bar.color,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        text.paint(
          canvas,
          Offset(cx - text.width / 2, rect.top - text.height - 3),
        );
      }
    }

    _paintLabels(canvas, plot, baseline);
  }

  void _paintLabels(Canvas canvas, Rect plot, double baseline) {
    final step = plot.width / bars.length;
    // Thin the labels out evenly so a month does not collapse into a smear.
    final every = bars.length <= maxLabels
        ? 1
        : (bars.length / maxLabels).ceil();

    for (var i = 0; i < bars.length; i++) {
      final isLast = i == bars.length - 1;
      if (!isLast && i % every != 0) continue;
      // Skip a label that would collide with the pinned last one.
      if (!isLast && bars.length - 1 - i < every * 0.6) continue;

      final label = bars[i].label;
      // Only today earns the emphasis; a meal name at the end of the row is
      // just the last category.
      final isToday = label == 'Today';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? const Color(0xFF6B7280) : const Color(0xFF9AA1AE),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final cx = plot.left + step * (i + 0.5);
      final dx = (cx - text.width / 2).clamp(0.0, plot.right - text.width);
      text.paint(canvas, Offset(dx, baseline + 6));
    }
  }

  void _paintEmpty(Canvas canvas, Rect plot) {
    final text = TextPainter(
      text: TextSpan(
        text: emptyMessage,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFFB4BAC6),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: plot.width);
    text.paint(
      canvas,
      Offset(
        plot.left + (plot.width - text.width) / 2,
        plot.top + (plot.height - text.height) / 2,
      ),
    );
  }

  String _format(double v) {
    if (unit == 'glasses') return v.round().toString();
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    return v.round().toString();
  }

  void _dashedLine(Canvas canvas, Offset from, Offset to, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    final total = (to - from).distance;
    if (total <= 0) return;
    final dir = (to - from) / total;
    var covered = 0.0;
    while (covered < total) {
      final end = math.min(covered + dash, total);
      canvas.drawLine(from + dir * covered, from + dir * end, paint);
      covered = end + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => true;
}
