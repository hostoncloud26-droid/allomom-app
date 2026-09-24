// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/blood_pressure_add_bottom_sheet.dart.
// Saves through Allomom's HealthVitalsController.addBloodPressureEntry
// (key blood_pressure, value = systolic, data systolic/diastolic/pulse).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/models/blood_pressure_models.dart';

/// Opens the Add Blood Pressure sheet. Resolves to `true` when a reading was saved.
Future<bool?> showBloodPressureAddSheet(
  BuildContext context, {
  String? userId,
  DateTime? createdAt,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BloodPressureAddBottomSheet(
      userId: userId ?? HealthVitalsController.instance.userId,
      createdAt: createdAt,
    ),
  );
}

class BloodPressureAddBottomSheet extends StatefulWidget {
  final String userId;

  /// Timestamp for the reading; defaults to now.
  final DateTime? createdAt;

  const BloodPressureAddBottomSheet({
    super.key,
    required this.userId,
    this.createdAt,
  });

  @override
  State<BloodPressureAddBottomSheet> createState() =>
      _BloodPressureAddBottomSheetState();
}

class _BloodPressureAddBottomSheetState
    extends State<BloodPressureAddBottomSheet> {
  final TextEditingController _systolicController = TextEditingController();
  final TextEditingController _diastolicController = TextEditingController();
  final TextEditingController _pulseController = TextEditingController();
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;

  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  BPCategory get _currentCategory {
    final sys = int.tryParse(_systolicController.text);
    final dia = int.tryParse(_diastolicController.text);

    if (sys == null || dia == null) return BPCategory.normal;

    if (sys >= 180 || dia >= 120) return BPCategory.crisis;
    if (sys >= 140 || dia >= 90) return BPCategory.stage2;
    if (sys >= 130 || dia >= 80) return BPCategory.stage1;
    if (sys >= 120 && dia < 80) return BPCategory.elevated;
    return BPCategory.normal;
  }

  Future<void> _saveEntry() async {
    final sys = int.tryParse(_systolicController.text);
    final dia = int.tryParse(_diastolicController.text);
    final pulse = int.tryParse(_pulseController.text);

    if (sys == null || dia == null || sys <= 0 || dia <= 0) {
      setState(() => _errorMessage = 'Please enter valid BP values');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final result = await _vitalsController.addBloodPressureEntry(
      systolic: sys,
      diastolic: dia,
      pulse: pulse,
      createdAt: widget.createdAt ?? DateTime.now(),
      userId: widget.userId.trim().isNotEmpty ? widget.userId.trim() : null,
    );

    if (!mounted) return;

    if (result != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Blood Pressure saved')),
      );
    } else {
      setState(() {
        _errorMessage = _vitalsController.error.isNotEmpty
            ? _vitalsController.error
            : 'Failed to save Blood Pressure';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final category = _currentCategory;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1F2B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SafeArea(
        top: false,
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
              'Add Blood Pressure',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 24),

            // Category Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: category.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: category.color.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    category.label,
                    style: TextStyle(
                      color: category.color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    label: 'Systolic',
                    controller: _systolicController,
                    hint: '120',
                    suffix: 'mmHg',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildInputField(
                    label: 'Diastolic',
                    controller: _diastolicController,
                    hint: '80',
                    suffix: 'mmHg',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Pulse (Optional)',
              controller: _pulseController,
              hint: '72',
              suffix: 'bpm',
            ),
            const SizedBox(height: 32),

            // Error Message Display
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
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 18),
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
                  backgroundColor: category.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Save Measurement',
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
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
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
