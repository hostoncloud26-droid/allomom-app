// Ported from AlloConnect lib/features/health_section/vitals/blood_oxygen/blood_oxygen_summary_screen.dart.
// The Allowear device analysis sheet is dropped; a manual "Add SpO₂" flow is added instead.
import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/blood_oxygen_add_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/views/daily_blood_oxygen_view.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/views/weekly_blood_oxygen_view.dart';
import 'package:allomom/features/my_health/vitals/blood_oxygen/views/monthly_blood_oxygen_view.dart';

class BloodOxygenSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;

  const BloodOxygenSummaryScreen({super.key, this.userId});

  @override
  State<BloodOxygenSummaryScreen> createState() =>
      _BloodOxygenSummaryScreenState();
}

class _BloodOxygenSummaryScreenState extends State<BloodOxygenSummaryScreen> {
  int _selectedFilterIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];
  int _refreshTick = 0;

  static const Color _oxygenColor = Color(0xFF00E5FF);

  String get _userId {
    final id = widget.userId?.trim() ?? '';
    return id.isNotEmpty ? id : HealthVitalsController.instance.userId.trim();
  }

  Future<void> _openAddBottomSheet() async {
    final saved = await showBloodOxygenAddSheet(context, userId: _userId);
    if (saved == true) await _refresh();
  }

  Future<void> _refresh() async {
    await HealthVitalsController.instance.fetchLatestVitals(showLoading: false);
    if (!mounted) return;
    setState(() => _refreshTick++);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0A111F)
        : const Color(0xFFF8FAFF);
    final textColor = isDarkMode ? Colors.white : const Color(0xFF1A1C1E);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBottomSheet,
        backgroundColor: _oxygenColor,
        icon: const Icon(Icons.add_rounded, color: Color(0xFF0A111F)),
        label: const Text(
          'Add SpO₂',
          style: TextStyle(
            color: Color(0xFF0A111F),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Blood Oxygen Analysis',
          style: TextStyle(
            color: textColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _oxygenColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const VitalBabyBanner(),
                // Premium Filter Toggle
                _buildFilterToggle(isDarkMode, textColor),
                const SizedBox(height: 24),

                // Dynamic View Switcher
                AnimatedSwitcher(
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
                  child: _buildCurrentView(),
                ),

                const SizedBox(height: 100),
              ],
            ),
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
                            offset: const Offset(0, 4),
                          ),
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

  Widget _buildCurrentView() {
    final userId = _userId;
    if (userId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: Text('User unknown. Please login again.')),
      );
    }
    switch (_selectedFilterIndex) {
      case 0:
        return DailyBloodOxygenView(
          userId: userId,
          key: ValueKey('daily-$_refreshTick'),
        );
      case 1:
        return WeeklyBloodOxygenView(
          userId: userId,
          key: ValueKey('weekly-$_refreshTick'),
        );
      case 2:
        return MonthlyBloodOxygenView(
          userId: userId,
          key: ValueKey('monthly-$_refreshTick'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
