import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Opens AlloConnect's workout logging sheet.
///
/// [initialWorkout] preselects a workout by name ('Prenatal Yoga',
/// 'Pelvic Exercise', 'Walking', …). Pass [vital] (a `workout` or `exercise`
/// row) to edit it. Resolves to true when something was saved.
Future<bool?> showWorkoutEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? vital,
  String? userId,
  String? initialWorkout,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WorkoutEntryBottomSheet(
      userId: userId,
      vital: vital,
      initialWorkout: initialWorkout,
    ),
  );
}

/// Allomom stores sessions in minutes: Pelvic Exercise under `exercise`,
/// everything else under `workout`. The MET-based kcal AlloConnect computes
/// goes into `data['calories']`.
class WorkoutEntryBottomSheet extends StatefulWidget {
  final String? userId;
  final VitalsStreamResponse? vital;
  final String? initialWorkout;

  const WorkoutEntryBottomSheet({
    super.key,
    this.userId,
    this.vital,
    this.initialWorkout,
  });

  @override
  State<WorkoutEntryBottomSheet> createState() =>
      _WorkoutEntryBottomSheetState();
}

class _WorkoutEntryBottomSheetState extends State<WorkoutEntryBottomSheet> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  static const Color _workoutColor = Colors.teal;
  static const String _pelvicName = 'Pelvic Exercise';

  // Selected workout key type
  String _selectedWorkoutType = 'Prenatal Yoga';

  // Key workouts list with MET and design tokens. Allomom's two pregnancy
  // sessions lead, followed by AlloConnect's list.
  final List<Map<String, dynamic>> _keyWorkouts = [
    {
      'name': 'Prenatal Yoga',
      'met': 2.5,
      'icon': Icons.self_improvement_rounded,
      'color': const Color(0xFF6366F1),
    },
    {
      'name': _pelvicName,
      'met': 2.0,
      'icon': Icons.fitness_center_rounded,
      'color': const Color(0xFFEC4899),
    },
    {
      'name': 'Running',
      'met': 8.0,
      'icon': Icons.directions_run_rounded,
      'color': Colors.orange,
    },
    {
      'name': 'Walking',
      'met': 3.5,
      'icon': Icons.directions_walk_rounded,
      'color': Colors.green,
    },
    {
      'name': 'Cycling',
      'met': 6.0,
      'icon': Icons.directions_bike_rounded,
      'color': Colors.blue,
    },
    {
      'name': 'Swimming',
      'met': 7.0,
      'icon': Icons.pool_rounded,
      'color': Colors.cyan,
    },
    {
      'name': 'Yoga',
      'met': 2.5,
      'icon': Icons.self_improvement_rounded,
      'color': Colors.purple,
    },
    {
      'name': 'Strength Training',
      'met': 5.0,
      'icon': Icons.fitness_center_rounded,
      'color': Colors.red,
    },
    {
      'name': 'HIIT',
      'met': 9.0,
      'icon': Icons.local_fire_department_rounded,
      'color': Colors.pink,
    },
  ];

  String? _matchWorkout(dynamic raw) {
    final s = raw?.toString().trim().toLowerCase();
    if (s == null || s.isEmpty) return null;
    for (final w in _keyWorkouts) {
      if ((w['name'] as String).toLowerCase() == s) return w['name'] as String;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();

    _durationController.text = '30';

    final vital = widget.vital;
    if (vital != null) {
      final data = vital.data ?? const <String, dynamic>{};
      _selectedWorkoutType =
          _matchWorkout(data['workout_type']) ??
          _matchWorkout(data['type']) ??
          _matchWorkout(data['activity']) ??
          (vital.key == 'exercise' ? _pelvicName : 'Prenatal Yoga');
      _durationController.text = vital.value.round().toString();
      final details =
          (data['details'] ?? data['activity'])?.toString().trim() ?? '';
      _detailsController.text = details == _selectedWorkoutType ? '' : details;
      final kcal = data['calories'];
      if (kcal is num) {
        _caloriesController.text = kcal.round().toString();
      } else {
        _recalculateMETCalories();
      }
    } else {
      _selectedWorkoutType =
          _matchWorkout(widget.initialWorkout) ?? _selectedWorkoutType;
      _recalculateMETCalories();
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _detailsController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  double get _selectedMet {
    final workout = _keyWorkouts.firstWhere(
      (w) => w['name'] == _selectedWorkoutType,
      orElse: () => _keyWorkouts.first,
    );
    return workout['met'] as double;
  }

  // Calculate calories using MET formula
  void _recalculateMETCalories() {
    final double duration = double.tryParse(_durationController.text) ?? 0.0;
    final double weight = _getUserWeight();

    // Formula: Calories = MET * weight(kg) * (duration(mins)/60)
    final double caloriesBurned = _selectedMet * weight * (duration / 60.0);
    _caloriesController.text = caloriesBurned.round().toString();
  }

  double _getUserWeight() {
    final weight = HealthVitalsController.instance.weightValue;
    return weight > 0.0 ? weight : 70.0;
  }

  Future<void> _saveData() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final calories = double.tryParse(_caloriesController.text) ?? 0.0;
    final details = _detailsController.text.trim();
    final duration = int.tryParse(_durationController.text) ?? 30;

    setState(() => _saving = true);
    try {
      final existing = widget.vital;
      final userId = widget.userId?.trim().isNotEmpty == true
          ? widget.userId!.trim()
          : MainController.instance.userId;
      final key = _selectedWorkoutType == _pelvicName ? 'exercise' : 'workout';

      final result = await HealthVitalsController.instance.addVitalEntry(
        key: key,
        value: duration.toDouble(),
        unit: 'minutes',
        createdAt: existing?.createdAt ?? DateTime.now(),
        userId: userId,
        data: {
          'activity': details.isNotEmpty ? details : _selectedWorkoutType,
          'type': _selectedWorkoutType,
          'details': details.isNotEmpty ? details : _selectedWorkoutType,
          'workout_type': _selectedWorkoutType,
          'duration': duration,
          'calories': calories.round(),
          'met': _selectedMet,
        },
      );

      if (result != null && existing != null) {
        // No in-place update in Allomom: re-logged at the original time, then
        // the old row is soft-deleted (which syncs).
        await VitalsSqLiteService().deleteVital(existing.id);
        await HealthVitalsController.instance.fetchLatestVitals(
          showLoading: false,
        );
      }

      if (!mounted) return;
      if (result != null) {
        _toast(
          existing != null
              ? 'Workout updated successfully'
              : 'Workout tracked successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        _toast(
          HealthVitalsController.instance.error.isNotEmpty
              ? HealthVitalsController.instance.error
              : 'Error saving workout data',
        );
      }
    } catch (e) {
      if (mounted) _toast('Error saving workout data');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2433) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade700
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _workoutColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.local_fire_department_rounded,
                        color: _workoutColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.vital != null ? 'Edit Workout' : 'Workout Logging',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Log your activities to compute total daily expenditure and deficit stats.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                _buildActionArea(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String hint,
    required IconData icon,
    Color? iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
      prefixIcon: Icon(
        icon,
        color: iconColor ?? _workoutColor.withValues(alpha: 0.7),
        size: 20,
      ),
    );
  }

  Widget _buildActionArea(bool isDark) {
    final fieldStyle = TextStyle(
      color: isDark ? Colors.white : Colors.black87,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Select Workout', isDark),
        const SizedBox(height: 10),

        // Workout key types list
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _keyWorkouts.length,
            itemBuilder: (context, index) {
              final workout = _keyWorkouts[index];
              final String name = workout['name'];
              final IconData icon = workout['icon'];
              final Color color = workout['color'];
              final isSelected = _selectedWorkoutType == name;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWorkoutType = name;
                    _recalculateMETCalories();
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : (isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? color : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isSelected
                            ? color
                            : (isDark ? Colors.grey : Colors.grey.shade600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: isSelected
                              ? color
                              : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),

        // Duration
        _label('Duration (Minutes)', isDark),
        const SizedBox(height: 8),
        TextFormField(
          controller: _durationController,
          keyboardType: TextInputType.number,
          style: fieldStyle,
          onChanged: (val) => _recalculateMETCalories(),
          decoration: _fieldDecoration(
            isDark: isDark,
            hint: 'e.g. 30',
            icon: Icons.timer_rounded,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter workout duration';
            }
            final parsed = int.tryParse(value);
            if (parsed == null || parsed <= 0) {
              return 'Please enter a valid duration';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Workout notes/custom title
        _label('Workout Description (Optional)', isDark),
        const SizedBox(height: 8),
        TextFormField(
          controller: _detailsController,
          style: fieldStyle,
          decoration: _fieldDecoration(
            isDark: isDark,
            hint: 'e.g. Evening jogging at the park',
            icon: Icons.description_rounded,
          ),
        ),
        const SizedBox(height: 20),

        // Calorie Burn Input (calculated automatically, editable)
        Row(
          children: [
            _label('Calories Burned (kcal)', isDark),
            const SizedBox(width: 6),
            Tooltip(
              message:
                  'Calculated using MET formula for weight ${_getUserWeight().round()} kg',
              child: Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: Colors.teal.shade300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _caloriesController,
          keyboardType: TextInputType.number,
          style: fieldStyle,
          decoration: _fieldDecoration(
            isDark: isDark,
            hint: 'e.g. 250',
            icon: Icons.bolt_rounded,
            iconColor: _workoutColor,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter calories burned';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
        ),
        const SizedBox(height: 32),
        // Save button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _saving ? null : _saveData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              disabledBackgroundColor: Theme.of(
                context,
              ).primaryColor.withValues(alpha: 0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
            ),
            child: _saving
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    widget.vital != null ? 'Update Workout' : 'Save Workout',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
