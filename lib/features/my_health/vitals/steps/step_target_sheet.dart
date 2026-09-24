// Ported from AlloConnect's `_showSetTargetBottomSheet`
// (lib/features/health_section/vitals/steps/views/daily_steps_view.dart and
// step_target_tile.dart). Writes through Allomom's
// `HealthVitalsController.setStepTarget` (the `targets` row, `data.stepTarget`).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

const Color _stepColor = Color(0xFF00E676);

/// Opens AlloConnect's "Set Daily Step Goal" sheet. Resolves to the new target
/// when one was saved, or null when dismissed.
Future<int?> showStepTargetSheet(BuildContext context, {String? userId}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _StepTargetSheet(userId: userId),
  );
}

class _StepTargetSheet extends StatefulWidget {
  final String? userId;
  const _StepTargetSheet({this.userId});

  @override
  State<_StepTargetSheet> createState() => _StepTargetSheetState();
}

class _StepTargetSheetState extends State<_StepTargetSheet> {
  final TextEditingController _customController = TextEditingController();
  static const _stepOptions = [5000, 8000, 10000, 12000];

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _save(int target) {
    HealthVitalsController.instance.setStepTarget(
      target,
      userId: widget.userId,
    );
    Navigator.of(context).pop(target);
    Get.snackbar(
      'Goal Updated',
      'Daily step goal set to $target steps!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: _stepColor.withValues(alpha: 0.9),
      colorText: Colors.white,
      borderRadius: 16,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetSteps = HealthVitalsController.instance.currentStepTarget;
    final base = isDark ? Colors.white : Colors.black;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.08),
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
                    child: const Icon(
                      Icons.track_changes_rounded,
                      color: _stepColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set Daily Step Goal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Choose a goal to match your fitness plans',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: base.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Quick Goals',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: base.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.3,
                ),
                itemCount: _stepOptions.length,
                itemBuilder: (context, index) {
                  final option = _stepOptions[index];
                  final isSelected = targetSteps == option;

                  return InkWell(
                    onTap: () => _save(option),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _stepColor.withValues(alpha: 0.12)
                            : base.withValues(alpha: isDark ? 0.03 : 0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? _stepColor.withValues(alpha: 0.5)
                              : base.withValues(alpha: isDark ? 0.06 : 0.04),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '$option',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: isSelected
                                  ? _stepColor
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          Text(
                            'steps',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? _stepColor.withValues(alpha: 0.8)
                                  : base.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'Custom Goal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: base.withValues(alpha: 0.4),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: base.withValues(alpha: isDark ? 0.03 : 0.02),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: base.withValues(alpha: isDark ? 0.06 : 0.04),
                        ),
                      ),
                      child: TextField(
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter steps count',
                          hintStyle: TextStyle(
                            color: base.withValues(alpha: 0.3),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Icon(
                            Icons.directions_walk_rounded,
                            color: base.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final customVal = int.tryParse(
                        _customController.text.trim(),
                      );
                      if (customVal != null && customVal > 0) {
                        _save(customVal);
                      } else {
                        Get.snackbar(
                          'Invalid Input',
                          'Please enter a valid step count.',
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.red.shade400,
                          colorText: Colors.white,
                          borderRadius: 16,
                          margin: const EdgeInsets.all(16),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _stepColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
