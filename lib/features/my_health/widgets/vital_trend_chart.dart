import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

import 'package:allomom/models/vitals_stream_model.dart';

/// One reading placed on the time axis.
class VitalSample {
  final DateTime time;
  final double value;

  const VitalSample(this.time, this.value);
}

/// A single plotted line (or bar set) on a [VitalTrendChart].
class VitalSeries {
  final String label;
  final Color color;
  final List<VitalSample> samples;

  const VitalSeries({
    required this.label,
    required this.color,
    required this.samples,
  });

  bool get isEmpty => samples.isEmpty;

  /// Builds a series straight from the vitals stream. [value] pulls the number
  /// out of a row when it does not live in `value` (systolic/diastolic, say);
  /// rows that resolve to nothing are dropped rather than drawn as a zero.
  factory VitalSeries.fromHistory({
    required String label,
    required Color color,
    required List<VitalsStreamResponse> history,
    double? Function(VitalsStreamResponse row)? value,
  }) {
    final samples = <VitalSample>[];
    for (final row in history) {
      final raw = value == null ? row.value : value(row);
      if (raw == null || raw.isNaN || raw.isInfinite || raw <= 0) continue;
      samples.add(VitalSample(row.createdAt, raw));
    }
    samples.sort((a, b) => a.time.compareTo(b.time));
    return VitalSeries(label: label, color: color, samples: samples);
  }
}

/// How several readings inside one bucket become a single point.
enum VitalAggregate {
  /// The bucket's mean — right for a measurement such as heart rate, where two
  /// readings in a day do not make the day's value twice as large.
  average,

  /// The bucket's total — right for a tally such as meal calories, glasses of
  /// water or kicks, where every entry adds to the day.
  sum,
}

/// A shaded healthy-range band drawn behind the series.
class VitalBand {
  final double min;
  final double max;
  final Color color;
  final String? label;

  const VitalBand({
    required this.min,
    required this.max,
    required this.color,
    this.label,
  });
}

/// A trend chart that draws only what was actually recorded.
///
/// Every point comes from the vitals stream, so a period with no readings
/// draws an empty state instead of an invented curve, and a day with a single
/// reading draws a single dot instead of a line across the whole axis.
class VitalTrendChart extends StatefulWidget {
  /// 'Day', 'Week' or 'Month'.
  final String period;
  final List<VitalSeries> series;
  final Color accent;
  final String unit;
  final int decimals;
  final List<VitalBand> bands;

  /// Hints for the value axis — widened when the readings fall outside them.
  final double? minY;
  final double? maxY;

  /// Draws columns instead of a line (steps, sleep hours, kicks).
  final bool bars;

  /// How same-bucket readings combine. Defaults to the mean.
  final VitalAggregate aggregate;
  final String emptyTitle;
  final String emptySubtitle;
  final double height;

  /// Formats the tooltip value when a plain number is not enough (e.g. `7h 20m`).
  final String Function(double value)? valueFormatter;

  const VitalTrendChart({
    super.key,
    required this.period,
    required this.series,
    required this.accent,
    this.unit = '',
    this.decimals = 0,
    this.bands = const [],
    this.minY,
    this.maxY,
    this.bars = false,
    this.aggregate = VitalAggregate.average,
    this.emptyTitle = 'No readings yet',
    this.emptySubtitle = 'Log a reading to start your trend',
    this.height = 196,
    this.valueFormatter,
  });

  @override
  State<VitalTrendChart> createState() => _VitalTrendChartState();
}

class _VitalTrendChartState extends State<VitalTrendChart> {
  /// Which plotted point the tooltip sits on; null means "the latest one".
  int? _selected;

  @override
  void didUpdateWidget(covariant VitalTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final model = _ChartModel.build(
      period: widget.period,
      series: widget.series,
      bars: widget.bars,
      aggregate: widget.aggregate,
    );

    final legend = widget.series.where((s) => s.samples.isNotEmpty).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (legend.length > 1) ...[
          Row(
            children: [
              for (final s in legend) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text(
                  s.label,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ],
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          height: widget.height,
          width: double.infinity,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) => _select(d.localPosition, constraints.maxWidth, model),
                onHorizontalDragUpdate: (d) =>
                    _select(d.localPosition, constraints.maxWidth, model),
                child: CustomPaint(
                  painter: _VitalTrendPainter(
                    model: model,
                    accent: widget.accent,
                    unit: widget.unit,
                    decimals: widget.decimals,
                    bands: widget.bands,
                    minY: widget.minY,
                    maxY: widget.maxY,
                    bars: widget.bars,
                    selected: _selected,
                    emptyTitle: widget.emptyTitle,
                    emptySubtitle: widget.emptySubtitle,
                    valueFormatter: widget.valueFormatter,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _select(Offset local, double width, _ChartModel model) {
    if (model.slots.isEmpty) return;
    final plotLeft = _VitalTrendPainter.leftPad;
    final plotWidth = math.max(1.0, width - plotLeft - _VitalTrendPainter.rightPad);
    final fraction = ((local.dx - plotLeft) / plotWidth).clamp(0.0, 1.0);

    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < model.slots.length; i++) {
      final d = (model.slots[i].x - fraction).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    if (_selected != best) setState(() => _selected = best);
  }
}

// ─── CHART MODEL ─────────────────────────────────────────────
// Turns raw samples into evenly-reasoned slots on a 0..1 time axis, so the
// painter never has to know what a "week" means.

class _Slot {
  final double x;
  final DateTime time;
  final String tooltipLabel;

  /// One entry per series, null where that series has nothing here.
  final List<double?> values;

  const _Slot({
    required this.x,
    required this.time,
    required this.tooltipLabel,
    required this.values,
  });
}

class _ChartModel {
  final List<_Slot> slots;
  final List<Color> colors;
  final List<String> seriesLabels;
  final List<String> xLabels;
  final List<double> xLabelPositions;

  const _ChartModel({
    required this.slots,
    required this.colors,
    required this.seriesLabels,
    required this.xLabels,
    required this.xLabelPositions,
  });

  bool get isEmpty =>
      slots.every((s) => s.values.every((v) => v == null));

  /// Points of one series, in axis order, skipping the slots it has no data for.
  List<MapEntry<int, double>> pointsOf(int seriesIndex) {
    final out = <MapEntry<int, double>>[];
    for (var i = 0; i < slots.length; i++) {
      final v = slots[i].values[seriesIndex];
      if (v != null) out.add(MapEntry(i, v));
    }
    return out;
  }

  static _ChartModel build({
    required String period,
    required List<VitalSeries> series,
    required bool bars,
    VitalAggregate aggregate = VitalAggregate.average,
  }) {
    final now = DateTime.now();
    final p = period.toLowerCase();
    final colors = series.map((s) => s.color).toList();
    final labels = series.map((s) => s.label).toList();

    if (p == 'day' || p == 'today') {
      return _buildDay(now, series, labels, colors, bars, aggregate);
    }
    if (p == 'week') {
      return _buildDaily(now, series, labels, colors,
          days: 7, aggregate: aggregate);
    }
    return _buildDaily(now, series, labels, colors,
        days: 30, aggregate: aggregate);
  }

  /// Today, positioned by clock time. Bars group into 4-hour blocks so a day of
  /// step syncs reads as a column chart rather than a thicket of spikes.
  /// Folds one bucket's readings into its single plotted value, or null when
  /// nothing was recorded there.
  static double? _combine(List<double> values, VitalAggregate aggregate) {
    if (values.isEmpty) return null;
    final total = values.reduce((a, b) => a + b);
    return aggregate == VitalAggregate.sum ? total : total / values.length;
  }

  static _ChartModel _buildDay(
    DateTime now,
    List<VitalSeries> series,
    List<String> labels,
    List<Color> colors,
    bool bars,
    VitalAggregate aggregate,
  ) {
    final startOfDay = DateTime(now.year, now.month, now.day);
    final slots = <_Slot>[];

    if (bars) {
      final buckets = List.generate(6, (_) => List<List<double>>.generate(series.length, (_) => []));
      for (var s = 0; s < series.length; s++) {
        for (final sample in series[s].samples) {
          if (sample.time.isBefore(startOfDay)) continue;
          final idx = (sample.time.hour ~/ 4).clamp(0, 5);
          buckets[idx][s].add(sample.value);
        }
      }
      for (var i = 0; i < 6; i++) {
        final blockStart = startOfDay.add(Duration(hours: i * 4));
        slots.add(_Slot(
          x: i / 5,
          time: blockStart,
          tooltipLabel: DateFormat('h a').format(blockStart),
          values: [
            for (var s = 0; s < series.length; s++)
              _combine(buckets[i][s], aggregate),
          ],
        ));
      }
      return _ChartModel(
        slots: slots,
        colors: colors,
        seriesLabels: labels,
        xLabels: const ['12 AM', '4 AM', '8 AM', '12 PM', '4 PM', '8 PM'],
        xLabelPositions: const [0, 0.2, 0.4, 0.6, 0.8, 1.0],
      );
    }

    // Lines keep each reading where it was taken on the clock.
    final byTime = <DateTime, List<double?>>{};
    for (var s = 0; s < series.length; s++) {
      for (final sample in series[s].samples) {
        if (sample.time.isBefore(startOfDay)) continue;
        final minute = DateTime(
          sample.time.year,
          sample.time.month,
          sample.time.day,
          sample.time.hour,
          sample.time.minute,
        );
        final row = byTime.putIfAbsent(
          minute,
          () => List<double?>.filled(series.length, null),
        );
        row[s] = sample.value;
      }
    }

    final times = byTime.keys.toList()..sort();
    for (final t in times) {
      final minutes = t.difference(startOfDay).inMinutes.clamp(0, 1440);
      slots.add(_Slot(
        x: minutes / 1440,
        time: t,
        tooltipLabel: DateFormat('h:mm a').format(t),
        values: byTime[t]!,
      ));
    }

    return _ChartModel(
      slots: slots,
      colors: colors,
      seriesLabels: labels,
      xLabels: const ['12 AM', '6 AM', '12 PM', '6 PM', '12 AM'],
      xLabelPositions: const [0, 0.25, 0.5, 0.75, 1.0],
    );
  }

  /// One slot per calendar day over the last [days], averaging same-day readings.
  static _ChartModel _buildDaily(
    DateTime now,
    List<VitalSeries> series,
    List<String> labels,
    List<Color> colors, {
    required int days,
    VitalAggregate aggregate = VitalAggregate.average,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final buckets = List.generate(
      days,
      (_) => List<List<double>>.generate(series.length, (_) => []),
    );

    for (var s = 0; s < series.length; s++) {
      for (final sample in series[s].samples) {
        final day = DateTime(sample.time.year, sample.time.month, sample.time.day);
        final ago = today.difference(day).inDays;
        if (ago < 0 || ago > days - 1) continue;
        buckets[days - 1 - ago][s].add(sample.value);
      }
    }

    final slots = <_Slot>[];
    for (var i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: days - 1 - i));
      slots.add(_Slot(
        x: days == 1 ? 0.5 : i / (days - 1),
        time: day,
        tooltipLabel: i == days - 1 ? 'Today' : DateFormat('dd MMM').format(day),
        values: [
          for (var s = 0; s < series.length; s++)
            _combine(buckets[i][s], aggregate),
        ],
      ));
    }

    final xLabels = <String>[];
    final xPositions = <double>[];
    if (days <= 7) {
      for (var i = 0; i < days; i++) {
        final day = today.subtract(Duration(days: days - 1 - i));
        xLabels.add(i == days - 1 ? 'Today' : DateFormat('E').format(day));
        xPositions.add(i / (days - 1));
      }
    } else {
      // Five evenly spaced date marks across the month.
      for (var k = 0; k < 5; k++) {
        final i = (k * (days - 1) / 4).round();
        final day = today.subtract(Duration(days: days - 1 - i));
        xLabels.add(k == 4 ? 'Today' : DateFormat('dd MMM').format(day));
        xPositions.add(i / (days - 1));
      }
    }

    return _ChartModel(
      slots: slots,
      colors: colors,
      seriesLabels: labels,
      xLabels: xLabels,
      xLabelPositions: xPositions,
    );
  }
}

// ─── PAINTER ─────────────────────────────────────────────────

class _VitalTrendPainter extends CustomPainter {
  final _ChartModel model;
  final Color accent;
  final String unit;
  final int decimals;
  final List<VitalBand> bands;
  final double? minY;
  final double? maxY;
  final bool bars;
  final int? selected;
  final String emptyTitle;
  final String emptySubtitle;
  final String Function(double)? valueFormatter;

  static const double leftPad = 34;
  static const double rightPad = 10;
  static const double topPad = 34;
  static const double bottomPad = 24;

  const _VitalTrendPainter({
    required this.model,
    required this.accent,
    required this.unit,
    required this.decimals,
    required this.bands,
    required this.minY,
    required this.maxY,
    required this.bars,
    required this.selected,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.valueFormatter,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      leftPad,
      topPad,
      size.width - rightPad,
      size.height - bottomPad,
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final values = <double>[];
    for (final slot in model.slots) {
      for (final v in slot.values) {
        if (v != null) values.add(v);
      }
    }

    final scale = _Scale.fit(
      values: values,
      minHint: minY,
      maxHint: maxY,
      bands: bands,
      fromZero: bars,
    );

    _paintBands(canvas, plot, scale);
    // With nothing recorded there is no scale to speak of, so the grid stays
    // but its numbers go — they would only be invented.
    _paintGrid(canvas, plot, scale, showLabels: values.isNotEmpty);
    _paintXLabels(canvas, plot);

    if (values.isEmpty) {
      _paintEmpty(canvas, plot);
      return;
    }

    if (bars) {
      _paintBars(canvas, plot, scale);
    } else {
      _paintLines(canvas, plot, scale);
    }

    _paintTooltip(canvas, plot, scale, size);
  }

  // ── Scaffolding ──

  void _paintBands(Canvas canvas, Rect plot, _Scale scale) {
    for (final band in bands) {
      final top = scale.y(plot, math.min(band.max, scale.max));
      final bottom = scale.y(plot, math.max(band.min, scale.min));
      if (bottom <= top) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(plot.left, top, plot.right, bottom),
          const Radius.circular(6),
        ),
        Paint()..color = band.color,
      );
    }
  }

  void _paintGrid(Canvas canvas, Rect plot, _Scale scale, {bool showLabels = true}) {
    final gridPaint = Paint()
      ..color = const Color(0xFFEDEFF3)
      ..strokeWidth = 1;

    for (final tick in scale.ticks) {
      final y = scale.y(plot, tick);
      _dashedLine(canvas, Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      if (!showLabels) continue;

      final label = TextPainter(
        text: TextSpan(
          text: _axisLabel(tick),
          style: const TextStyle(
            fontSize: 9.5,
            color: Color(0xFFB4BAC6),
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: leftPad - 6);
      label.paint(canvas, Offset(plot.left - 8 - label.width, y - label.height / 2));
    }
  }

  void _paintXLabels(Canvas canvas, Rect plot) {
    for (var i = 0; i < model.xLabels.length; i++) {
      final text = model.xLabels[i];
      final isNow = text == 'Today';
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: 9.5,
            color: isNow ? const Color(0xFF6B7280) : const Color(0xFF9AA1AE),
            fontWeight: isNow ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final x = plot.left + plot.width * model.xLabelPositions[i];
      var dx = x - tp.width / 2;
      dx = dx.clamp(0.0, plot.right - tp.width);
      tp.paint(canvas, Offset(dx, plot.bottom + 8));
    }
  }

  void _paintEmpty(Canvas canvas, Rect plot) {
    final title = TextPainter(
      text: TextSpan(
        text: emptyTitle,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: Color(0xFF8E95A5),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: plot.width);

    final sub = TextPainter(
      text: TextSpan(
        text: emptySubtitle,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Color(0xFFB4BAC6),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: plot.width);

    final blockHeight = title.height + 5 + sub.height;
    final top = plot.top + (plot.height - blockHeight) / 2;
    title.paint(canvas, Offset(plot.left + (plot.width - title.width) / 2, top));
    sub.paint(
      canvas,
      Offset(plot.left + (plot.width - sub.width) / 2, top + title.height + 5),
    );
  }

  // ── Series ──

  void _paintLines(Canvas canvas, Rect plot, _Scale scale) {
    for (var s = 0; s < model.colors.length; s++) {
      final points = model.pointsOf(s);
      if (points.isEmpty) continue;

      final color = model.colors[s];
      final offsets = points
          .map((e) => Offset(
                plot.left + plot.width * model.slots[e.key].x,
                scale.y(plot, e.value),
              ))
          .toList();

      if (offsets.length >= 2) {
        final line = _monotonePath(offsets);

        // Soft area under the primary series only — two stacked fills muddy.
        if (s == 0) {
          final area = Path.from(line)
            ..lineTo(offsets.last.dx, plot.bottom)
            ..lineTo(offsets.first.dx, plot.bottom)
            ..close();
          canvas.drawPath(
            area,
            Paint()
              ..shader = ui.Gradient.linear(
                Offset(0, plot.top),
                Offset(0, plot.bottom),
                [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
              ),
          );
        }

        canvas.drawPath(
          line,
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }

      // Dots stay readable only while there are few of them.
      if (offsets.length <= 14) {
        for (final o in offsets) {
          canvas.drawCircle(o, 4.0, Paint()..color = Colors.white);
          canvas.drawCircle(
            o,
            4.0,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.2,
          );
        }
      } else if (offsets.length == 1) {
        canvas.drawCircle(offsets.first, 5.0, Paint()..color = color);
      }
    }
  }

  void _paintBars(Canvas canvas, Rect plot, _Scale scale) {
    final filled = model.slots.where((s) => s.values.first != null).length;
    if (filled == 0) return;

    final step = plot.width / math.max(1, model.slots.length);
    final barWidth = math.min(22.0, math.max(8.0, step * 0.5));
    final color = model.colors.first;
    final zeroY = scale.y(plot, math.max(scale.min, 0));

    for (var i = 0; i < model.slots.length; i++) {
      final v = model.slots[i].values.first;
      if (v == null) continue;
      // Keep the end columns fully inside the plot rather than half-clipped.
      final cx = (plot.left + plot.width * model.slots[i].x)
          .clamp(plot.left + barWidth / 2, plot.right - barWidth / 2);
      final top = scale.y(plot, v);
      final isSelected = i == _selectedIndex();

      final rect = Rect.fromLTRB(
        cx - barWidth / 2,
        math.min(top, zeroY - 2),
        cx + barWidth / 2,
        zeroY,
      );
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          rect,
          topLeft: const Radius.circular(7),
          topRight: const Radius.circular(7),
        ),
        Paint()
          ..shader = ui.Gradient.linear(
            Offset(0, rect.top),
            Offset(0, rect.bottom),
            [
              color.withValues(alpha: isSelected ? 1.0 : 0.85),
              color.withValues(alpha: isSelected ? 0.55 : 0.32),
            ],
          ),
      );
    }
  }

  // ── Tooltip ──

  int _selectedIndex() {
    // Default to the most recent slot that actually holds a reading.
    if (selected != null &&
        selected! >= 0 &&
        selected! < model.slots.length &&
        model.slots[selected!].values.any((v) => v != null)) {
      return selected!;
    }
    for (var i = model.slots.length - 1; i >= 0; i--) {
      if (model.slots[i].values.any((v) => v != null)) return i;
    }
    return -1;
  }

  void _paintTooltip(Canvas canvas, Rect plot, _Scale scale, Size size) {
    final index = _selectedIndex();
    if (index < 0) return;

    final slot = model.slots[index];
    final x = plot.left + plot.width * slot.x;

    final present = <int>[];
    for (var s = 0; s < slot.values.length; s++) {
      if (slot.values[s] != null) present.add(s);
    }
    if (present.isEmpty) return;

    final topValue = present
        .map((s) => slot.values[s]!)
        .reduce((a, b) => a > b ? a : b);
    final anchorY = scale.y(plot, topValue);

    // Guide line + emphasised markers.
    _dashedLine(
      canvas,
      Offset(x, plot.top),
      Offset(x, plot.bottom),
      Paint()
        ..color = accent.withValues(alpha: 0.35)
        ..strokeWidth = 1.2,
    );

    if (!bars) {
      for (final s in present) {
        final o = Offset(x, scale.y(plot, slot.values[s]!));
        canvas.drawCircle(o, 7.5, Paint()..color = model.colors[s].withValues(alpha: 0.16));
        canvas.drawCircle(o, 4.8, Paint()..color = model.colors[s]);
        canvas.drawCircle(o, 2.0, Paint()..color = Colors.white);
      }
    }

    final valueText = present
        .map((s) => _formatValue(slot.values[s]!))
        .join(present.length > 1 ? '/' : '');

    final time = TextPainter(
      text: TextSpan(
        text: slot.tooltipLabel,
        style: const TextStyle(
          fontSize: 8.5,
          color: Color(0xFF8E95A5),
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final value = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: valueText,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF1E2024),
              fontWeight: FontWeight.w800,
            ),
          ),
          if (unit.isNotEmpty)
            TextSpan(
              text: ' $unit',
              style: const TextStyle(
                fontSize: 9,
                color: Color(0xFF8E95A5),
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final w = math.max(time.width, value.width) + 20;
    final h = time.height + value.height + 12;
    var left = x - w / 2;
    left = left.clamp(0.0, size.width - w);
    var top = anchorY - h - 12;
    if (top < 0) top = math.min(anchorY + 12, plot.bottom - h);

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, w, h),
      const Radius.circular(11),
    );
    canvas.drawShadow(
      Path()..addRRect(rect),
      Colors.black.withValues(alpha: 0.12),
      4,
      true,
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    canvas.drawRRect(
      rect,
      Paint()
        ..color = accent.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    time.paint(canvas, Offset(left + (w - time.width) / 2, top + 6));
    value.paint(canvas, Offset(left + (w - value.width) / 2, top + 6 + time.height));
  }

  // ── Helpers ──

  String _formatValue(double v) =>
      valueFormatter != null ? valueFormatter!(v) : v.toStringAsFixed(decimals);

  String _axisLabel(double v) {
    if (v.abs() >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
    final d = v == v.roundToDouble() ? 0 : math.min(decimals, 1);
    return v.toStringAsFixed(d);
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

  /// Monotone cubic (Fritsch–Carlson) — a smooth line that never invents a peak
  /// or dip between two readings the way a plain spline does.
  Path _monotonePath(List<Offset> pts) {
    final n = pts.length;
    final path = Path()..moveTo(pts.first.dx, pts.first.dy);
    if (n < 2) return path;

    final dx = List<double>.generate(n - 1, (i) {
      final d = pts[i + 1].dx - pts[i].dx;
      return d.abs() < 1e-6 ? 1e-6 : d;
    });
    final slope =
        List<double>.generate(n - 1, (i) => (pts[i + 1].dy - pts[i].dy) / dx[i]);

    final m = List<double>.filled(n, 0);
    m[0] = slope.first;
    m[n - 1] = slope.last;
    for (var i = 1; i < n - 1; i++) {
      if (slope[i - 1] * slope[i] <= 0) {
        m[i] = 0;
      } else {
        m[i] = (slope[i - 1] + slope[i]) / 2;
        final limit = 3 * math.min(slope[i - 1].abs(), slope[i].abs());
        if (m[i].abs() > limit) m[i] = limit * (m[i] < 0 ? -1 : 1);
      }
    }

    for (var i = 0; i < n - 1; i++) {
      final h = dx[i];
      path.cubicTo(
        pts[i].dx + h / 3,
        pts[i].dy + m[i] * h / 3,
        pts[i + 1].dx - h / 3,
        pts[i + 1].dy - m[i + 1] * h / 3,
        pts[i + 1].dx,
        pts[i + 1].dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _VitalTrendPainter old) => true;
}

// ─── VALUE AXIS ──────────────────────────────────────────────

class _Scale {
  final double min;
  final double max;
  final List<double> ticks;

  const _Scale(this.min, this.max, this.ticks);

  double y(Rect plot, double value) {
    final span = max - min;
    if (span <= 0) return plot.center.dy;
    final t = ((value - min) / span).clamp(0.0, 1.0);
    return plot.bottom - plot.height * t;
  }

  /// Picks a rounded axis that contains every reading (and any healthy band),
  /// falling back to the caller's hints when there is nothing to plot.
  factory _Scale.fit({
    required List<double> values,
    required double? minHint,
    required double? maxHint,
    required List<VitalBand> bands,
    required bool fromZero,
  }) {
    // Readings set the range and get breathing room above and below; the
    // caller's hints and any healthy band are then folded in as-is, so a
    // clinical axis such as 50–150 mmHg stays exactly that.
    var lo = double.infinity;
    var hi = -double.infinity;
    for (final v in values) {
      lo = math.min(lo, v);
      hi = math.max(hi, v);
    }

    if (lo.isFinite && hi.isFinite) {
      if (hi - lo < 1e-6) {
        final pad = hi.abs() < 1 ? 1.0 : hi.abs() * 0.15;
        lo -= pad;
        hi += pad;
      } else {
        final pad = (hi - lo) * 0.12;
        lo -= pad;
        hi += pad;
      }
    } else {
      lo = double.infinity;
      hi = -double.infinity;
    }

    if (minHint != null) lo = math.min(lo, minHint);
    if (maxHint != null) hi = math.max(hi, maxHint);
    for (final b in bands) {
      lo = math.min(lo, b.min);
      hi = math.max(hi, b.max);
    }

    if (!lo.isFinite || !hi.isFinite) {
      lo = 0;
      hi = 100;
    }
    if (fromZero) lo = math.min(lo, 0);
    // Never dip below zero for a quantity that cannot be negative.
    if (lo < 0 && values.every((v) => v >= 0)) lo = 0;

    final step = _niceStep((hi - lo) / 4.5);
    final niceLo = (lo / step).floorToDouble() * step;
    final niceHi = (hi / step).ceilToDouble() * step;

    final ticks = <double>[];
    for (var t = niceLo; t <= niceHi + step / 2; t += step) {
      ticks.add(double.parse(t.toStringAsFixed(4)));
      if (ticks.length > 8) break;
    }

    return _Scale(niceLo, niceHi, ticks);
  }

  static double _niceStep(double raw) {
    if (raw <= 0) return 1;
    final magnitude = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
    final norm = raw / magnitude;
    double nice;
    if (norm <= 1) {
      nice = 1;
    } else if (norm <= 2) {
      nice = 2;
    } else if (norm <= 2.5) {
      nice = 2.5;
    } else if (norm <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }
}
