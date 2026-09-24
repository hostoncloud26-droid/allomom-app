import 'package:flutter/material.dart';
import 'package:allomom/features/my_health/vitals/common/vital_baby_banner.dart';
import 'package:get/get.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/edit_heart_rate_dialog.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/views/daily_view.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/views/weekly_view.dart';
import 'package:allomom/features/my_health/vitals/heart_rate/views/monthly_view.dart';

class HeartRateSummaryScreen extends StatefulWidget {
  const HeartRateSummaryScreen({super.key});

  @override
  State<HeartRateSummaryScreen> createState() => _HeartRateSummaryScreenState();
}

class _HeartRateSummaryScreenState extends State<HeartRateSummaryScreen> {
  final HealthVitalsController _controller = HealthVitalsController.instance;
  final RxInt _selectedTab = 0.obs;
  int _refreshTick = 0;

  Future<void> _openEntryDialog() async {
    final saved = await showHeartRateEntryDialog(context);
    if (saved == true) {
      await _refreshAnalysis();
    }
  }

  Future<void> _refreshAnalysis() async {
    await _controller.fetchLatestVitals();
    if (!mounted) {
      return;
    }
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
        onPressed: _openEntryDialog,
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(isDarkMode, textColor),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAnalysis,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  // Bottom inset keeps the last card clear of the FAB.
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  child: Column(
                    children: [
                      const VitalBabyBanner(),
                      // Tabs sit under the baby card and scroll with it, as on Sleep.
                      _buildFilterToggle(isDarkMode, textColor),
                      Obx(() {
                        final userId = _controller.userId.trim();

                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: _buildSelectedView(userId),
                        );
                      }),
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
      return const Column(
        children: [
          SizedBox(height: 100),
          Icon(Icons.person_off_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'User identity unknown',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text('Please try logging in again.'),
        ],
      );
    }

    switch (_selectedTab.value) {
      case 0:
        return HeartRateDailyView(
          key: ValueKey('daily-$_refreshTick'),
          userId: userId,
        );
      case 1:
        return HeartRateWeeklyView(
          key: ValueKey('weekly-$_refreshTick'),
          userId: userId,
        );
      case 2:
        return HeartRateMonthlyView(
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
            'Heart Rate Analysis',
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
    return Expanded(
      child: Obx(() {
        final isSelected = _selectedTab.value == index;
        return GestureDetector(
          onTap: () => _selectedTab.value = index,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isSelected
                  ? (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white)
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
                color: isSelected
                    ? textColor
                    : textColor.withValues(alpha: 0.4),
              ),
            ),
          ),
        );
      }),
    );
  }
}
