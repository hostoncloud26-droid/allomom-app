// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/edit_blood_pressure_sheet.dart.
// NumberPicker (not in Allomom's pubspec) is replaced by a wheel picker with the
// same size/styling, and "Update" now saves through HealthVitalsController.updateVitalEntry.
import 'package:flutter/material.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/models/blood_pressure_models.dart';

/// Opens the Edit Blood Pressure sheet for an existing `blood_pressure` vital.
/// Resolves to `true` when the reading was updated.
Future<bool?> showEditBloodPressureSheet(
  BuildContext context, {
  required VitalsStreamResponse vital,
  String? userId,
  VoidCallback? onUpdate,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => EditBloodPressureSheet(
      vital: vital,
      userId: userId ?? HealthVitalsController.instance.userId,
      onUpdate: onUpdate ?? () {},
    ),
  );
}

class EditBloodPressureSheet extends StatefulWidget {
  final VitalsStreamResponse vital;
  final String userId;
  final VoidCallback onUpdate;

  const EditBloodPressureSheet({
    super.key,
    required this.vital,
    required this.userId,
    required this.onUpdate,
  });

  @override
  State<EditBloodPressureSheet> createState() => _EditBloodPressureSheetState();
}

class _EditBloodPressureSheetState extends State<EditBloodPressureSheet> {
  late int _systolic;
  late int _diastolic;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = BloodPressureEntry.fromVital(widget.vital);
    _systolic = entry.systolic.clamp(60, 240);
    _diastolic = entry.diastolic.clamp(40, 150);
  }

  Future<void> _update() async {
    setState(() => _isSaving = true);
    final data = <String, dynamic>{
      ...?widget.vital.data,
      'systolic': _systolic,
      'diastolic': _diastolic,
    };
    final result = await HealthVitalsController.instance.updateVitalEntry(
      vitalId: widget.vital.id,
      key: 'blood_pressure',
      value: _systolic.toDouble(),
      unit: widget.vital.unit.isNotEmpty ? widget.vital.unit : 'mmHg',
      createdAt: widget.vital.createdAt,
      userId: widget.userId.trim().isNotEmpty ? widget.userId.trim() : null,
      data: data,
    );
    if (!mounted) return;
    if (result != null) {
      widget.onUpdate();
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Blood Pressure updated')),
      );
    } else {
      setState(() => _isSaving = false);
      final error = HealthVitalsController.instance.error;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(
            error.isNotEmpty ? error : 'Failed to update Blood Pressure',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.brightness == Brightness.dark
        ? Colors.white
        : Colors.black87;

    final entry = BloodPressureEntry(
      timestamp: widget.vital.createdAt,
      systolic: _systolic,
      diastolic: _diastolic,
    );

    final category = entry.category;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Drag Handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(10),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Edit Blood Pressure",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Compact BP Display
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: category.color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.favorite, color: category.color, size: 24),
                          const SizedBox(width: 10),
                          Text(
                            '$_systolic/$_diastolic',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "mmHg",
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        category.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: category.color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      "Adjust values",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor.withValues(alpha: 0.6),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildPicker(
                          label: "Systolic",
                          value: _systolic,
                          min: 60,
                          max: 240,
                          color: Colors.pink,
                          onChanged: (v) => setState(() => _systolic = v),
                        ),
                        _buildPicker(
                          label: "Diastolic",
                          value: _diastolic,
                          min: 40,
                          max: 150,
                          color: Colors.blue,
                          onChanged: (v) => setState(() => _diastolic = v),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // Sticky Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _update,
                      child: _isSaving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text("Update"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPicker({
    required String label,
    required int value,
    required int min,
    required int max,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w700, color: color),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          height: 110,
          child: _NumberWheel(
            value: value,
            minValue: min,
            maxValue: max,
            onChanged: onChanged,
            itemHeight: 32,
            selectedColor: color,
          ),
        ),
      ],
    );
  }
}

/// Minimal stand-in for `numberpicker`'s NumberPicker (vertical integer wheel).
class _NumberWheel extends StatefulWidget {
  final int value;
  final int minValue;
  final int maxValue;
  final double itemHeight;
  final Color selectedColor;
  final ValueChanged<int> onChanged;

  const _NumberWheel({
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.itemHeight,
    required this.selectedColor,
    required this.onChanged,
  });

  @override
  State<_NumberWheel> createState() => _NumberWheelState();
}

class _NumberWheelState extends State<_NumberWheel> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: widget.value - widget.minValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
    return ListWheelScrollView.useDelegate(
      controller: _controller,
      itemExtent: widget.itemHeight,
      physics: const FixedExtentScrollPhysics(),
      diameterRatio: 100,
      onSelectedItemChanged: (i) => widget.onChanged(widget.minValue + i),
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: widget.maxValue - widget.minValue + 1,
        builder: (context, i) {
          final v = widget.minValue + i;
          final selected = v == widget.value;
          return Center(
            child: Text(
              '$v',
              style: selected
                  ? TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: widget.selectedColor,
                    )
                  : TextStyle(fontSize: 14, color: baseColor),
            ),
          );
        },
      ),
    );
  }
}
