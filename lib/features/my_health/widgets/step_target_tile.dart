import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/vitals/steps/step_target_sheet.dart';

import 'nutrition/health_tile_parts.dart';

const Color _stepColor = Color(0xFF00E676);

/// AlloConnect's "Step Goal Tracker" tile: the daily step target, whether it
/// is custom or the default, and a Set Target button that opens Allomom's
/// step-target sheet (ported from AlloConnect).
///
/// The target is a setting rather than a day's reading, so [date] (today when
/// null) is accepted for parity with the other day tiles and does not change
/// what is shown.
class StepTargetTile extends StatefulWidget {
  final String? userId;

  /// Day being viewed. Defaults to today when omitted.
  final DateTime? date;

  const StepTargetTile({
    super.key,
    this.userId,
    this.date,
  });

  @override
  State<StepTargetTile> createState() => _StepTargetTileState();
}

class _StepTargetTileState extends State<StepTargetTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    duration: const Duration(seconds: 2),
    vsync: this,
  )..repeat(reverse: true);
  late final Animation<double> _pulseScale =
      Tween<double>(begin: 1.0, end: 1.04).animate(
    CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
  );

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _showSetTargetBottomSheet(BuildContext context) {
    showStepTargetSheet(
      context,
      userId: widget.userId ?? MainController.instance.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.palette.isDark;
    final textColor = tileTextColor(context);

    return AnimatedBuilder(
      animation: HealthVitalsController.instance,
      builder: (context, _) {
        final vitals = HealthVitalsController.instance;
        final currentTarget = vitals.currentStepTarget;
        final hasCustomVital = vitals.targetVital?.data?['stepTarget'] != null;

        return HealthTileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _stepColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Step Goal Tracker',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: hasCustomVital
                          ? _stepColor.withValues(alpha: 0.12)
                          : (isDarkMode
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      hasCustomVital ? 'CUSTOM' : 'DEFAULT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: hasCustomVital
                            ? _stepColor
                            : textColor.withValues(alpha: 0.4),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  ScaleTransition(
                    scale: _pulseScale,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _stepColor.withValues(alpha: 0.12),
                        border: Border.all(
                          color: _stepColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.insights_rounded,
                        color: _stepColor,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Target',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textColor.withValues(alpha: 0.5),
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$currentTarget ',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: textColor,
                                  ),
                                ),
                                TextSpan(
                                  text: 'steps',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: textColor.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showSetTargetBottomSheet(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _stepColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.edit_road_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Set Target',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
