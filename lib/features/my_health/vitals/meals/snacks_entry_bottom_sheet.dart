// Ported from AlloConnect lib/features/health_section/vitals/snacks/snacks_entry_bottom_sheet.dart.
// AlloConnect's AI food analysis, camera photo and Auto/Manual toggle are left
// out, so the sheet is always in its Manual mode.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';

import 'meal_entry_bottom_sheet.dart' show mealDetailsOf;
import 'meal_vitals_store.dart';

/// Opens the add (when [vital] is null) or edit snack sheet.
/// Resolves to true when a row was saved or updated.
Future<bool?> showSnacksEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? vital,
  String? userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => SnacksEntryBottomSheet(
      vital: vital,
      userId: MealVitalsStore.resolveUserId(userId),
    ),
  );
}

class SnacksEntryBottomSheet extends StatefulWidget {
  final String userId;
  final VitalsStreamResponse? vital;

  const SnacksEntryBottomSheet({super.key, required this.userId, this.vital});

  @override
  State<SnacksEntryBottomSheet> createState() => _SnacksEntryBottomSheetState();
}

class _SnacksEntryBottomSheetState extends State<SnacksEntryBottomSheet> {
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final vital = widget.vital;
    if (vital != null) {
      _caloriesController.text = vital.value.toInt().toString();
      _detailsController.text = mealDetailsOf(vital) ?? '';
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

  Future<void> _saveData() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    final calories = double.tryParse(_caloriesController.text.trim()) ?? 0.0;
    final details = _detailsController.text.trim();
    final messenger = ScaffoldMessenger.maybeOf(context);
    final navigator = Navigator.of(context);
    final existing = widget.vital;
    final when = existing?.createdAt ?? DateTime.now();

    // Home's snack shape (kcal in value, portions in data['count']) plus the
    // note AlloConnect collects. An edit keeps the row's own count.
    final data = <String, dynamic>{
      'count': 1,
      'count_unit': 'portions',
      ...?existing?.data,
      'details': details,
      'items': details,
      'meal': 'Snacks',
      'type': 'snacks',
      'meal_type': 'snacks',
      'time': DateFormat('HH:mm').format(when),
    };

    setState(() => _busy = true);
    try {
      bool ok;
      if (existing != null) {
        await MealVitalsStore.updateVital(
          id: existing.id,
          value: calories,
          unit: 'kcal',
          createdAt: existing.createdAt,
          data: data,
        );
        ok = true;
      } else {
        final result = await HealthVitalsController.instance.addVitalEntry(
          key: 'snacks',
          value: calories,
          unit: 'kcal',
          createdAt: when,
          userId: widget.userId,
          data: data,
        );
        ok = result != null;
      }

      if (ok) {
        navigator.pop(true);
        _toast(
          messenger,
          existing != null
              ? 'Snacks updated successfully'
              : 'Snacks tracked successfully',
        );
      } else {
        if (mounted) setState(() => _busy = false);
        final err = HealthVitalsController.instance.error;
        _toast(messenger, err.isNotEmpty ? err : 'Error saving snacks data');
      }
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      _toast(messenger, 'Error saving snacks data');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final snacksColor = Colors.pink.shade400;
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
                      color: snacksColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.cookie_rounded,
                      color: snacksColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    widget.vital != null ? 'Edit Snacks' : 'Snacks Tracking',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Keep track of your snack calories to stay mindful of your daily nutrition goal.',
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
                  hint: 'e.g. Mixed nuts or Greek yogurt',
                  icon: Icons.restaurant_rounded,
                  iconColor: snacksColor,
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
                  hint: 'e.g. 200',
                  icon: Icons.bolt_rounded,
                  iconColor: snacksColor,
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
                              ? 'Update Snacks'
                              : 'Save Snacks',
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
    final none = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      filled: true,
      fillColor:
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
      border: none,
      enabledBorder: none,
      focusedBorder: none,
      contentPadding: const EdgeInsets.all(16),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
    );
  }
}
