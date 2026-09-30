import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';

// Views
import 'package:allomom/allowear/features/heart_rate/views/heart_rate_card.dart';
import 'package:allomom/allowear/features/blood_oxygen/views/blood_oxygen_card.dart';
import 'package:allomom/allowear/features/hrv/views/hrv_card.dart';

import 'package:allomom/allowear/features/health_monitoring/widgets/monitoring_config_section.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class HealthMonitoringPage extends StatelessWidget {
  HealthMonitoringPage({super.key});

  final AllowearController configController =
      allowear;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);
    final scaffoldBgColor =
        isDark ? const Color(0xFF121218) : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── Premium Header ─────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: scaffoldBgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                color: isDark ? Colors.white : Black800,
                size: 20,
              ),
              onPressed: () => Get.back(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
              title: Text(
                'Health Monitoring',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Black800,
                ),
              ),
            ),
          ),

          // ── Monitoring Configuration Panel ─────────────────────────
          SliverToBoxAdapter(
            child: MonitoringConfigSection(),
          ),

          // ── Divider ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Divider(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06),
                thickness: 1,
              ),
            ),
          ),

          // ── Vitals & Activity Section Header ───────────────────────
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'Vitals & Activity',
              Icons.monitor_heart_outlined,
              primaryColor,
              isDark,
            ),
          ),

          // ── Heart Rate Monitor ─────────────────────────────────────
          if (configController.supportsLive(VitalType.heartRate))
            const SliverToBoxAdapter(
              child: HeartRateCard(),
            ),

          // ── Blood Oxygen Monitor ───────────────────────────────────
          if (configController.supportsLive(VitalType.spo2))
            const SliverToBoxAdapter(
              child: BloodOxygenCard(),
            ),

          // ── HRV Monitor ────────────────────────────────────────────
          if (configController.supportsLive(VitalType.hrv))
            const SliverToBoxAdapter(
              child: HrvCard(),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Black800,
            ),
          ),
        ],
      ),
    );
  }
}
