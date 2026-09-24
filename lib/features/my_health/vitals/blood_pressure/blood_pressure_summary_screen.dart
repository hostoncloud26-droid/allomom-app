// Ported from AlloConnect lib/features/health_section/vitals/blood_pressure/blood_pressure_summary_screen.dart.
import 'package:flutter/material.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/blood_pressure_add_bottom_sheet.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/views/blood_pressure_daily_view.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/views/blood_pressure_weekly_view.dart';
import 'package:allomom/features/my_health/vitals/blood_pressure/views/blood_pressure_monthly_view.dart';

class BloodPressureSummaryScreen extends StatefulWidget {
  /// Defaults to the signed-in user.
  final String? userId;

  const BloodPressureSummaryScreen({super.key, this.userId});

  @override
  State<BloodPressureSummaryScreen> createState() =>
      _BloodPressureSummaryScreenState();
}

class _BloodPressureSummaryScreenState
    extends State<BloodPressureSummaryScreen> {
  final HealthVitalsController _controller = HealthVitalsController.instance;
  int _selectedTab = 0;
  int _refreshTick = 0;

  String get _userId {
    final id = widget.userId?.trim() ?? '';
    return id.isNotEmpty ? id : _controller.userId.trim();
  }

  Future<void> _openAddBottomSheet() async {
    final userId = _userId;
    if (userId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to identify user.')));
      return;
    }

    await showBloodPressureAddSheet(context, userId: userId);
    _refreshAnalysis();
  }

  Future<void> _refreshAnalysis() async {
    await _controller.fetchLatestVitals(showLoading: false);
    if (!mounted) return;
    setState(() {
      _refreshTick++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final backgroundColor = isDarkMode
        ? const Color(0xFF0F131A)
        : const Color(0xFFF8F9FE);

    return Scaffold(
      backgroundColor: backgroundColor,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddBottomSheet,
        backgroundColor: const Color(0xFFE91E63),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add BP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDarkMode, textColor),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAnalysis,
                color: const Color(0xFFE91E63),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  // Bottom inset keeps the last card clear of the FAB.
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  child: Column(
                    children: [
                      const VitalBabyBanner(
                        narrationKey: NarrationKeys.pgVitalsBp,
                      ),
                      // Tabs sit under the baby card and scroll with it, as on Sleep.
                      _buildFilterToggle(isDarkMode, textColor),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _buildSelectedView(_userId),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedView(String userId) {
    if (userId.isEmpty) {
      return const Center(child: Text('User unknown. Please login again.'));
    }

    switch (_selectedTab) {
      case 0:
        return BloodPressureDailyView(
          key: ValueKey('daily-$_refreshTick'),
          userId: userId,
        );
      case 1:
        return BloodPressureWeeklyView(
          key: ValueKey('weekly-$_refreshTick'),
          userId: userId,
        );
      case 2:
        return BloodPressureMonthlyView(
          key: ValueKey('monthly-$_refreshTick'),
          userId: userId,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildAppBar(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 20, 16),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: textColor,
              size: 20,
            ),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Blood Pressure Analysis',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggle(bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 24),
      child: Container(
        height: 52,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTab('Daily', 0, isDark, textColor),
            _buildTab('Weekly', 1, isDark, textColor),
            _buildTab('Monthly', 2, isDark, textColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index, bool isDark, Color textColor) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected && !isDark
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? textColor : textColor.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }
}
