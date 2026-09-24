// Stress entry sheet for the ported AlloConnect Stress Analysis screen.
//
// AlloConnect has no manual stress entry (stress comes from the wearable), so
// this sheet reuses the look of AlloConnect's body-composition "Update" sheet
// and the stress bands / colours of its StressSummaryScreen.
//
// Data shape matches Allomom's existing log sheet:
// `HealthVitalsController.addStressEntry` → key `stress`, unit `score`,
// value 1–100, data {stressScore}.
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

/// AlloConnect stress colour for a 0–100 score.
Color stressColorFor(int stress) {
  if (stress <= 0) return Colors.blueGrey.shade400;
  if (stress <= 15) return const Color(0xFF10B981); // calm
  if (stress <= 30) return const Color(0xFF84CC16); // relaxed
  if (stress <= 50) return const Color(0xFF0EA5E9); // normal
  if (stress <= 70) return const Color(0xFFF59E0B); // slightly tense
  if (stress <= 85) return const Color(0xFFF97316); // tense
  return const Color(0xFFEF4444); // overwhelmed
}

/// AlloConnect stress label for a 0–100 score.
String stressLabelFor(int stress) {
  if (stress <= 0) return 'No Data';
  if (stress <= 15) return 'Calm';
  if (stress <= 30) return 'Relaxed';
  if (stress <= 50) return 'Normal';
  if (stress <= 70) return 'Slightly tense';
  if (stress <= 85) return 'Tense';
  return 'Overwhelmed';
}

/// Opens the stress log sheet. Returns `true` when an entry was saved.
Future<bool?> showStressEntrySheet(
  BuildContext context, {
  int? initialValue,
  DateTime? initialDate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        _StressEntrySheet(initialValue: initialValue, initialDate: initialDate),
  );
}

class _StressEntrySheet extends StatefulWidget {
  final int? initialValue;
  final DateTime? initialDate;

  const _StressEntrySheet({this.initialValue, this.initialDate});

  @override
  State<_StressEntrySheet> createState() => _StressEntrySheetState();
}

class _StressEntrySheetState extends State<_StressEntrySheet> {
  late final TextEditingController _inputController;
  late DateTime _recordedAt;
  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    final initial = (widget.initialValue ?? 25).clamp(1, 100);
    _inputController = TextEditingController(text: '$initial');
    final now = DateTime.now();
    final date = widget.initialDate;
    _recordedAt = date == null || DateUtils.isSameDay(date, now)
        ? now
        : DateTime(date.year, date.month, date.day, 12);
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  int? get _parsed => int.tryParse(_inputController.text.trim());

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: now.subtract(const Duration(days: 365)),
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

  Future<void> _save() async {
    final value = _parsed;
    if (value == null || value < 1 || value > 100) {
      setState(
        () => _errorMessage = 'Please enter a stress score between 1 and 100',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final vitals = HealthVitalsController.instance;
    final result = await vitals.addStressEntry(
      stressScore: value,
      createdAt: _recordedAt,
    );

    if (!mounted) return;
    if (result != null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _errorMessage = vitals.error.isNotEmpty
          ? vitals.error
          : 'Failed to save stress score';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final score = (_parsed ?? 0).clamp(0, 100);
    final color = stressColorFor(score);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF151D2A) : Colors.white,
          borderRadius: BorderRadius.circular(28),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Log Stress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rate how stressed you feel on a 1-100 scale.',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inputController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() => _errorMessage = ''),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter stress score',
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.25),
                    fontWeight: FontWeight.w600,
                  ),
                  suffixText: '/100',
                  suffixStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w700,
                  ),
                  filled: true,
                  fillColor: isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: color,
                  thumbColor: color,
                  inactiveTrackColor: color.withValues(alpha: 0.18),
                  overlayColor: color.withValues(alpha: 0.12),
                ),
                child: Slider(
                  value: score.clamp(1, 100).toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  onChanged: (v) => setState(() {
                    _inputController.text = v.round().toString();
                    _errorMessage = '';
                  }),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.self_improvement_rounded,
                      color: color,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        score > 0
                            ? '${stressLabelFor(score)} · $score/100'
                            : 'Enter a valid stress score',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: isDarkMode
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _pickDateTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule_rounded,
                          size: 16,
                          color: textColor.withValues(alpha: 0.55),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(_recordedAt),
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.edit_rounded,
                          size: 14,
                          color: textColor.withValues(alpha: 0.45),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0EA5E9),
                    disabledBackgroundColor: const Color(
                      0xFF0EA5E9,
                    ).withValues(alpha: 0.6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Stress Score',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
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
