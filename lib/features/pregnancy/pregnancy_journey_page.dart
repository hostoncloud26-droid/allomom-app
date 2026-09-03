import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/lab_reports_schedule_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class PregnancyJourneyPage extends StatefulWidget {
  const PregnancyJourneyPage({super.key});

  @override
  State<PregnancyJourneyPage> createState() => _PregnancyJourneyPageState();
}

class _PregnancyJourneyPageState extends State<PregnancyJourneyPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      UserSessionManager.instance.fetchAndSyncProfileFromApi();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserSessionManager.instance,
      builder: (context, _) {
        final session = UserSessionManager.instance;
        final gestationalWeek = session.currentGestationalWeek;
        final trimester = session.currentTrimester;
        final daysLeft = session.daysLeftUntilEdd;
        final eddFormatted = session.formattedEddDate;
        final progressFraction = session.pregnancyProgressFraction;
        final progressPercent = (progressFraction * 100).toInt();

        return Scaffold(
          backgroundColor: const Color(0xFFFBFBFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFFFBFBFC),
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF1E2024),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'My Pregnancy Journey',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.calendar_month_rounded,
                  color: Color(0xFFFF3B5C),
                  size: 22,
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AncSchedulePage()),
                  );
                },
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── BABY HERO CARD ───
                  BabyHeroBanner(
                    speechText: "Am $gestationalWeek weeks, Amma! 💕\nWe're growing so strong together.",
                    bubblePosition: SpeechBubblePosition.topCenter,
                    height: 270,
                    greetingText: "",
                  ),
                  const SizedBox(height: 18),

                  // ─── PREGNANCY INFO SECTION (EDD, DAYS LEFT, WEEK PROGRESS) ───
                  _buildPregnancyInfoCard(
                    context: context,
                    gestationalWeek: gestationalWeek,
                    trimester: trimester,
                    daysLeft: daysLeft,
                    eddFormatted: eddFormatted,
                    progressFraction: progressFraction,
                    progressPercent: progressPercent,
                  ),

                  const SizedBox(height: 16),

                  // ─── UPCOMING CARE & SCHEDULE SECTION CARD ───
                  _buildUpcomingScheduleCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── PREGNANCY INFO CARD (DYNAMIC & LIVE) ───────────────────
  Widget _buildPregnancyInfoCard({
    required BuildContext context,
    required int gestationalWeek,
    required String trimester,
    required int daysLeft,
    required String eddFormatted,
    required double progressFraction,
    required int progressPercent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.favorite_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 15,
                  ),
                  SizedBox(width: 5),
                  Text(
                    'PREGNANCY INFO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  trimester,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFF3B5C),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Week Title & Edit Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Week $gestationalWeek of 40',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PregnancyConfirmationPage()),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.edit_calendar_rounded, size: 12, color: Color(0xFF4B5563)),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Timeline',
                        style: GoogleFonts.poppins(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF4B5563),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Slim Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF8E95A5),
                    ),
                  ),
                  Text(
                    '$progressPercent%',
                    style: const TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: const Color(0xFFFFE6ED),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF3B5C)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3 Metric Stat Chips
          Row(
            children: [
              // EDD Chip
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFFFF0F4),
                  icon: Icons.event_available_rounded,
                  iconColor: const Color(0xFFFF4E6A),
                  value: eddFormatted,
                  label: 'Due Date',
                ),
              ),
              const SizedBox(width: 8),

              // Days Left Chip
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFEDF6FF),
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: const Color(0xFF3898EC),
                  value: '$daysLeft',
                  label: 'Days Left',
                ),
              ),
              const SizedBox(width: 8),

              // Current Week Chip
              Expanded(
                child: _buildInfoMetricChip(
                  bg: const Color(0xFFF3E8FF),
                  icon: Icons.child_care_rounded,
                  iconColor: const Color(0xFF8B5CF6),
                  value: 'W $gestationalWeek',
                  label: 'Week',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoMetricChip({
    required Color bg,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF8A90A0),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── UPCOMING SCHEDULE SECTION CARD ────────────────────────
  Widget _buildUpcomingScheduleCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0F1F5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    color: Color(0xFFFF3B5C),
                    size: 15,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'UPCOMING SCHEDULE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF3B5C),
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              Text(
                'Next 30 Days',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF8E95A5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Doctor Appointment Row
          _buildScheduleRow(
            icon: Icons.medical_services_rounded,
            iconBg: const Color(0xFFFFF0F4),
            iconColor: const Color(0xFFFF3B5C),
            title: 'Doctor Appointment',
            date: '12 Sep 2026 · 10:30 AM',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AncSchedulePage()),
              );
            },
          ),

          const Divider(color: Color(0xFFF3F4F6), height: 20, thickness: 1),

          // 2. Vaccination Row
          _buildScheduleRow(
            icon: Icons.vaccines_rounded,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Tetanus Toxoid (TT-2)',
            date: '18 Sep 2026',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VaccinationSchedulePage()),
              );
            },
          ),

          const Divider(color: Color(0xFFF3F4F6), height: 20, thickness: 1),

          // 3. Lab Report & Scan Row
          _buildScheduleRow(
            icon: Icons.science_rounded,
            iconBg: const Color(0xFFEDF6FF),
            iconColor: const Color(0xFF3898EC),
            title: 'Glucose (75g OGTT) & Hemoglobin',
            date: '25 Sep 2026 · 8:00 AM',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LabReportsSchedulePage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String date,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Color(0xFFBDC3CE),
            ),
          ],
        ),
      ),
    );
  }
}
