// Ported from AlloConnect lib/features/health_section/vitals/steps/steps_summary_screen.dart.
import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/steps/views/daily_steps_view.dart';
import 'package:allomom/features/my_health/vitals/steps/views/weekly_steps_view.dart';
import 'package:allomom/features/my_health/vitals/steps/views/monthly_steps_view.dart';

/// AlloConnect's "Steps Analysis" screen: Daily / Weekly / Monthly tabs.
/// The goal comes from Allomom's `HealthVitalsController.currentStepTarget`
/// (the `targets` row), so [goalSteps] is kept only for call-site parity.
class StepsSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;
  final int initialSteps;
  final int goalSteps;

  const StepsSummaryScreen({
    super.key,
    this.userId,
    this.initialSteps = 0,
    this.goalSteps = 10000,
  });

  @override
  State<StepsSummaryScreen> createState() => _StepsSummaryScreenState();
}

class _StepsSummaryScreenState extends State<StepsSummaryScreen> {
  int _selectedFilterIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];

  String get _userId {
    final id = widget.userId?.trim() ?? '';
    return id.isNotEmpty ? id : HealthVitalsController.instance.userId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDarkMode ? const Color(0xFF0A111F) : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Steps Analysis',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const VitalBabyBanner(),
              _buildFilterToggle(isDarkMode, textColor),
              const SizedBox(height: 24),
              GetBuilder<HealthVitalsController>(
                init: HealthVitalsController.instance,
                builder: (vitals) => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.05, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: _buildCurrentView(vitals.currentStepTarget),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterToggle(bool isDarkMode, Color textColor) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDarkMode
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.white)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected && !isDarkMode
                      ? [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  _filters[index],
                  style: TextStyle(
                    color: isSelected
                        ? textColor
                        : textColor.withValues(alpha: 0.5),
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentView(int target) {
    switch (_selectedFilterIndex) {
      case 0:
        return DailyStepsView(
            userId: _userId,
            goalSteps: target,
            key: ValueKey('daily-$target'));
      case 1:
        return WeeklyStepsView(
            userId: _userId,
            goalSteps: target,
            key: ValueKey('weekly-$target'));
      case 2:
        return MonthlyStepsView(
            userId: _userId,
            goalSteps: target,
            key: ValueKey('monthly-$target'));
      default:
        return const SizedBox.shrink();
    }
  }
}
