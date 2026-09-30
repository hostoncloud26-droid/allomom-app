import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/allowear/core/models/steps_response_map_model.dart';
import 'package:allomom/allowear/core/models/sleep_response_map_model.dart';

import 'package:intl/intl.dart';

// Navigation Targets
import 'package:allomom/features/my_health/vitals/heart_rate/heart_rate_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/stress/stress_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/steps/steps_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/sleep/sleep_summary_screen.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_summary_screen.dart';

class AllowearVitalsList extends StatelessWidget {
  const AllowearVitalsList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final vitalsController = Get.isRegistered<HealthVitalsController>()
        ? Get.find<HealthVitalsController>()
        : Get.put(HealthVitalsController());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Padding(
        //   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        //   child: Row(
        //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //     children: [
        //       Text(
        //         'Live Vitals'.tr,
        //         style: TextStyle(
        //           fontSize: 18,
        //           fontWeight: FontWeight.w800,
        //           color: isDark ? Colors.white : const Color(0xFF2C3E50),
        //           fontFamily: 'Manrope',
        //           letterSpacing: -0.4,
        //         ),
        //       ),
        //     ],
        //   ),
        // ),
        const SizedBox(height: 8),
        const AllowearStepsTile(),
        const AllowearSleepTile(),
        AllowearVitalTile(
          title: 'Heart Rate',
          unit: 'bpm',
          icon: Icons.favorite_rounded,
          color: const Color(0xFFE74C3C),
          vitalKey: 'heart_rate',
          maxPoints: 20, // N data points for Heart Rate
          onTap: (latestValue, lastUpdatedAt, userId) =>
              Get.to(() => const HeartRateSummaryScreen()),
        ),
        AllowearVitalTile(
          title: 'Blood Oxygen',
          unit: '%',
          icon: Icons.opacity_rounded,
          color: const Color(0xFF3498DB),
          vitalKey: 'blood_oxygen',
          maxPoints: 10, // N data points for SpO2
          onTap: (latestValue, lastUpdatedAt, userId) {
            if (userId.isNotEmpty) {
              Get.to(() => BloodOxygenSummaryScreen(userId: userId));
            }
          },
        ),
        AllowearVitalTile(
          title: 'Stress Load',
          unit: '/100',
          icon: Icons.psychology_alt_rounded,
          color: const Color(0xFFF39C12),
          vitalKey: 'stress',
          maxPoints: 15, // N data points for Stress
          onTap: (latestValue, lastUpdatedAt, userId) {
            if (userId.isNotEmpty) {
              Get.to(() => StressSummaryScreen(
                    userId: userId,
                    initialStress: latestValue?.round() ?? 0,
                    lastUpdatedAt: lastUpdatedAt,
                  ));
            }
          },
        ),
        AllowearVitalTile(
          title: 'Blood Pressure',
          unit: 'mmHg',
          icon: Icons.speed_rounded,
          color: const Color(0xFF9B59B6),
          vitalKey: 'blood_pressure',
          maxPoints: 15,
          // The row's value is the systolic; the diastolic lives in `data`.
          formatValue: (vital) {
            final diastolic = vital.data?['diastolic'];
            return diastolic is num
                ? '${vital.value.round()}/${diastolic.round()}'
                : '${vital.value.round()}';
          },
          onTap: (latestValue, lastUpdatedAt, userId) =>
              Get.to(() => const BloodPressureSummaryScreen()),
        ),
        AllowearVitalTile(
          title: 'Temperature',
          unit: '°C',
          icon: Icons.thermostat_rounded,
          color: const Color(0xFFFF8A3D),
          vitalKey: 'temperature',
          maxPoints: 15,
          formatValue: (vital) => vital.value.toStringAsFixed(1),
          onTap: (latestValue, lastUpdatedAt, userId) {},
        ),
      ],
    );
  }
}

class AllowearVitalTile extends StatefulWidget {
  final String title;
  final String unit;
  final IconData icon;
  final Color color;
  final String vitalKey;
  final int maxPoints;
  final void Function(
      double? latestValue, DateTime? lastUpdatedAt, String userId) onTap;

  /// How the latest reading is shown; defaults to the value rounded.
  final String Function(VitalsStreamResponse vital)? formatValue;

  const AllowearVitalTile({
    super.key,
    required this.title,
    required this.unit,
    required this.icon,
    required this.color,
    required this.vitalKey,
    required this.maxPoints,
    required this.onTap,
    this.formatValue,
  });

  @override
  State<AllowearVitalTile> createState() => _AllowearVitalTileState();
}

class _AllowearVitalTileState extends State<AllowearVitalTile> {
  final HealthVitalsController _vitalsController =
      Get.isRegistered<HealthVitalsController>()
          ? Get.find<HealthVitalsController>()
          : Get.put(HealthVitalsController());

  List<VitalsStreamResponse> _history = [];
  bool _isLoading = true;

  // Listeners for DB & User ID subscription
  VoidCallback? _vitalsSubscription;

  @override
  void initState() {
    super.initState();
    _loadHistoryFromDatabase();

    // Subscribe to DB changes: Whenever the controller's vitals list changes,
    // it signals that a new sync, update, or vital addition has happened in SQLite.
    // Allomom: the vitals controller calls update() after every write, sync
    // and reload (it is not reactive), so a listener stands in for .listen.
    _vitalsSubscription = _vitalsController.addListener(_loadHistoryFromDatabase);

    // Subscribe to User ID changes: If user switches, reload correct SQLite entries
  }

  @override
  void dispose() {
    _vitalsSubscription?.call();
    super.dispose();
  }

  Future<void> _loadHistoryFromDatabase() async {
    final userId = _vitalsController.userId.trim();
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _history = [];
          _isLoading = false;
        });
      }
      return;
    }

    try {
      // Query history directly from SQLite
      final rawHistory = await VitalsSqLiteService().getVitalsHistory(
        userId,
        widget.vitalKey,
      );

      final List<VitalsStreamResponse> parsedHistory = rawHistory.map((map) {
        final rawData = map['data'];
        final parsedData = rawData is String && rawData.isNotEmpty
            ? jsonDecode(rawData) as Map<String, dynamic>?
            : rawData as Map<String, dynamic>?;

        final createdAtVal = map['createdAt'];
        final DateTime createdAtDate = createdAtVal is DateTime
            ? createdAtVal
            : DateTime.parse(createdAtVal.toString());

        return VitalsStreamResponse(
          id: map['id']?.toString() ?? '',
          key: map['vital_key']?.toString() ?? '',
          value: (map['value'] as num?)?.toDouble() ?? 0.0,
          unit: map['unit']?.toString() ?? '',
          createdAt: createdAtDate,
          data: parsedData,
        );
      }).toList();

      // Sort chronological (oldest first for sparkline)
      parsedHistory.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Separate data taken today
      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final todayEntries = parsedHistory
          .where((v) =>
              v.createdAt.isAfter(startOfToday) ||
              v.createdAt.isAtSameMomentAs(startOfToday))
          .toList();

      List<VitalsStreamResponse> finalHistory;
      if (todayEntries.length >= 2) {
        // Show today's data, limited to maxPoints
        finalHistory = todayEntries.length > widget.maxPoints
            ? todayEntries.sublist(todayEntries.length - widget.maxPoints)
            : todayEntries;
      } else {
        // Fallback to last N data points overall to ensure trendline is visible
        finalHistory = parsedHistory.length > widget.maxPoints
            ? parsedHistory.sublist(parsedHistory.length - widget.maxPoints)
            : parsedHistory;
      }

      if (mounted) {
        setState(() {
          _history = finalHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading history for vital key ${widget.vitalKey}: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final latest = _history.isNotEmpty ? _history.last : null;
    final valueStr = latest == null
        ? '--'
        : widget.formatValue?.call(latest) ?? '${latest.value.round()}';
    final timeStr = latest != null ? _timeAgo(latest.createdAt) : '';

    final backgroundColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final userId = _vitalsController.userId.trim();
              widget.onTap(latest?.value, latest?.createdAt, userId);
            },
            splashColor: widget.color.withOpacity(0.1),
            highlightColor: widget.color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // Left side: Icon, Title, Value, Time-ago
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: widget.color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(widget.icon,
                                  color: widget.color, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              widget.title.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor.withOpacity(0.6),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              valueStr,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                fontFamily: 'Manrope',
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.unit,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 10,
                                  color: widget.color.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: widget.color.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Right side: Sleek Sparkline Graph
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.black.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _history.isEmpty
                              ? Center(
                                  child: Text(
                                    'No data'.tr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor.withOpacity(0.3),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    final height = constraints.maxHeight;

                                    final minVal = _history
                                        .map((e) => e.value)
                                        .reduce(math.min);
                                    final maxVal = _history
                                        .map((e) => e.value)
                                        .reduce(math.max);
                                    final range = maxVal - minVal == 0
                                        ? 10.0
                                        : maxVal - minVal;

                                    // Build coordinates
                                    final points = <Offset>[];
                                    final stepX = _history.length > 1
                                        ? width / (_history.length - 1)
                                        : width;

                                    for (int i = 0; i < _history.length; i++) {
                                      final x = i * stepX;
                                      final normY =
                                          (_history[i].value - minVal) / range;
                                      // Invert Y coordinate since 0,0 is top-left
                                      final y =
                                          height - (normY * (height - 8)) - 4;
                                      points.add(Offset(x, y));
                                    }

                                    return CustomPaint(
                                      size: Size(width, height),
                                      painter: _MiniSparklinePainter(
                                        points: points,
                                        color: widget.color,
                                        isDark: isDark,
                                      ),
                                    );
                                  },
                                ),
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

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago'.tr;
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago'.tr;
    } else {
      return '${difference.inDays}d ago'.tr;
    }
  }
}

class _MiniSparklinePainter extends CustomPainter {
  final List<Offset> points;
  final Color color;
  final bool isDark;

  _MiniSparklinePainter({
    required this.points,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    if (points.length == 1) {
      canvas.drawCircle(points.first, 3.5, Paint()..color = color);
      return;
    }

    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];

      // Smooth spline control points
      final cp1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final cp2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);

      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, p1.dx, p1.dy);
    }

    // Fill path
    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.18),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // Stroke path
    final strokePaint = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw a prominent glowing dot on the latest point
    final lastPoint = points.last;
    final dotGlow = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final dotCore = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = isDark ? const Color(0xff1E1E1E) : Colors.white
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(lastPoint, 6.0, dotGlow);
    canvas.drawCircle(lastPoint, 3.5, dotCore);
    canvas.drawCircle(lastPoint, 3.5, dotBorder);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

// ==========================================
// Allowear Steps Count Tile
// ==========================================
class AllowearStepsTile extends StatefulWidget {
  const AllowearStepsTile({super.key});

  @override
  State<AllowearStepsTile> createState() => _AllowearStepsTileState();
}

class _AllowearStepsTileState extends State<AllowearStepsTile> {
  final HealthVitalsController _vitalsController =
      Get.isRegistered<HealthVitalsController>()
          ? Get.find<HealthVitalsController>()
          : Get.put(HealthVitalsController());

  int _totalSteps = 0;
  List<int> _hourlySteps = List.filled(24, 0);
  DateTime? _lastUpdatedAt;
  bool _isLoading = true;

  VoidCallback? _vitalsSubscription;

  @override
  void initState() {
    super.initState();
    _loadStepsFromDatabase();

    // Allomom: the vitals controller calls update() after every write, sync
    // and reload (it is not reactive), so a listener stands in for .listen.
    _vitalsSubscription = _vitalsController.addListener(_loadStepsFromDatabase);
  }

  @override
  void dispose() {
    _vitalsSubscription?.call();
    super.dispose();
  }

  Future<void> _loadStepsFromDatabase() async {
    final userId = _vitalsController.userId.trim();
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _totalSteps = 0;
          _hourlySteps = List.filled(24, 0);
          _lastUpdatedAt = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final rawHistory = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'steps',
      );

      if (rawHistory.isEmpty) {
        if (mounted) {
          setState(() {
            _totalSteps = 0;
            _hourlySteps = List.filled(24, 0);
            _lastUpdatedAt = null;
            _isLoading = false;
          });
        }
        return;
      }

      final latestRecord = rawHistory.first;
      final rawData = latestRecord['data'];
      final parsedData = rawData is String && rawData.isNotEmpty
          ? jsonDecode(rawData) as Map<String, dynamic>?
          : rawData as Map<String, dynamic>?;

      final createdAtVal = latestRecord['createdAt'];
      final DateTime createdAtDate = createdAtVal is DateTime
          ? createdAtVal
          : DateTime.parse(createdAtVal.toString());

      final now = DateTime.now();
      final isToday = createdAtDate.year == now.year &&
          createdAtDate.month == now.month &&
          createdAtDate.day == now.day;

      int totalSteps = 0;
      final List<int> hourlySteps = List.filled(24, 0);

      if (isToday) {
        if (parsedData != null) {
          final model = StepsResponseMapModel.fromJson(parsedData);
          totalSteps = model.steps;
          for (final hourItem in model.hourlyData) {
            if (hourItem.hour >= 0 && hourItem.hour < 24) {
              hourlySteps[hourItem.hour] = hourItem.steps;
            }
          }
        } else {
          totalSteps = (latestRecord['value'] as num?)?.toInt() ?? 0;
          final hour = createdAtDate.hour;
          if (hour >= 0 && hour < 24) {
            hourlySteps[hour] = totalSteps;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalSteps = totalSteps;
          _hourlySteps = hourlySteps;
          _lastUpdatedAt = isToday ? createdAtDate : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading steps history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final valueStr = NumberFormat('#,###').format(_totalSteps);
    final lastUpdated = _lastUpdatedAt;
    final timeStr = lastUpdated != null ? _timeAgo(lastUpdated) : '';

    final backgroundColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    const tileColor = Color(0xFF00E676);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final userId = _vitalsController.userId.trim();
              if (userId.isNotEmpty) {
                Get.to(() => StepsSummaryScreen(
                      userId: userId,
                      initialSteps: _totalSteps,
                    ));
              }
            },
            splashColor: tileColor.withOpacity(0.1),
            highlightColor: tileColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: tileColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.directions_walk_rounded,
                                  color: tileColor, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Step Count'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor.withOpacity(0.6),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              valueStr,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                fontFamily: 'Manrope',
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'steps'.tr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: textColor.withOpacity(0.4),
                              ),
                            ),
                          ],
                        ),
                        if (timeStr.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded,
                                  size: 10, color: tileColor.withOpacity(0.6)),
                              const SizedBox(width: 4),
                              Text(
                                timeStr,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: tileColor.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.black.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : CustomPaint(
                              size: Size.infinite,
                              painter: _MiniBarChartPainter(
                                hourlySteps: _hourlySteps,
                                color: tileColor,
                                isDark: isDark,
                              ),
                            ),
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

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inSeconds < 60) {
      return 'Just now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago'.tr;
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago'.tr;
    } else {
      return '${difference.inDays}d ago'.tr;
    }
  }
}

class _MiniBarChartPainter extends CustomPainter {
  final List<int> hourlySteps;
  final Color color;
  final bool isDark;

  _MiniBarChartPainter({
    required this.hourlySteps,
    required this.color,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hourlySteps.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    final int maxSteps = hourlySteps.reduce(math.max);
    final double maxVal = maxSteps == 0 ? 100.0 : maxSteps.toDouble();

    final int length = hourlySteps.length;
    final double spacing = 1.5;
    final double barWidth = (width - (spacing * (length - 1))) / length;

    final Paint barPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          color.withOpacity(0.3),
          color,
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    final Paint bgPaint = Paint()
      ..color = isDark
          ? Colors.white.withOpacity(0.03)
          : Colors.black.withOpacity(0.02)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < length; i++) {
      final double x = i * (barWidth + spacing);
      final RRect bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, height),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(bgRect, bgPaint);

      final double val = hourlySteps[i].toDouble();
      final double barHeight = (val / maxVal) * (height - 4);
      if (barHeight > 0) {
        final double y = height - barHeight;
        final RRect rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(1.5),
        );
        canvas.drawRRect(rect, barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MiniBarChartPainter oldDelegate) {
    return oldDelegate.hourlySteps != hourlySteps ||
        oldDelegate.color != color ||
        oldDelegate.isDark != isDark;
  }
}

// ==========================================
// Allowear Sleep Tile
// ==========================================
class AllowearSleepTile extends StatefulWidget {
  const AllowearSleepTile({super.key});

  @override
  State<AllowearSleepTile> createState() => _AllowearSleepTileState();
}

class _AllowearSleepTileState extends State<AllowearSleepTile> {
  final HealthVitalsController _vitalsController =
      Get.isRegistered<HealthVitalsController>()
          ? Get.find<HealthVitalsController>()
          : Get.put(HealthVitalsController());

  int _totalSleepMinutes = 0;
  DateTime? _sleepTime;
  DateTime? _wakeTime;
  double _deepRatio = 0.0;
  double _lightRatio = 0.0;
  double _remRatio = 0.0;
  double _awakeRatio = 0.0;
  DateTime? _lastUpdatedAt;
  bool _isLoading = true;

  VoidCallback? _vitalsSubscription;

  @override
  void initState() {
    super.initState();
    _loadSleepFromDatabase();

    // Allomom: the vitals controller calls update() after every write, sync
    // and reload (it is not reactive), so a listener stands in for .listen.
    _vitalsSubscription = _vitalsController.addListener(_loadSleepFromDatabase);
  }

  @override
  void dispose() {
    _vitalsSubscription?.call();
    super.dispose();
  }

  Future<void> _loadSleepFromDatabase() async {
    final userId = _vitalsController.userId.trim();
    if (userId.isEmpty) {
      if (mounted) {
        setState(() {
          _totalSleepMinutes = 0;
          _sleepTime = null;
          _wakeTime = null;
          _deepRatio = 0.0;
          _lightRatio = 0.0;
          _remRatio = 0.0;
          _awakeRatio = 0.0;
          _lastUpdatedAt = null;
          _isLoading = false;
        });
      }
      return;
    }

    try {
      final rawHistory = await VitalsSqLiteService().getVitalsHistory(
        userId,
        'sleep_data',
      );

      if (rawHistory.isEmpty) {
        if (mounted) {
          setState(() {
            _totalSleepMinutes = 0;
            _sleepTime = null;
            _wakeTime = null;
            _deepRatio = 0.0;
            _lightRatio = 0.0;
            _remRatio = 0.0;
            _awakeRatio = 0.0;
            _lastUpdatedAt = null;
            _isLoading = false;
          });
        }
        return;
      }

      final latestRecord = rawHistory.first;
      final rawData = latestRecord['data'];
      final parsedData = rawData is String && rawData.isNotEmpty
          ? jsonDecode(rawData) as Map<String, dynamic>?
          : rawData as Map<String, dynamic>?;

      final createdAtVal = latestRecord['createdAt'];
      final DateTime createdAtDate = createdAtVal is DateTime
          ? createdAtVal
          : DateTime.parse(createdAtVal.toString());

      final now = DateTime.now();
      final isToday = createdAtDate.year == now.year &&
          createdAtDate.month == now.month &&
          createdAtDate.day == now.day;

      DateTime? sleepTime;
      DateTime? wakeTime;
      int totalMinutes = 0;
      double deepRatio = 0.0;
      double lightRatio = 0.0;
      double remRatio = 0.0;
      double awakeRatio = 0.0;

      if (isToday) {
        if (parsedData != null) {
          try {
            final model = SleepResponseMapModel.fromJson(parsedData);
            sleepTime = model.sleepTime;
            wakeTime = model.awakeTime;
            totalMinutes = model.totalSleepDuration;
            if (totalMinutes <= 0 && wakeTime.isAfter(sleepTime)) {
              totalMinutes = wakeTime.difference(sleepTime).inMinutes;
            }
            totalMinutes = math.max(0, totalMinutes);

            int deep = math.max(0, model.deepSleepDuration);
            int light = math.max(0, model.lightSleepDuration);
            int rem = math.max(0, model.remSleepDuration);
            int awake = math.max(0, model.awakeDuration);

            if (totalMinutes > 0 && deep == 0 && light == 0 && rem == 0) {
              deep = (totalMinutes * 0.22).round();
              rem = (totalMinutes * 0.20).round();
              light = math.max(0, totalMinutes - deep - rem);
            }

            if (totalMinutes > 0) {
              deepRatio = deep / totalMinutes;
              lightRatio = light / totalMinutes;
              remRatio = rem / totalMinutes;
              awakeRatio = awake / totalMinutes;
            }
          } catch (_) {}
        }

        if (totalMinutes == 0) {
          final val = (latestRecord['value'] as num?)?.toDouble() ?? 0.0;
          totalMinutes = (val * 60).round();
          wakeTime = createdAtDate;
          sleepTime = wakeTime.subtract(Duration(minutes: totalMinutes));

          final deep = (totalMinutes * 0.22).round();
          final rem = (totalMinutes * 0.20).round();
          final light = math.max(0, totalMinutes - deep - rem);

          if (totalMinutes > 0) {
            deepRatio = deep / totalMinutes;
            lightRatio = light / totalMinutes;
            remRatio = rem / totalMinutes;
            awakeRatio = 0.0;
          }
        }
      }

      if (mounted) {
        setState(() {
          _totalSleepMinutes = totalMinutes;
          _sleepTime = sleepTime;
          _wakeTime = wakeTime;
          _deepRatio = deepRatio;
          _lightRatio = lightRatio;
          _remRatio = remRatio;
          _awakeRatio = awakeRatio;
          _lastUpdatedAt = isToday ? createdAtDate : null;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading sleep history: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final int hours = _totalSleepMinutes ~/ 60;
    final int minutes = _totalSleepMinutes % 60;
    final valueStr = _totalSleepMinutes > 0 ? '${hours}h ${minutes}m' : '--';

    final DateFormat timeFormat = DateFormat('hh:mm a');
    final sleep = _sleepTime;
    final wake = _wakeTime;
    final sleepTimeStr = sleep != null ? timeFormat.format(sleep) : '--';
    final wakeTimeStr = wake != null ? timeFormat.format(wake) : '--';

    final backgroundColor = Theme.of(context).cardColor;
    final borderColor = isDark
        ? Colors.white.withOpacity(0.06)
        : Colors.black.withOpacity(0.04);
    final textColor = isDark ? Colors.white : const Color(0xFF2C3E50);
    const tileColor = Color(0xFF6366F1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              final userId = _vitalsController.userId.trim();
              if (userId.isNotEmpty) {
                Get.to(() => SleepSummaryScreen(
                      userId: userId,
                      initialSleepHours: _totalSleepMinutes / 60.0,
                      bedTime: _sleepTime,
                      wakeTime: _wakeTime,
                    ));
              }
            },
            splashColor: tileColor.withOpacity(0.1),
            highlightColor: tileColor.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: tileColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.nights_stay_rounded,
                                  color: tileColor, size: 16),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sleep'.tr,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: textColor.withOpacity(0.6),
                                fontFamily: 'Manrope',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              valueStr,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: textColor,
                                fontFamily: 'Manrope',
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        if (_totalSleepMinutes > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.bedtime_outlined,
                                  size: 10, color: tileColor.withOpacity(0.6)),
                              const SizedBox(width: 3),
                              Text(
                                sleepTimeStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text('|',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: textColor.withOpacity(0.2))),
                              const SizedBox(width: 5),
                              Icon(Icons.wb_sunny_outlined,
                                  size: 10,
                                  color: Colors.orange.withOpacity(0.6)),
                              const SizedBox(width: 3),
                              Text(
                                wakeTimeStr,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: textColor.withOpacity(0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: Container(
                      height: 70,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.02)
                            : Colors.black.withOpacity(0.01),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _totalSleepMinutes == 0
                              ? Center(
                                  child: Text(
                                    'No data'.tr,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: textColor.withOpacity(0.3),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _SleepStageRatioBar(
                                      deepRatio: _deepRatio,
                                      lightRatio: _lightRatio,
                                      remRatio: _remRatio,
                                      awakeRatio: _awakeRatio,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        _buildStagePercent('Deep', _deepRatio,
                                            const Color(0xFF4F46E5), textColor),
                                        _buildStagePercent('Light', _lightRatio,
                                            const Color(0xFF0EA5E9), textColor),
                                        _buildStagePercent('REM', _remRatio,
                                            const Color(0xFF9333EA), textColor),
                                      ],
                                    ),
                                  ],
                                ),
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

  Widget _buildStagePercent(
      String label, double ratio, Color color, Color textColor) {
    final pct = (ratio * 100).round();
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 3),
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: textColor.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

class _SleepStageRatioBar extends StatelessWidget {
  final double deepRatio;
  final double lightRatio;
  final double remRatio;
  final double awakeRatio;

  const _SleepStageRatioBar({
    required this.deepRatio,
    required this.lightRatio,
    required this.remRatio,
    required this.awakeRatio,
  });

  @override
  Widget build(BuildContext context) {
    final totalRatio = deepRatio + lightRatio + remRatio + awakeRatio;
    if (totalRatio <= 0) {
      return Container(
        height: 8,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(4),
        ),
      );
    }

    final d = deepRatio / totalRatio;
    final l = lightRatio / totalRatio;
    final r = remRatio / totalRatio;
    final a = awakeRatio / totalRatio;

    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            if (d > 0)
              Expanded(
                  flex: (d * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF4F46E5))),
            if (l > 0)
              Expanded(
                  flex: (l * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF0EA5E9))),
            if (r > 0)
              Expanded(
                  flex: (r * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFF9333EA))),
            if (a > 0)
              Expanded(
                  flex: (a * 100).round().clamp(1, 100),
                  child: Container(color: const Color(0xFFF59E0B))),
          ],
        ),
      ),
    );
  }
}
