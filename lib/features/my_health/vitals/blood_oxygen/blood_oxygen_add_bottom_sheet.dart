// Manual SpO₂ entry for Allomom. AlloConnect only records SpO₂ from its device,
// so this sheet mirrors AlloConnect's BloodPressureAddBottomSheet layout and
// uses the SpO₂ status bands from AlloConnect's DailyBloodOxygenView.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

/// Opens the manual SpO₂ entry sheet. Resolves to `true` when a reading was saved.
Future<bool?> showBloodOxygenAddSheet(
  BuildContext context, {
  String? userId,
  DateTime? createdAt,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) =>
        BloodOxygenAddBottomSheet(userId: userId, createdAt: createdAt),
  );
}

class BloodOxygenAddBottomSheet extends StatefulWidget {
  final String? userId;

  /// Timestamp for the reading; defaults to now.
  final DateTime? createdAt;

  const BloodOxygenAddBottomSheet({super.key, this.userId, this.createdAt});

  @override
  State<BloodOxygenAddBottomSheet> createState() =>
      _BloodOxygenAddBottomSheetState();
}

class _BloodOxygenAddBottomSheetState extends State<BloodOxygenAddBottomSheet> {
  final TextEditingController _spo2Controller = TextEditingController();
  final HealthVitalsController _vitalsController =
      HealthVitalsController.instance;

  bool _isSaving = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _spo2Controller.dispose();
    super.dispose();
  }

  double? get _value => double.tryParse(_spo2Controller.text.trim());

  Color _statusColor(double? v) {
    if (v == null) return const Color(0xFF00E5FF);
    if (v >= 95) return const Color(0xFF00E5FF);
    if (v >= 90) return const Color(0xFF4CAF50);
    if (v >= 85) return const Color(0xFFFFB300);
    return const Color(0xFFFF5252);
  }

  String _statusLabel(double? v) {
    if (v == null) return 'Normal range: 95-100%';
    if (v >= 95) return 'Optimal Concentration';
    if (v >= 90) return 'Normal Levels';
    if (v >= 85) return 'Mildly Low';
    return 'Critical Low';
  }

  Future<void> _saveEntry() async {
    final spo2 = _value;
    if (spo2 == null || spo2 < 50 || spo2 > 100) {
      setState(
        () => _errorMessage = 'Please enter a valid SpO₂ percentage (50-100%)',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = '';
    });

    final userId = widget.userId?.trim();
    final result = (userId != null && userId.isNotEmpty)
        ? await _vitalsController.addVitalEntry(
            key: 'blood_oxygen',
            value: spo2,
            unit: '%',
            createdAt: widget.createdAt ?? DateTime.now(),
            userId: userId,
            data: {'spo2': spo2},
          )
        : await _vitalsController.addBloodOxygenEntry(
            spo2Percent: spo2,
            createdAt: widget.createdAt ?? DateTime.now(),
          );

    if (!mounted) return;

    if (result != null) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop(true);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Blood Oxygen saved')),
      );
    } else {
      setState(() {
        _errorMessage = _vitalsController.error.isNotEmpty
            ? _vitalsController.error
            : 'Failed to save Blood Oxygen';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final value = _value;
    final color = _statusColor(value);
    final textColor = isDarkMode ? Colors.white : Colors.black87;

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
              'Add Blood Oxygen',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            const SizedBox(height: 24),

            // Status Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _statusLabel(value),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _buildInputField(
              label: 'SpO₂',
              controller: _spo2Controller,
              hint: '98',
              suffix: '%',
              onChanged: (_) => setState(() {}),
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
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Measurement',
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
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d{0,3}(\.\d?)?')),
          ],
          onChanged: onChanged,
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
