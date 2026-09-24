// Ported from AlloConnect
// lib/features/health_section/vitals/body_composition/body_composition_summary_screen.dart
// (`_openUpdateBottomSheet` / `_buildChangeInfo`), extracted so the weight &
// height entry flow can be opened from anywhere.
//
// Data shape matches Allomom's existing log sheet:
// - weight → `HealthVitalsController.addWeightEntry` (key `weight`, unit `kg`,
//   data {weight, height, bmi}).
// - height → `addVitalEntry(key: 'height', unit: 'cm')`.
import 'package:flutter/material.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';

/// Which body-composition metric the entry sheet edits.
enum BodyCompositionMetric { weight, height }

extension BodyCompositionMetricX on BodyCompositionMetric {
  String get key => this == BodyCompositionMetric.weight ? 'weight' : 'height';
  String get label =>
      this == BodyCompositionMetric.weight ? 'Weight' : 'Height';
  String get unit => this == BodyCompositionMetric.weight ? 'kg' : 'cm';
  Color get accentColor => this == BodyCompositionMetric.weight
      ? const Color(0xFFFF7A45)
      : const Color(0xFF2F80ED);
  double get minValue => this == BodyCompositionMetric.weight ? 20 : 50;
  double get maxValue => this == BodyCompositionMetric.weight ? 300 : 250;
}

/// Latest recorded height in cm, or 0 when none was ever logged.
///
/// Deliberately ignores `HealthVitalsController.heightValue`, which falls back
/// to a 162 cm placeholder.
double latestRecordedHeightCm() {
  final vitals = HealthVitalsController.instance;
  final fromHeight = vitals.heightVital?.value ?? 0;
  if (fromHeight > 0) return fromHeight;
  return 0;
}

/// Latest recorded weight in kg, or 0 when none was logged.
double latestRecordedWeightKg() {
  final vitals = HealthVitalsController.instance;
  return vitals.weightVital?.value ?? 0;
}

/// Opens AlloConnect's "Update Weight / Update Height" bottom sheet.
///
/// Returns `true` when a new entry was saved. [currentValue] defaults to the
/// latest recorded value; [currentHeightCm] (used to compute the BMI stored on
/// a weight entry) defaults to the latest recorded height.
Future<bool?> showBodyCompositionEntrySheet(
  BuildContext context, {
  required BodyCompositionMetric metric,
  double? currentValue,
  double? currentHeightCm,
  String? userId,
}) {
  final resolvedCurrent =
      currentValue ??
      (metric == BodyCompositionMetric.weight
          ? latestRecordedWeightKg()
          : latestRecordedHeightCm());
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _BodyCompositionEntrySheet(
      metric: metric,
      currentValue: resolvedCurrent,
      currentHeightCm: currentHeightCm ?? latestRecordedHeightCm(),
      userId: userId,
    ),
  );
}

class _BodyCompositionEntrySheet extends StatefulWidget {
  final BodyCompositionMetric metric;
  final double currentValue;
  final double currentHeightCm;
  final String? userId;

  const _BodyCompositionEntrySheet({
    required this.metric,
    required this.currentValue,
    required this.currentHeightCm,
    this.userId,
  });

  @override
  State<_BodyCompositionEntrySheet> createState() =>
      _BodyCompositionEntrySheetState();
}

class _BodyCompositionEntrySheetState
    extends State<_BodyCompositionEntrySheet> {
  late final TextEditingController _inputController;
  bool _isSaving = false;
  String _errorMessage = '';

  String get _label => widget.metric.label;
  String get _unit => widget.metric.unit;
  Color get _accentColor => widget.metric.accentColor;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(
      text: widget.currentValue > 0
          ? widget.currentValue.toStringAsFixed(1)
          : '',
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  double? get _parsedValue =>
      double.tryParse(_inputController.text.trim().replaceAll(',', '.'));

  _ValueChangeInfo _buildChangeInfo({
    required double currentValue,
    required double? newValue,
    required bool isDarkMode,
  }) {
    final label = _label;
    final unit = _unit;
    final neutralColor = isDarkMode ? Colors.white70 : Colors.black54;

    if (newValue == null) {
      return _ValueChangeInfo(
        message: 'Enter a valid $label value',
        color: neutralColor,
        icon: Icons.edit_note_rounded,
      );
    }

    if (newValue <= 0) {
      return _ValueChangeInfo(
        message: '$label should be greater than zero',
        color: const Color(0xFFFF8A65),
        icon: Icons.error_outline_rounded,
      );
    }

    if (currentValue <= 0) {
      return _ValueChangeInfo(
        message: 'This will be your first ${label.toLowerCase()} entry',
        color: const Color(0xFF42A5F5),
        icon: Icons.auto_awesome_rounded,
      );
    }

    final delta = newValue - currentValue;
    final absDelta = delta.abs();

    if (absDelta < 0.01) {
      return _ValueChangeInfo(
        message: 'No change in ${label.toLowerCase()}',
        color: neutralColor,
        icon: Icons.horizontal_rule_rounded,
      );
    }

    final isIncrease = delta > 0;
    final action = isIncrease ? 'increased' : 'decreased';
    final color = isIncrease
        ? const Color(0xFF00B66D)
        : const Color(0xFFFF8A65);

    return _ValueChangeInfo(
      message:
          'You have $action ${label.toLowerCase()} by ${absDelta.toStringAsFixed(1)} $unit',
      color: color,
      icon: isIncrease
          ? Icons.trending_up_rounded
          : Icons.trending_down_rounded,
    );
  }

  Future<void> _save() async {
    final newValue = _parsedValue;
    final metric = widget.metric;

    if (newValue == null || newValue <= 0) {
      setState(() => _errorMessage = 'Please enter a valid $_label');
      return;
    }
    if (newValue < metric.minValue || newValue > metric.maxValue) {
      setState(
        () => _errorMessage =
            'Please enter a $_label between ${metric.minValue.toStringAsFixed(0)} and ${metric.maxValue.toStringAsFixed(0)} $_unit',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final vitals = HealthVitalsController.instance;
    final now = DateTime.now();
    final targetUserId = (widget.userId?.trim().isNotEmpty ?? false)
        ? widget.userId!.trim()
        : MainController.instance.userId;

    final result = metric == BodyCompositionMetric.weight
        ? await vitals.addWeightEntry(
            weightKg: newValue,
            heightCm: widget.currentHeightCm > 0
                ? widget.currentHeightCm
                : null,
            createdAt: now,
          )
        : await vitals.addVitalEntry(
            key: 'height',
            value: newValue,
            unit: 'cm',
            createdAt: now,
            userId: targetUserId,
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
          : 'Failed to update $_label';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);
    final label = _label;
    final unit = _unit;
    final currentValue = widget.currentValue;
    final changeInfo = _buildChangeInfo(
      currentValue: currentValue,
      newValue: _parsedValue,
      isDarkMode: isDarkMode,
    );

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
                'Update $label',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                currentValue > 0
                    ? 'Current $label: ${currentValue.toStringAsFixed(1)} $unit'
                    : 'No previous $label found',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.65),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _inputController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: true,
                onChanged: (_) => setState(() => _errorMessage = ''),
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter $label in $unit',
                  hintStyle: TextStyle(
                    color: textColor.withValues(alpha: 0.25),
                    fontWeight: FontWeight.w600,
                  ),
                  suffixText: unit,
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
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: changeInfo.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: changeInfo.color.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(changeInfo.icon, color: changeInfo.color, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        changeInfo.message,
                        style: TextStyle(
                          color: changeInfo.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
                    backgroundColor: _accentColor,
                    disabledBackgroundColor: _accentColor.withValues(
                      alpha: 0.6,
                    ),
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
                      : Text(
                          'Update $label',
                          style: const TextStyle(
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

class _ValueChangeInfo {
  final String message;
  final Color color;
  final IconData icon;

  const _ValueChangeInfo({
    required this.message,
    required this.color,
    required this.icon,
  });
}
