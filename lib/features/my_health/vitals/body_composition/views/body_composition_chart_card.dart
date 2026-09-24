import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/features/my_health/vitals/body_composition/models/body_composition_models.dart';
import 'package:allomom/features/my_health/vitals/common/vitals_empty_state.dart';

class BodyCompositionChartCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? metricLabel;
  final List<double> values;
  final List<DateTime> dates;
  final String unit;
  final Color color;
  final BodyCompositionDateFilter filter;
  final ValueChanged<BodyCompositionDateFilter>? onFilterChanged;
  final double? latestValue;
  final double height;

  const BodyCompositionChartCard({
    super.key,
    required this.title,
    this.subtitle,
    this.metricLabel,
    required this.values,
    required this.dates,
    required this.unit,
    required this.color,
    required this.filter,
    this.onFilterChanged,
    this.latestValue,
    this.height = 180,
  });

  String _filterLabel(BodyCompositionDateFilter f) {
    switch (f) {
      case BodyCompositionDateFilter.daily:
        return 'Today';
      case BodyCompositionDateFilter.weekly:
        return 'This Week';
      case BodyCompositionDateFilter.monthly:
        return 'This Month';
      case BodyCompositionDateFilter.allTime:
        return 'All Time';
    }
  }

  String _formatAxisDate(
    DateTime date,
    List<DateTime> allDates,
    BodyCompositionDateFilter f,
  ) {
    if (allDates.length > 1) {
      final first = allDates.first;
      final allSameDay = allDates.every(
        (d) =>
            d.year == first.year &&
            d.month == first.month &&
            d.day == first.day,
      );
      if (allSameDay) {
        return DateFormat('hh:mm a').format(date);
      }
    }

    switch (f) {
      case BodyCompositionDateFilter.daily:
        return DateFormat('hh:mm a').format(date);
      case BodyCompositionDateFilter.weekly:
        return DateFormat('E, dd').format(date);
      case BodyCompositionDateFilter.monthly:
        return DateFormat('dd MMM').format(date);
      case BodyCompositionDateFilter.allTime:
        final currentYear = DateTime.now().year;
        return date.year != currentYear
            ? DateFormat('dd MMM yy').format(date)
            : DateFormat('dd MMM').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final cardBg = isDarkMode ? const Color(0xFF151D2A) : Colors.white;
    final borderColor = isDarkMode
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    final validPoints = <int, double>{};
    for (int i = 0; i < values.length; i++) {
      if (values[i] > 0) {
        validPoints[i] = values[i];
      }
    }

    final double displayValue = latestValue != null && latestValue! > 0
        ? latestValue!
        : (validPoints.isNotEmpty ? validPoints.values.last : 0);

    final resolvedMetricLabel =
        metricLabel ?? title.replaceAll(' Trend', '').replaceAll(' Graph', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header: Title & Dropdown Filter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ],
            ),
            if (onFilterChanged != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF0F3F8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<BodyCompositionDateFilter>(
                    value: filter,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: textColor.withValues(alpha: 0.7),
                    ),
                    dropdownColor: isDarkMode
                        ? const Color(0xFF1B2433)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: textColor.withValues(alpha: 0.8),
                    ),
                    onChanged: (newFilter) {
                      if (newFilter != null) {
                        onFilterChanged!(newFilter);
                      }
                    },
                    items: BodyCompositionDateFilter.values.map((f) {
                      return DropdownMenuItem<BodyCompositionDateFilter>(
                        value: f,
                        child: Text(_filterLabel(f)),
                      );
                    }).toList(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Chart Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
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
              // Inside Card Header: Metric description & Current Value Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        resolvedMetricLabel,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '($unit)',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: textColor.withValues(alpha: 0.4),
                        ),
                      ),
                    ],
                  ),
                  if (displayValue > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        displayValue.toStringAsFixed(unit == 'cm' ? 1 : 1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (validPoints.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: VitalsEmptyState(
                    title: 'No $title data',
                    subtitle: 'Add more measurements to unlock your trends.',
                    icon: title.toLowerCase().contains('height')
                        ? Icons.height_rounded
                        : Icons.monitor_weight_rounded,
                    iconColor: color,
                  ),
                )
              else
                _buildChart(validPoints, isDarkMode, textColor, cardBg),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChart(
    Map<int, double> validPoints,
    bool isDarkMode,
    Color textColor,
    Color cardBg,
  ) {
    final points = validPoints.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList();

    final minVal = validPoints.values.reduce((a, b) => a < b ? a : b);
    final maxVal = validPoints.values.reduce((a, b) => a > b ? a : b);

    final double padding = ((maxVal - minVal) * 0.25).clamp(1.0, 10.0);
    final double minY = (minVal - padding).clamp(0, double.infinity);
    final double maxY = maxVal + padding;
    final double interval = ((maxY - minY) / 3).clamp(1.0, double.infinity);

    final double rawInterval = dates.length > 5
        ? (dates.length / 4).floorToDouble()
        : 1.0;
    final double bottomInterval = rawInterval < 1.0 ? 1.0 : rawInterval;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: interval,
                getTitlesWidget: (value, meta) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(
                      value.toInt().toString(),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: dates.isNotEmpty,
                reservedSize: 26,
                interval: bottomInterval,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= dates.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _formatAxisDate(dates[index], dates, filter),
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (touchedSpot) => isDarkMode
                  ? const Color(0xFF1E2433)
                  : const Color(0xFF151D2A),
              tooltipBorderRadius: BorderRadius.circular(12),
              maxContentWidth: 200,
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 8,
              ),
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (spots) {
                return spots.map((spot) {
                  final index = spot.x.toInt();
                  final date = index >= 0 && index < dates.length
                      ? dates[index]
                      : null;
                  final dateStr = date != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(date)
                      : '';
                  return LineTooltipItem(
                    '${spot.y.toStringAsFixed(unit == 'cm' ? 0 : 1)} $unit\n',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: dateStr,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: points.length > 1,
              curveSmoothness: 0.35,
              color: color,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (_, __, ___, ____) => FlDotCirclePainter(
                  radius: 3.5,
                  color: color,
                  strokeWidth: 2,
                  strokeColor: cardBg,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.20),
                    color.withValues(alpha: 0.01),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
