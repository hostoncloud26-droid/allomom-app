import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';

class LabReportsSchedulePage extends StatefulWidget {
  const LabReportsSchedulePage({super.key});

  @override
  State<LabReportsSchedulePage> createState() => _LabReportsSchedulePageState();
}

class _LabReportsSchedulePageState extends State<LabReportsSchedulePage> {
  final List<Map<String, dynamic>> _labReports = [
    {
      'name': 'Booking Blood Panel & Urine Analysis',
      'category': 'Routine First Trimester Screen',
      'week': 'Week 8',
      'date': '12 May 2026',
      'lab': 'SaveMom Diagnostics Lab',
      'status': 'Completed & Normal',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'items': [
        {'test': 'Complete Blood Count (CBC)', 'result': 'Hb: 11.2 g/dL', 'flag': 'Normal'},
        {'test': 'Blood Group & Rh Typing', 'result': 'B Positive (B+)', 'flag': 'Normal'},
        {'test': 'Infectious Screen (HIV, VDRL, HBsAg)', 'result': 'Non-Reactive', 'flag': 'Negative'},
        {'test': 'Thyroid Stimulating Hormone (TSH)', 'result': '1.85 mIU/L', 'flag': 'Normal (0.2-2.5)'},
      ],
      'doctorSummary': 'All baseline blood counts and viral markers clear. Normal thyroid function.'
    },
    {
      'name': 'NT Scan & Dual Marker Genetic Screen',
      'category': 'First Trimester Aneuploidy Screening',
      'week': 'Week 12',
      'date': '9 Jun 2026',
      'lab': 'Apollo Advanced Fetal Medicine',
      'status': 'Completed & Normal',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'items': [
        {'test': 'Nuchal Translucency (NT)', 'result': '1.2 mm', 'flag': 'Normal (< 2.5 mm)'},
        {'test': 'Nasal Bone', 'result': 'Present & Visualised', 'flag': 'Normal'},
        {'test': 'Free Beta hCG & PAPP-A', 'result': '1.05 MoM', 'flag': 'Low Risk (1:10,000)'},
      ],
      'doctorSummary': 'Low risk for chromosomal conditions (Trisomy 21, 18, 13). Reassuring scan.'
    },
    {
      'name': 'Level-II Targeted Anomaly Ultrasound (TIFFA)',
      'category': 'Fetal Morphology Evaluation',
      'week': 'Week 20',
      'date': '4 Aug 2026',
      'lab': 'Apollo Advanced Imaging Center',
      'status': 'Completed & Normal',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'items': [
        {'test': 'Fetal Anatomy Survey', 'result': 'All organs intact', 'flag': 'Normal'},
        {'test': 'Amniotic Fluid Index (AFI)', 'result': '14.2 cm', 'flag': 'Adequate'},
        {'test': 'Cervical Canal Length', 'result': '3.8 cm', 'flag': 'Normal (> 3.0 cm)'},
        {'test': 'Placental Location', 'result': 'Anterior Upper Segment', 'flag': 'Clear of OS'},
      ],
      'doctorSummary': 'Complete detailed anatomy normal. No structural anomalies detected.'
    },
    {
      'name': 'Gestational Diabetes 75g OGTT & CBC',
      'category': 'Metabolic & Iron Deficiency Screen',
      'week': 'Week 24',
      'date': '25 Sep 2026 · 8:00 AM Fasting',
      'lab': 'SaveMom Diagnostics Lab',
      'status': 'Next Upcoming',
      'statusColor': Color(0xFFFF3B5C),
      'statusBg': Color(0xFFFFF0F4),
      'items': [
        {'test': 'Fasting Blood Glucose', 'result': 'Pending', 'flag': 'Target < 92 mg/dL'},
        {'test': '1-Hour Glucose Post 75g', 'result': 'Pending', 'flag': 'Target < 180 mg/dL'},
        {'test': '2-Hour Glucose Post 75g', 'result': 'Pending', 'flag': 'Target < 153 mg/dL'},
        {'test': 'Repeat Hemoglobin (Hb)', 'result': 'Pending', 'flag': 'Target > 10.5 g/dL'},
      ],
      'doctorSummary': 'Fasting instructions: 8-10 hours overnight fast before blood draw.'
    },
    {
      'name': 'Third Trimester Fetal Doppler & AFI Scan',
      'category': 'Biophysical Growth Evaluation',
      'week': 'Week 32',
      'date': '7 Nov 2026',
      'lab': 'Apollo Advanced Imaging Center',
      'status': 'Scheduled',
      'statusColor': Color(0xFF3898EC),
      'statusBg': Color(0xFFEDF6FF),
      'items': [
        {'test': 'Estimated Fetal Weight (EFW)', 'result': 'Scheduled', 'flag': 'Growth Percentile'},
        {'test': 'Umbilical Artery PI / RI Doppler', 'result': 'Scheduled', 'flag': 'Vascular Resistance'},
        {'test': 'Fetal Presentation', 'result': 'Scheduled', 'flag': 'Cephalic Tracking'},
      ],
      'doctorSummary': 'Third-trimester growth milestone check.'
    },
    {
      'name': 'Pre-Delivery Blood Panel & GBS Swab',
      'category': 'Delivery Readiness Investigation',
      'week': 'Week 36',
      'date': '5 Dec 2026',
      'lab': 'SaveMom Diagnostics Lab',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'items': [
        {'test': 'Group B Streptococcus (GBS)', 'result': 'Scheduled', 'flag': 'Vagino-Rectal Swab'},
        {'test': 'Coagulation Profile (PT/INR, APTT)', 'result': 'Scheduled', 'flag': 'Labor Preparation'},
        {'test': 'Crossmatch & Save Serum', 'result': 'Scheduled', 'flag': 'Blood Bank Readiness'},
      ],
      'doctorSummary': 'Pre-labor safety protocols and labor room admission clearance.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E2024), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '9-Month Lab Reports & Scans',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E2024),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                children: [
                  // ─── BABY HERO BANNER AT TOP ───
                  const BabyHeroBanner(
                    speechText: "Am 23 weeks, Amma! 💕\nAll our test reports look great.",
                    bubblePosition: SpeechBubblePosition.topCenter,
                    height: 270,
                    greetingText: "",
                  ),
                  const SizedBox(height: 16),

                  // ─── LAB REPORTS LIST ───
                  for (final report in _labReports) ...[
                    _buildReportCard(report),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> report) {
    final isNext = report['status'] == 'Next Upcoming';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNext ? const Color(0xFF3898EC) : const Color(0xFFF0F1F5),
          width: isNext ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? const Color(0xFF3898EC).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row: Week Badge + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEDF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report['week'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3898EC),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: report['statusBg'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  report['status'],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: report['statusColor'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Report Title & Category
          Text(
            report['name'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            report['category'],
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8E95A5),
            ),
          ),
          const SizedBox(height: 6),

          // Date
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 14, color: Color(0xFF3898EC)),
              const SizedBox(width: 6),
              Text(
                report['date'],
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Itemized Test Results Table
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var item in report['items'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item['test']!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item['result']!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E2024),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Doctor interpretation
          Text(
            'Doctor Review: ${report['doctorSummary']}',
            style: const TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
