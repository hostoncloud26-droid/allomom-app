import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';

class AncSchedulePage extends StatefulWidget {
  const AncSchedulePage({super.key});

  @override
  State<AncSchedulePage> createState() => _AncSchedulePageState();
}

class _AncSchedulePageState extends State<AncSchedulePage> {
  int _selectedTrimesterFilter = 0; // 0: All, 1: T1, 2: T2, 3: T3

  final List<Map<String, dynamic>> _ancVisits = [
    {
      'trimester': 1,
      'week': 'Week 8',
      'title': 'First Prenatal Booking Visit',
      'date': '12 May 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'highlights': ['Pregnancy confirmation & dating scan', 'Baseline BP (116/74) & Weight (62.8 kg)', 'Started Folic Acid 5mg & Prenatal vitamins'],
      'notes': 'Healthy intrauterine single gestation. CRL corresponds to 8 weeks 2 days. Heartbeat 152 bpm.'
    },
    {
      'trimester': 1,
      'week': 'Week 12',
      'title': 'First Trimester NT Scan & Screen',
      'date': '9 Jun 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'highlights': ['Nuchal Translucency (NT: 1.2mm - Normal)', 'Double Marker blood test review', 'Blood pressure: 118/76 mmHg'],
      'notes': 'Normal fetal anatomy for gestational age. Low risk for aneuploidies.'
    },
    {
      'trimester': 2,
      'week': 'Week 16',
      'title': 'Early Mid-Trimester Evaluation',
      'date': '7 Jul 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'highlights': ['Fetal Doppler Heart Rate: 146 bpm', 'Maternal Weight: 64.2 kg', 'Prescribed Calcium & Iron supplements'],
      'notes': 'Uterine fundus palpable midway between symphysis pubis and umbilicus. Normal progress.'
    },
    {
      'trimester': 2,
      'week': 'Week 20',
      'title': 'Targeted Anomaly Scan (TIFFA)',
      'date': '4 Aug 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Diagnostic Center',
      'status': 'Completed',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'highlights': ['Detailed fetal organ survey normal', 'Cervical length: 3.8 cm (Normal)', 'Placenta: Anterior, Upper segment'],
      'notes': 'All four chambers of fetal heart visualised clearly. Normal spine, brain, kidneys, and extremities.'
    },
    {
      'trimester': 2,
      'week': 'Week 24',
      'title': 'Upcoming Routine ANC Visit',
      'date': '12 Sep 2026 · 10:30 AM',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Next Upcoming',
      'statusColor': Color(0xFFFF3B5C),
      'statusBg': Color(0xFFFFF0F4),
      'highlights': ['Gestational Diabetes 75g OGTT screening', 'Repeat Hemoglobin & Urine protein test', 'Fundal height & fetal kick counseling'],
      'notes': 'Please fast for 8-10 hours prior to the morning appointment for accurate blood sugar evaluation.'
    },
    {
      'trimester': 3,
      'week': 'Week 28',
      'title': 'Third Trimester Kickoff Checkup',
      'date': '10 Oct 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF3898EC),
      'statusBg': Color(0xFFEDF6FF),
      'highlights': ['Daily fetal kick count recording', 'Iron-deficiency anemia monitoring', 'Pre-eclampsia symptom review'],
      'notes': 'Transition to fortnightly antenatal visits starting from Week 28.'
    },
    {
      'trimester': 3,
      'week': 'Week 32',
      'title': 'Fetal Growth & Doppler Ultrasound',
      'date': '7 Nov 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'highlights': ['Estimated Fetal Weight (EFW)', 'Amniotic Fluid Index (AFI)', 'Umbilical artery Doppler velocimetry'],
      'notes': 'Assessing fetal growth trajectory and placental function.'
    },
    {
      'trimester': 3,
      'week': 'Week 36',
      'title': 'Term Preparation & GBS Swab',
      'date': '5 Dec 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'highlights': ['Group B Streptococcus (GBS) screening', 'Fetal presentation (Cephalic / Breech)', 'Hospital bag & birth plan alignment'],
      'notes': 'Transitioning to weekly antenatal visits until delivery.'
    },
    {
      'trimester': 3,
      'week': 'Week 38',
      'title': 'Weekly Term Clinical Assessment',
      'date': '19 Dec 2026',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'highlights': ['Non-Stress Test (NST / CTG)', 'Cervical readiness / Bishop score assessment', 'Labor signs & emergency contact checklist'],
      'notes': 'Monitoring for early spontaneous labor signs or rupture of membranes.'
    },
    {
      'trimester': 3,
      'week': 'Week 40',
      'title': 'Due Date & Final Delivery Assessment',
      'date': '28 Feb 2027',
      'doctor': 'Dr. Shalini Sharma · OB/GYN',
      'location': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'highlights': ['Biophysical Profile (BPP) score', 'Delivery suite admission readiness', 'Post-dates management strategy'],
      'notes': 'Welcome day! Final consultation before welcoming baby into the world.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredVisits = _ancVisits.where((v) {
      if (_selectedTrimesterFilter == 0) return true;
      return v['trimester'] == _selectedTrimesterFilter;
    }).toList();

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
          '9-Month ANC Schedule',
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
                    speechText: "Am 23 weeks, Amma! 💕\nLet's check our doctor visits.",
                    bubblePosition: SpeechBubblePosition.topCenter,
                    height: 270,
                    greetingText: "",
                  ),
                  const SizedBox(height: 16),

                  // ─── TRIMESTER FILTER CHIPS ───
                  Row(
                    children: [
                      _buildFilterTab(0, 'All (10)'),
                      const SizedBox(width: 8),
                      _buildFilterTab(1, 'Tri 1'),
                      const SizedBox(width: 8),
                      _buildFilterTab(2, 'Tri 2'),
                      const SizedBox(width: 8),
                      _buildFilterTab(3, 'Tri 3'),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ─── VISITS TIMELINE ───
                  for (final visit in filteredVisits) ...[
                    _buildVisitCard(visit),
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

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedTrimesterFilter == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTrimesterFilter = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF3B5C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFFFF3B5C) : const Color(0xFFE5E7EB),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF3B5C).withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisitCard(Map<String, dynamic> visit) {
    final isNext = visit['status'] == 'Next Upcoming';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNext ? const Color(0xFFFF3B5C) : const Color(0xFFF0F1F5),
          width: isNext ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? const Color(0xFFFF3B5C).withValues(alpha: 0.08)
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
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  visit['week'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF3B5C),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: visit['statusBg'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (visit['status'] == 'Completed')
                      const Icon(Icons.check_circle_rounded, size: 13, color: Color(0xFF10B981)),
                    if (visit['status'] == 'Next Upcoming')
                      const Icon(Icons.alarm_rounded, size: 13, color: Color(0xFFFF3B5C)),
                    if (visit['status'] == 'Scheduled')
                      const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF6B7280)),
                    const SizedBox(width: 4),
                    Text(
                      visit['status'],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: visit['statusColor'],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Visit Title
          Text(
            visit['title'],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 4),

          // Date & Time
          Row(
            children: [
              const Icon(Icons.event_rounded, size: 14, color: Color(0xFFFF3B5C)),
              const SizedBox(width: 6),
              Text(
                visit['date'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Key Highlights
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Checkup Checklist & Key Milestones:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
                const SizedBox(height: 6),
                for (String hl in visit['highlights'])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ', style: TextStyle(color: Color(0xFFFF3B5C), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            hl,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Clinical Note
          Text(
            'Doctor Advice: ${visit['notes']}',
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
