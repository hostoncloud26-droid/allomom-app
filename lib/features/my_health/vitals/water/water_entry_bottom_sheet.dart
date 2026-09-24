import 'package:flutter/material.dart';

import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/overview_section/nutrition/nutrition_day_data.dart';
import 'package:allomom/models/vitals_stream_model.dart';
import 'package:allomom/services/sq_lite/services/vitals_sqlite_service.dart';

/// Millilitres a `water` row stands for.
///
/// Allomom stores water as glasses of [kGlassMl] ml in the value (increments,
/// negative to undo); rows written by this sheet also keep the exact
/// amount in `data['ml']`.
double waterRowMl(VitalsStreamResponse v) {
  final ml = v.data?['ml'];
  if (ml is num) return v.value < 0 ? -ml.abs().toDouble() : ml.toDouble();
  final parsed = double.tryParse(ml?.toString() ?? '');
  if (parsed != null) return v.value < 0 ? -parsed.abs() : parsed;
  return v.value * kGlassMl;
}

/// Opens AlloConnect's water entry sheet. Pass [vital] to edit an existing
/// row. Resolves to true when something was saved.
Future<bool?> showWaterEntrySheet(
  BuildContext context, {
  VitalsStreamResponse? vital,
  String? userId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WaterEntryBottomSheet(userId: userId, vital: vital),
  );
}

class WaterEntryBottomSheet extends StatefulWidget {
  final String? userId;
  final VitalsStreamResponse? vital;

  const WaterEntryBottomSheet({super.key, this.userId, this.vital});

  @override
  State<WaterEntryBottomSheet> createState() => _WaterEntryBottomSheetState();
}

class _WaterEntryBottomSheetState extends State<WaterEntryBottomSheet> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  int _selectedPreset = 250;
  bool _saving = false;

  final List<int> _presets = [100, 250, 500, 750];

  @override
  void initState() {
    super.initState();
    final vital = widget.vital;
    if (vital != null) {
      final val = waterRowMl(vital).abs().round();
      _amountController.text = val.toString();
      _selectedPreset = _presets.contains(val) ? val : -1; // -1: custom
    } else {
      _amountController.text = '250';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _toast(String message) {
    ScaffoldMessenger.maybeOf(
      context,
    )?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _saveWaterData() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      _toast('Please enter a valid amount of water');
      return;
    }

    setState(() => _saving = true);
    try {
      final existing = widget.vital;
      // Glasses in the value so every existing reader keeps summing glasses;
      // the exact ml rides along in data.
      final glasses = double.parse((amount / kGlassMl).toStringAsFixed(2));
      final userId = widget.userId?.trim().isNotEmpty == true
          ? widget.userId!.trim()
          : MainController.instance.userId;

      final result = await HealthVitalsController.instance.addVitalEntry(
        key: 'water',
        value: glasses,
        unit: 'glasses',
        createdAt: existing?.createdAt ?? DateTime.now(),
        userId: userId,
        data: {
          'details': existing != null
              ? 'Water intake (Edited)'
              : 'Water intake',
          'type': 'water',
          'ml': amount.round(),
          'count': glasses,
          'count_unit': 'glasses',
        },
      );

      if (result != null && existing != null) {
        // No in-place update in Allomom: the edit is re-logged at the
        // original time, then the old row is soft-deleted (which syncs).
        await VitalsSqLiteService().deleteVital(existing.id);
        await HealthVitalsController.instance.fetchLatestVitals(
          showLoading: false,
        );
      }

      if (!mounted) return;
      if (result != null) {
        _toast(
          existing != null
              ? 'Water entry updated successfully'
              : 'Water intake logged successfully',
        );
        Navigator.of(context).pop(true);
      } else {
        _toast(
          HealthVitalsController.instance.error.isNotEmpty
              ? HealthVitalsController.instance.error
              : 'Error saving water entry',
        );
      }
    } catch (e) {
      if (mounted) _toast('Error saving water entry');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final waterColor = Colors.cyan.shade600;

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
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: waterColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.water_drop_rounded,
                        color: waterColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      widget.vital != null
                          ? 'Edit Water Intake'
                          : 'Log Water Intake',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Tracking daily water intake helps you maintain cellular hydration, support digestion, and regulate body temperature.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                // Presets Choice
                Text(
                  'Select Preset',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: _presets.map((preset) {
                    final isSelected = _selectedPreset == preset;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedPreset = preset;
                            _amountController.text = preset.toString();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? waterColor
                                : (isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : Colors.grey.shade100),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? waterColor
                                  : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                preset <= 150
                                    ? Icons.local_cafe_rounded
                                    : preset <= 300
                                    ? Icons.local_drink_rounded
                                    : Icons.wine_bar_rounded,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700),
                                size: 20,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$preset ml',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? Colors.white70
                                            : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Custom amount input
                Text(
                  'Custom Amount (ml)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  onChanged: (value) {
                    final parsed = int.tryParse(value);
                    setState(() {
                      _selectedPreset =
                          (parsed != null && _presets.contains(parsed))
                          ? parsed
                          : -1;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'e.g. 350',
                    hintStyle: TextStyle(
                      color: isDark
                          ? Colors.grey.shade600
                          : Colors.grey.shade400,
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
                      Icons.opacity_rounded,
                      color: waterColor,
                      size: 20,
                    ),
                    suffixText: 'ml',
                    suffixStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: waterColor,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter water amount';
                    }
                    final parsed = double.tryParse(value);
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _saveWaterData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      disabledBackgroundColor: theme.primaryColor.withValues(
                        alpha: 0.6,
                      ),
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
                            widget.vital != null
                                ? 'Update Intake'
                                : 'Log Intake',
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
      ),
    );
  }
}
