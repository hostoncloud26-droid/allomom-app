// Add / edit blood glucose, in the style of AlloConnect's
// lib/features/health_section/vitals/blood_pressure/blood_pressure_add_bottom_sheet.dart.
//
// Writes the same row Allomom's vital log sheet writes: key `glucose`, value
// mg/dL, unit `mg/dL`, data {'glucose': value, 'mealPhase': phase}. Editing a
// legacy `blood_glucose` row keeps its key.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'models/blood_glucose_models.dart';

/// Opens the blood glucose entry sheet. Pass [existing] to edit (or delete) a
/// reading. Resolves to `true` when something was saved or deleted.
Future<bool?> showBloodGlucoseEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? existing,
  DateTime? initialDate,
  String? initialMealPhase,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BloodGlucoseEntrySheet(
      existing: existing,
      initialDate: initialDate,
      initialMealPhase: initialMealPhase,
    ),
  );
}

class BloodGlucoseEntrySheet extends StatefulWidget {
  final VitalsStreamResponse? existing;
  final DateTime? initialDate;

  /// 'fasting', 'pre_meal' or 'post_meal'. Defaults to 'fasting'.
  final String? initialMealPhase;

  const BloodGlucoseEntrySheet({
    super.key,
    this.existing,
    this.initialDate,
    this.initialMealPhase,
  });

  @override
  State<BloodGlucoseEntrySheet> createState() => _BloodGlucoseEntrySheetState();
}

class _BloodGlucoseEntrySheetState extends State<BloodGlucoseEntrySheet> {
  final TextEditingController _valueController = TextEditingController();
  late DateTime _recordedAt;
  String _mealPhase = 'fasting';
  bool _isSaving = false;
  String _errorMessage = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final v = existing.value;
      _valueController.text = v == v.roundToDouble()
          ? v.toStringAsFixed(0)
          : v.toStringAsFixed(1);
      _recordedAt = existing.createdAt;
      _mealPhase = _normalisePhase(existing.data?['mealPhase']?.toString());
    } else {
      _mealPhase = _normalisePhase(widget.initialMealPhase);
      final now = DateTime.now();
      final d = widget.initialDate;
      _recordedAt = d == null || DateUtils.isSameDay(d, now) || d.isAfter(now)
          ? now
          : DateTime(d.year, d.month, d.day, 9);
    }
  }

  static String _normalisePhase(String? phase) {
    final p = phase?.trim().toLowerCase() ?? '';
    if (kGlucoseMealPhases.contains(p)) return p;
    if (glucoseIsPostMeal(p)) return 'post_meal';
    if (p.contains('pre') || p.contains('before')) return 'pre_meal';
    return 'fasting';
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_valueController.text.trim());

  GlucoseCategory? get _currentCategory {
    final v = _value;
    if (v == null || v <= 0) return null;
    return glucoseCategoryFor(v, _mealPhase);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (!mounted) return;
    var picked = DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? _recordedAt.hour,
      time?.minute ?? _recordedAt.minute,
    );
    if (picked.isAfter(now)) picked = now;
    setState(() => _recordedAt = picked);
  }

  Future<void> _saveEntry() async {
    final g = _value;
    if (g == null || g <= 0 || g > 600) {
      setState(
        () => _errorMessage =
            'Please enter a valid Blood Glucose reading (e.g. 95)',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final vitals = HealthVitalsController.instance;
    final existing = widget.existing;
    final VitalsStreamResponse? result;
    if (existing == null) {
      result = await vitals.addBloodGlucoseEntry(
        mgDl: g,
        mealPhase: _mealPhase,
        createdAt: _recordedAt,
      );
    } else {
      result = await vitals.updateVitalEntry(
        vitalId: existing.id,
        key: existing.key,
        value: g,
        unit: 'mg/dL',
        createdAt: _recordedAt,
        data: {...?existing.data, 'glucose': g, 'mealPhase': _mealPhase},
      );
    }

    if (!mounted) return;
    if (result != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? 'Blood glucose updated' : 'Blood glucose saved',
          ),
        ),
      );
    } else {
      setState(() {
        _errorMessage = vitals.error.isNotEmpty
            ? vitals.error
            : 'Failed to save Blood Glucose';
        _isSaving = false;
      });
    }
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete reading?'),
        content: const Text('This blood glucose reading will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      await VitalsSqLiteService().deleteVital(existing.id);
      await HealthVitalsController.instance.fetchLatestVitals(
        showLoading: false,
      );
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Blood glucose reading deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to delete reading';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final category = _currentCategory;
    final accent = category?.color ?? kGlucoseColor;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1F2B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _isEdit ? 'Edit Blood Glucose' : 'Add Blood Glucose',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 24),

              // Category indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category?.label ?? 'Enter your reading',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (category != null)
                      Text(
                        glucosePhaseLabel(_mealPhase),
                        style: TextStyle(
                          color: accent.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildInputField(
                label: 'Blood Glucose',
                controller: _valueController,
                hint: '95',
                suffix: 'mg/dL',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildMealTiming(isDarkMode),
              const SizedBox(height: 16),
              _buildDateTimeField(isDarkMode),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pregnancy target: fasting / pre-meal below '
                  '${kGlucoseFastingTarget.toInt()} mg/dL · post-meal below '
                  '${kGlucosePostMealTarget.toInt()} mg/dL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              if (_errorMessage.isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    disabledBackgroundColor: accent.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEdit ? 'Update Measurement' : 'Save Measurement',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              if (_isEdit) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _isSaving ? null : _delete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 18,
                  ),
                  label: const Text(
                    'Delete Reading',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealTiming(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Timing',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final phase in kGlucoseMealPhases) ...[
              if (phase != kGlucoseMealPhases.first) const SizedBox(width: 8),
              Expanded(child: _buildPhaseChip(phase, isDarkMode)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseChip(String phase, bool isDarkMode) {
    final isSelected = _mealPhase == phase;
    return GestureDetector(
      onTap: _isSaving ? null : () => setState(() => _mealPhase = phase),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? kGlucoseColor.withValues(alpha: 0.12)
              : (isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kGlucoseColor : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Text(
          glucosePhaseLabel(phase),
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? kGlucoseColor
                : (isDarkMode ? Colors.white70 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildDateTimeField(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isSaving ? null : _pickDateTime,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 18,
                  color: isDarkMode ? Colors.white60 : Colors.black54,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    DateFormat('EEE, d MMM yyyy · h:mm a').format(_recordedAt),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.edit_calendar_rounded,
                  size: 18,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required String suffix,
    ValueChanged<String>? onChanged,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isDarkMode ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          autofocus: !_isEdit,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 18,
              color: isDarkMode
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.15),
            ),
            suffixText: suffix,
            filled: true,
            fillColor: isDarkMode
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
