import 'package:flutter/material.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/vitals/workout/workout_entry_bottom_sheet.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'nutrition/health_tile_parts.dart';

const Color _yogaColor = Color(0xFF6366F1);
const Color _pelvicColor = Color(0xFFEC4899);

/// The day's gentle pregnancy fitness as AlloConnect's workout tile — total
/// active minutes, the latest session and quick logs for Prenatal Yoga
/// (`workout`) and Pelvic Exercise (`exercise`), both stored in minutes.
///
/// Shows [date] (today when null). A past day is read-only.
class FitnessTiles extends StatefulWidget {
  final String? userId;

  /// Day whose workouts are shown. Defaults to today when omitted.
  final DateTime? date;

  const FitnessTiles({
    super.key,
    this.userId,
    this.date,
  });

  @override
  State<FitnessTiles> createState() => _FitnessTilesState();
}

class _FitnessTilesState extends State<FitnessTiles> {
  List<VitalsStreamResponse> _sessions = const [];
  int _loadSeq = 0;

  DateTime get _selectedDate => widget.date ?? DateTime.now();
  bool get _readOnly => !DateUtils.isSameDay(_selectedDate, DateTime.now());

  @override
  void initState() {
    super.initState();
    _loadFitnessData();
    HealthVitalsController.instance.addListener(_loadFitnessData);
  }

  @override
  void didUpdateWidget(covariant FitnessTiles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId ||
        !DateUtils.isSameDay(oldWidget.date ?? DateTime.now(), _selectedDate)) {
      _loadFitnessData();
    }
  }

  @override
  void dispose() {
    HealthVitalsController.instance.removeListener(_loadFitnessData);
    super.dispose();
  }

  Future<void> _loadFitnessData() async {
    if (!mounted) return;
    final seq = ++_loadSeq;
    try {
      final targetUserId = widget.userId ?? MainController.instance.userId;
      final bounds = dayBounds(_selectedDate);
      final service = VitalsSqLiteService();

      final results = await Future.wait([
        for (final key in const ['workout', 'exercise'])
          service.getVitalsHistory(
            targetUserId,
            key,
            fromDate: bounds.start,
            toDate: bounds.end,
          ),
      ]);
      if (!mounted || seq != _loadSeq) return;

      final sessions = [
        for (final rows in results) ...rows.map(vitalFromRow),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() => _sessions = sessions);
    } catch (e) {
      debugPrint('FitnessTiles: failed to load day: $e');
    }
  }

  Future<void> _logWorkout(String workout) async {
    if (_readOnly) return;
    final saved = await showWorkoutEntrySheet(
      context,
      userId: widget.userId ?? MainController.instance.userId,
      initialWorkout: workout,
    );
    if (saved == true && mounted) await _loadFitnessData();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Fitness',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 8),
        _WorkoutTile(
          sessions: _sessions,
          readOnly: _readOnly,
          onLogYoga: () => _logWorkout('Prenatal Yoga'),
          onLogPelvic: () => _logWorkout('Pelvic Exercise'),
        ),
      ],
    );
  }
}

/// AlloConnect's workout tile, fed by Allomom's minute-based sessions.
class _WorkoutTile extends StatelessWidget {
  final List<VitalsStreamResponse> sessions;
  final bool readOnly;
  final VoidCallback onLogYoga;
  final VoidCallback onLogPelvic;

  const _WorkoutTile({
    required this.sessions,
    required this.readOnly,
    required this.onLogYoga,
    required this.onLogPelvic,
  });

  static final Color _workoutColor = Colors.teal.shade500;

  bool _isPelvic(VitalsStreamResponse v) => v.key == 'exercise';

  String _nameOf(VitalsStreamResponse v) {
    final activity = v.data?['activity']?.toString().trim();
    if (activity != null && activity.isNotEmpty) return activity;
    final type = v.data?['type']?.toString().trim();
    if (type != null && type.isNotEmpty) return type;
    return _isPelvic(v) ? 'Pelvic Exercise' : 'Prenatal Yoga';
  }

  @override
  Widget build(BuildContext context) {
    final hasData = sessions.isNotEmpty;
    return HealthTilePressable(
      child: HealthTileCard(
        key: ValueKey(hasData ? 'tracked' : 'empty'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            hasData ? _tracked(context) : _empty(context),
            if (!readOnly) ...[
              const SizedBox(height: 20),
              Container(height: 1, color: tileBorderColor(context)),
              const SizedBox(height: 16),
              Row(
                children: [
                  HealthTileQuickAction(
                    label: 'Prenatal Yoga',
                    icon: Icons.self_improvement_rounded,
                    color: _yogaColor,
                    onTap: onLogYoga,
                  ),
                  const SizedBox(width: 8),
                  HealthTileQuickAction(
                    label: 'Pelvic Exercise',
                    icon: Icons.fitness_center_rounded,
                    color: _pelvicColor,
                    onTap: onLogPelvic,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tracked(BuildContext context) {
    final textColor = tileTextColor(context);
    final latest = sessions.first;
    final latestColor = _isPelvic(latest) ? _pelvicColor : _yogaColor;
    final latestIcon = _isPelvic(latest)
        ? Icons.fitness_center_rounded
        : Icons.self_improvement_rounded;
    final totalMinutes = sessions.fold<double>(0, (s, v) => s + v.value);
    final kcal = (totalMinutes * kWorkoutKcalPerMinute).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HealthTileHeader(
          title: readOnly ? 'Workouts' : 'Workouts Today',
          accent: _workoutColor,
          trailing: [HealthTileBadge(text: 'ACTIVE', color: _workoutColor)],
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthTileBigValue(
                    value: '${totalMinutes.round()}',
                    unit: 'mins active',
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(latestIcon, size: 16, color: latestColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${_nameOf(latest)} (${latest.value.round()}m)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${sessions.length} ${sessions.length == 1 ? 'Session' : 'Sessions'} · ~$kcal kcal',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: textColor.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HealthTileHeader(title: 'Workouts', accent: _workoutColor, muted: true),
        const SizedBox(height: 16),
        HealthTileEmptyCopy(
          title: readOnly ? 'No Workouts logged' : 'Track Workouts',
          hint: 'Gentle yoga and pelvic floor work keep you strong.',
        ),
      ],
    );
  }
}
