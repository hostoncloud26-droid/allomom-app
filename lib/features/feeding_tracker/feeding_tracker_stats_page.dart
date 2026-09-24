import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/my_health/widgets/vital_log_bottom_sheet.dart';

class FeedingTrackerStatsPage extends StatefulWidget {
  const FeedingTrackerStatsPage({super.key});

  @override
  State<FeedingTrackerStatsPage> createState() => _FeedingTrackerStatsPageState();
}

class _FeedingTrackerStatsPageState extends State<FeedingTrackerStatsPage> {
  AppPalette get _p => context.palette;

  int _selectedFilter = 0; // 0: Day, 1: Week, 2: Month

  String get _periodKey {
    switch (_selectedFilter) {
      case 0:
        return 'day';
      case 1:
        return 'week';
      case 2:
      default:
        return 'month';
    }
  }

  void _logFeed() async {
    final logged = await VitalLogBottomSheet.show(
      context,
      initialKey: 'feeding',
      lockKey: true,
    );
    if (logged == true) {
      setState(() {});
    }
  }

  List<Map<String, dynamic>> _getDisplayFeeds(List<dynamic> vitalsList) {
    if (vitalsList.isEmpty) return [];
    return vitalsList.map((v) {
      final isBottle = (v.data?['type']?.toString().toLowerCase().contains('bottle') ?? false) || v.unit == 'ml';
      final timeStr = DateFormat('hh:mm a').format(v.createdAt);
      final feedType = v.data?['type']?.toString() ?? (isBottle ? 'Bottle Feed' : 'Breastfeeding');
      final amount = v.value.toInt().toString();
      final unit = v.unit.isNotEmpty ? v.unit : (isBottle ? 'ml' : 'min');
      return {
        'time': timeStr,
        'type': feedType,
        'amount': amount,
        'unit': unit,
        'icon': isBottle ? Icons.local_drink_rounded : Icons.water_drop_rounded,
        'isBreastfeeding': !isBottle,
      };
    }).toList().reversed.toList();
  }

  void _showAllFeedsSheet(List<Map<String, dynamic>> feeds) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _p.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'All Feeds History',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
              ),
              const SizedBox(height: 16),
              if (feeds.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No feeds recorded yet.', style: TextStyle(color: _p.pick(Colors.grey, _p.textMuted))),
                  ),
                )
              else
                ...feeds.map((feed) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: _buildFeedRow(feed),
                    )),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HealthVitalsController.instance,
      builder: (context, _) {
        final vitals = HealthVitalsController.instance;
        final periodHistory = vitals.getHistoryForPeriod('feeding', _periodKey);
        final feeds = _getDisplayFeeds(periodHistory);

        final totalFeeds = periodHistory.isNotEmpty ? periodHistory.length : 0;
        final totalDurationMinutes = periodHistory.isNotEmpty
            ? periodHistory.where((v) => v.unit != 'ml').map((v) => v.value.toInt()).fold<int>(0, (a, b) => a + b)
            : 0;

        String periodTitle = "Today's feeds";
        String periodSubheader = DateFormat('dd MMM').format(DateTime.now());
        String totalSubLabel = 'feeds today';

        if (_selectedFilter == 1) {
          periodTitle = "This week's feeds";
          final start = DateTime.now().subtract(const Duration(days: 6));
          periodSubheader = '${DateFormat('dd MMM').format(start)} - Today';
          totalSubLabel = 'feeds this week';
        } else if (_selectedFilter == 2) {
          periodTitle = "This month's feeds";
          periodSubheader = DateFormat('MMMM yyyy').format(DateTime.now());
          totalSubLabel = 'feeds this month';
        }

        return Scaffold(
          backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
          body: SafeArea(
            child: Column(
              children: [
                // ─── TOP APP BAR ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.maybePop(context),
                        icon: Icon(
                          Icons.arrow_back,
                          color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                          size: 24,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Feeding Tracker',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                            ),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _logFeed,
                        icon: const Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
                        label: const Text(
                          'Log',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: _p.tint(const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── FIXED TOP: Baby Hero Banner, Top Summary Card & Filter Tabs ───
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                  child: BabyHeroBanner(
                    speechText:
                        "Week ${MainController.instance.currentGestationalWeek}, Amma!\nWe're growing together. Can you feel the kicks?",
                    bubblePosition: SpeechBubblePosition.topCenter,
                    height: 220,
                  ),
                ),

                // ─── TOP SUMMARY CARD ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const FeedingTrackerPage()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      decoration: BoxDecoration(
                        color: _p.card,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: _p.pick(Colors.black.withValues(alpha: 0.03), _p.shadow),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: _p.tint(const Color(0xFF8B5CF6), const Color(0xFFEDE9FE)),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_drink_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '$totalFeeds',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    totalSubLabel,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Total feeding time',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _p.pick(const Color(0xFF8C93A3), _p.textMuted),
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                totalDurationMinutes > 0 ? '$totalDurationMinutes min' : '${totalFeeds * 20} min',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: _p.pick(const Color(0xFF8C93A3), _p.textMuted),
                            size: 24,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── FILTER TABS (Day / Week / Month) ───
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _p.card,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: _p.pick(Colors.black.withValues(alpha: 0.02), _p.shadow),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _buildFilterTab(0, 'Day'),
                        _buildFilterTab(1, 'Week'),
                        _buildFilterTab(2, 'Month'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // ─── SCROLLABLE BODY (After the tab) ───
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // ─── FEEDS CARD ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _p.card,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: _p.pick(Colors.black.withValues(alpha: 0.03), _p.shadow),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  periodTitle,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                  ),
                                ),
                                Text(
                                  periodSubheader,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: _p.pick(const Color(0xFF8C93A3), _p.textMuted),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // List of Feeds
                            if (feeds.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.child_care_rounded, size: 36, color: _p.pick(Colors.grey.shade300, _p.textMuted)),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No feeds recorded for this period',
                                        style: TextStyle(fontSize: 13.5, color: _p.pick(Colors.grey.shade600, _p.textSecondary), fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else ...[
                              for (int i = 0; i < feeds.length; i++) ...[
                                _buildFeedRow(feeds[i]),
                                if (i < feeds.length - 1) const SizedBox(height: 14),
                              ],

                              const SizedBox(height: 18),

                              // View All Action
                              GestureDetector(
                                onTap: () => _showAllFeedsSheet(feeds),
                                child: const Text(
                                  'View all',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ─── MOTIVATIONAL MESSAGE CONTAINER ───
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        decoration: BoxDecoration(
                          color: _p.tint(const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.favorite_rounded,
                              color: Color(0xFF8B5CF6),
                              size: 24,
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                "You're doing a great job!\nKeep listening to your baby's needs.",
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);
  }

  Widget _buildFeedRow(Map<String, dynamic> feed) {
    final isBreastfeeding = feed['isBreastfeeding'] as bool;
    final icon = feed['icon'] as IconData;
    final time = feed['time'] as String;
    final type = feed['type'] as String;
    final amount = feed['amount'] as String;
    final unit = feed['unit'] as String;

    final iconBg = isBreastfeeding
        ? _p.tint(const Color(0xFF8B5CF6), const Color(0xFFEDE9FE))
        : _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFE4E6));
    final iconColor = isBreastfeeding ? const Color(0xFF8B5CF6) : const Color(0xFFFF4E6A);

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          time,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            type,
            style: TextStyle(
              fontSize: 14,
              color: _p.pick(const Color(0xFF374151), _p.textSecondary),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              amount,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
              ),
            ),
            const SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right_rounded,
          color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
          size: 20,
        ),
      ],
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? _p.tint(const Color(0xFF8B5CF6), const Color(0xFFEDE9FE))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF8B5CF6) : _p.pick(const Color(0xFF6B7280), _p.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
