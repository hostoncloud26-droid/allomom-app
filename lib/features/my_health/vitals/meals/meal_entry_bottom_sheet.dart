// Ported from AlloConnect lib/features/health_section/vitals/{breakfast,lunch,dinner}/
// *_entry_bottom_sheet.dart. AlloConnect's AI food analysis, camera photo and
// Auto/Manual toggle are left out, so the sheet is always in its Manual mode.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'meal_kind.dart';
import 'meal_vitals_store.dart';

/// Opens the add (when [vital] is null) or edit sheet for [meal].
/// Resolves to true when a row was saved, updated or deleted.
Future<bool?> showMealEntrySheet(
  BuildContext context, {
  required MealKind meal,
  VitalsStreamResponse? vital,
  String? userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MealEntryBottomSheet(
      meal: meal,
      vital: vital,
      userId: MealVitalsStore.resolveUserId(userId),
    ),
  );
}

/// The note a meal row shows: `details` (AlloConnect / Today's care) or
/// `items` (My Health / Home).
String? mealDetailsOf(VitalsStreamResponse vital) {
  for (final k in const ['details', 'items']) {
    final v = vital.data?[k]?.toString().trim();
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

class MealEntryBottomSheet extends StatefulWidget {
  final MealKind meal;
  final String userId;
  final VitalsStreamResponse? vital;

  const MealEntryBottomSheet({
    super.key,
    required this.meal,
    required this.userId,
    this.vital,
  });

  @override
  State<MealEntryBottomSheet> createState() => _MealEntryBottomSheetState();
}

class _MealEntryBottomSheetState extends State<MealEntryBottomSheet> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDateTime;
  bool _busy = false;

  MealKind get _meal => widget.meal;

  @override
  void initState() {
    super.initState();
    final vital = widget.vital;
    if (vital != null) {
      _caloriesController.text = vital.value.toInt().toString();
      _detailsController.text = mealDetailsOf(vital) ?? '';
      _selectedDateTime = vital.createdAt;
    } else {
      _selectedDateTime = DateTime.now();
    }
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _toast(ScaffoldMessengerState? messenger, String msg) {
    messenger?.showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );
    if (picked != null) {
      setState(() {
        _selectedDateTime = DateTime(
          _selectedDateTime.year,
          _selectedDateTime.month,
          _selectedDateTime.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  Future<void> _deleteVital() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF1E2433) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Delete ${_meal.label} Log',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: Text(
            'Are you sure you want to delete this ${_meal.lower} log?',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDarkMode ? Colors.grey.shade300 : Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await MealVitalsStore.deleteVital(widget.vital!.id);
      navigator.pop(true);
      _toast(messenger, '${_meal.label} deleted successfully');
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _toast(messenger, 'Error deleting ${_meal.lower} data');
    }
  }

  Future<void> _saveData() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final details = _detailsController.text.trim();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);

    // Allomom's shape (items/details/meal) plus AlloConnect's timing fields.
    final data = <String, dynamic>{
      ...?widget.vital?.data,
      'items': details,
      'details': details,
      'meal': _meal.label,
      'type': _meal.vitalKey,
      'meal_type': _meal.vitalKey,
      'eating_time': DateFormat('h:mm a').format(_selectedDateTime),
      'when_ate': DateFormat('h:mm a').format(_selectedDateTime),
      'time': DateFormat('HH:mm').format(_selectedDateTime),
    };

    setState(() => _busy = true);
    try {
      bool ok;
      if (widget.vital != null) {
        await MealVitalsStore.updateVital(
          id: widget.vital!.id,
          value: calories,
          unit: 'kcal',
          createdAt: _selectedDateTime,
          data: data,
        );
        ok = true;
      } else {
        final result = await HealthVitalsController.instance.addVitalEntry(
          key: _meal.vitalKey,
          value: calories,
          unit: 'kcal',
          createdAt: _selectedDateTime,
          userId: widget.userId,
          data: data,
        );
        ok = result != null;
      }

      if (ok) {
        navigator.pop(true);
        _toast(
          messenger,
          widget.vital != null
              ? '${_meal.label} updated successfully'
              : '${_meal.label} tracked successfully',
        );
      } else {
        if (mounted) setState(() => _busy = false);
        final err = HealthVitalsController.instance.error;
        _toast(messenger,
            err.isNotEmpty ? err : 'Error saving ${_meal.lower} data');
      }
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _toast(messenger, 'Error saving ${_meal.lower} data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mealColor = _meal.entryColor;
    final fieldColor = _meal.entryFieldColor;
    final labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
    );

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
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
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
                      color: mealColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_meal.entryIcon, color: mealColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.vital != null
                        ? 'Edit ${_meal.label}'
                        : '${_meal.label} Tracking',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (widget.vital != null) ...[
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                      ),
                      onPressed: _busy ? null : _deleteVital,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Text(
                _meal.entrySubtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 32),

              // Details
              Text('What did you have?', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _detailsController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  isDark: isDark,
                  hint: _meal.detailsHint,
                  icon: Icons.restaurant_rounded,
                  iconColor: fieldColor,
                ),
              ),
              const SizedBox(height: 24),

              // Time Picker
              Text('When did you have this?', style: labelStyle),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectTime,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: mealColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('h:mm a').format(_selectedDateTime),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Calories
              Text('Calories (kcal)', style: labelStyle),
              const SizedBox(height: 8),
              TextFormField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveData(),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                decoration: _fieldDecoration(
                  isDark: isDark,
                  hint: _meal.caloriesHint,
                  icon: Icons.bolt_rounded,
                  iconColor: fieldColor,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter calories';
                  }
                  if (double.tryParse(value.trim()) == null) {
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
                  onPressed: _busy ? null : _saveData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    disabledBackgroundColor:
                        theme.primaryColor.withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    elevation: 0,
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          widget.vital != null
                              ? 'Update ${_meal.label}'
                              : 'Save ${_meal.label}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required bool isDark,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.all(16),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
    );
  }
}
