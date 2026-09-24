// Add / edit hemoglobin, in the style of AlloConnect's
// lib/features/health_section/vitals/blood_pressure/blood_pressure_add_bottom_sheet.dart.
//
// Writes the same row Allomom's vital log sheet writes: key `hemoglobin`,
// value g/dL, unit `g/dL`, data {'hemoglobin': value}.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

import 'models/hemoglobin_models.dart';

/// Opens the hemoglobin entry sheet. Pass [existing] to edit (or delete) a
/// reading. Resolves to `true` when something was saved or deleted.
Future<bool?> showHemoglobinEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        HemoglobinEntrySheet(existing: existing, initialDate: initialDate),
  );
}

class HemoglobinEntrySheet extends StatefulWidget {
  final VitalsStreamResponse? existing;
  final DateTime? initialDate;

  const HemoglobinEntrySheet({super.key, this.existing, this.initialDate});

  @override
  State<HemoglobinEntrySheet> createState() => _HemoglobinEntrySheetState();
}

class _HemoglobinEntrySheetState extends State<HemoglobinEntrySheet> {
  final TextEditingController _valueController = TextEditingController();
  late DateTime _recordedAt;
  bool _isSaving = false;
  String _errorMessage = '';

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _valueController.text = existing.value.toStringAsFixed(1);
      _recordedAt = existing.createdAt;
    } else {
      final now = DateTime.now();
      final d = widget.initialDate;
      _recordedAt = d == null || DateUtils.isSameDay(d, now) || d.isAfter(now)
          ? now
          : DateTime(d.year, d.month, d.day, 9);
    }
  }

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_valueController.text.trim());

  HbCategory? get _currentCategory {
    final v = _value;
    if (v == null || v <= 0) return null;
    return hbCategoryFor(v);
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
    final hb = _value;
    if (hb == null || hb <= 0 || hb > 25) {
      setState(
        () => _errorMessage =
            'Please enter a realistic Hemoglobin value (e.g. 11.5)',
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
      result = await vitals.addHemoglobinEntry(
        hemoglobinGdl: hb,
        createdAt: _recordedAt,
      );
    } else {
      result = await vitals.updateVitalEntry(
        vitalId: existing.id,
        key: existing.key,
        value: hb,
        unit: 'g/dL',
        createdAt: _recordedAt,
        data: {...?existing.data, 'hemoglobin': hb},
      );
    }

    if (!mounted) return;
    if (result != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Hemoglobin updated' : 'Hemoglobin saved'),
        ),
      );
    } else {
      setState(() {
        _errorMessage = vitals.error.isNotEmpty
            ? vitals.error
            : 'Failed to save Hemoglobin';
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
        content: const Text('This hemoglobin reading will be removed.'),
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
        const SnackBar(content: Text('Hemoglobin reading deleted')),
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
    final accent = category?.color ?? kHemoglobinColor;

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
                _isEdit ? 'Edit Hemoglobin' : 'Add Hemoglobin',
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
                        category?.label ?? 'Enter your lab result',
                        style: TextStyle(
                          color: accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (category != null)
                      Text(
                        category.rangeText,
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
                label: 'Hemoglobin Level',
                controller: _valueController,
                hint: '12.0',
                suffix: 'g/dL',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              _buildDateTimeField(isDarkMode),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pregnancy target: above $kHbTarget g/dL · healthy '
                  '${kHbBandMin.toStringAsFixed(0)}–${kHbBandMax.toStringAsFixed(0)} g/dL',
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
