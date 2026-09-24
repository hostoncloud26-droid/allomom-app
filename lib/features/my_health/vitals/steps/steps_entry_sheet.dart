// Manual steps entry for Allomom. AlloConnect has no manual steps form (its
// steps come from Health Connect / Apple Health / AlloWear sync, which Allomom
// doesn't have), so this sheet takes the look of AlloConnect's "Set Daily Step
// Goal" sheet and writes the same row Allomom's vital log sheet does:
// key `steps`, value = the day's step count, unit `steps`,
// data {steps, distanceKm, calories} (via `addStepsEntry`).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

const Color _stepColor = Color(0xFF00E676);

/// Opens the steps entry sheet. Pass [existing] to edit (or delete) a saved
/// reading; otherwise a new reading is logged for [initialDate] (now when
/// null). Resolves to true when something was saved or deleted.
Future<bool?> showStepsEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? existing,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _StepsEntrySheet(existing: existing, initialDate: initialDate),
  );
}

class _StepsEntrySheet extends StatefulWidget {
  final VitalsStreamResponse? existing;
  final DateTime? initialDate;
  const _StepsEntrySheet({this.existing, this.initialDate});

  @override
  State<_StepsEntrySheet> createState() => _StepsEntrySheetState();
}

class _StepsEntrySheetState extends State<_StepsEntrySheet> {
  late final TextEditingController _controller;
  late DateTime _dateTime;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final existingSteps = existing == null
        ? null
        : ((existing.data?['steps'] as num?)?.toInt() ??
            existing.value.toInt());
    _controller = TextEditingController(text: existingSteps?.toString() ?? '');
    final now = DateTime.now();
    if (existing != null) {
      _dateTime = existing.createdAt;
    } else if (widget.initialDate != null &&
        !DateUtils.isSameDay(widget.initialDate, now)) {
      final d = widget.initialDate!;
      _dateTime = DateTime(d.year, d.month, d.day, 20);
    } else {
      _dateTime = now;
    }
    if (_dateTime.isAfter(now)) _dateTime = now;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _snack(String title, String message, Color color) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: color,
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _dateTime,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_dateTime),
    );
    if (!mounted) return;
    var picked = DateTime(date.year, date.month, date.day,
        time?.hour ?? _dateTime.hour, time?.minute ?? _dateTime.minute);
    if (picked.isAfter(now)) picked = now;
    setState(() => _dateTime = picked);
  }

  Future<void> _save() async {
    final steps = int.tryParse(_controller.text.trim());
    if (steps == null || steps <= 0 || steps > 100000) {
      _snack('Invalid Input', 'Please enter a valid step count.',
          Colors.red.shade400);
      return;
    }
    setState(() => _saving = true);
    final vitals = HealthVitalsController.instance;
    final existing = widget.existing;
    VitalsStreamResponse? saved;
    if (existing == null) {
      saved = await vitals.addStepsEntry(steps: steps, createdAt: _dateTime);
    } else {
      final data = Map<String, dynamic>.from(existing.data ?? const {})
        ..remove('hourly_data')
        ..remove('hourlyData')
        ..remove('distance')
        ..['steps'] = steps
        ..['distanceKm'] = (steps * 0.00078).toStringAsFixed(2)
        ..['calories'] = (steps * 0.04).toInt();
      saved = await vitals.updateVitalEntry(
        vitalId: existing.id,
        key: 'steps',
        value: steps.toDouble(),
        unit: 'steps',
        createdAt: _dateTime,
        data: data,
      );
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (saved == null) {
      _snack('Error', 'Could not save your steps. Please try again.',
          Colors.red.shade400);
      return;
    }
    Navigator.of(context).pop(true);
    _snack(_isEdit ? 'Steps Updated' : 'Steps Logged',
        '$steps steps saved!', _stepColor.withValues(alpha: 0.9));
  }

  Future<void> _delete() async {
    final existing = widget.existing;
    if (existing == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete entry?'),
        content: const Text('This steps reading will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _saving = true);
    await VitalsSqLiteService().deleteVital(existing.id);
    await HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
    if (!mounted) return;
    Navigator.of(context).pop(true);
    _snack('Entry Deleted', 'Steps reading removed.',
        Colors.red.withValues(alpha: 0.9));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? Colors.white : Colors.black;
    final textColor = isDark ? Colors.white : Colors.black87;
    final fieldBg = base.withValues(alpha: isDark ? 0.03 : 0.02);
    final fieldBorder = base.withValues(alpha: isDark ? 0.06 : 0.04);

    Widget label(String text) => Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: base.withValues(alpha: 0.4),
            letterSpacing: 0.5,
          ),
        );

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF161C2A) : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(36),
            topRight: Radius.circular(36),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: base.withValues(alpha: isDark ? 0.1 : 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _stepColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.directions_walk_rounded,
                        color: _stepColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isEdit ? 'Edit Steps' : 'Log Steps',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Enter your total steps for the day',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: base.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEdit)
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: _saving ? null : _delete,
                      icon: Icon(Icons.delete_outline_rounded,
                          color: Colors.red.shade400),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              label('Step Count'),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: fieldBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: fieldBorder),
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: !_isEdit,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter steps count',
                    hintStyle: TextStyle(color: base.withValues(alpha: 0.3)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.directions_walk_rounded,
                        color: base.withValues(alpha: 0.4)),
                    suffixText: 'steps',
                    suffixStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: base.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              label('Date & Time'),
              const SizedBox(height: 12),
              InkWell(
                onTap: _saving ? null : _pickDateTime,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: fieldBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: fieldBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 18, color: base.withValues(alpha: 0.4)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEE, d MMM yyyy • h:mm a')
                              .format(_dateTime),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                      ),
                      Icon(Icons.edit_calendar_rounded,
                          size: 18, color: _stepColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _stepColor,
                    disabledBackgroundColor:
                        _stepColor.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _isEdit ? 'Update' : 'Save',
                          style: const TextStyle(
                            fontSize: 14,
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
}
