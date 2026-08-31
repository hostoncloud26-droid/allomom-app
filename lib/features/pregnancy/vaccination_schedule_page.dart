import 'package:flutter/material.dart';
import 'package:allomom/components/baby_hero_banner.dart';

class VaccinationSchedulePage extends StatefulWidget {
  const VaccinationSchedulePage({super.key});

  @override
  State<VaccinationSchedulePage> createState() => _VaccinationSchedulePageState();
}

class _VaccinationSchedulePageState extends State<VaccinationSchedulePage> {
  final List<Map<String, dynamic>> _vaccines = [
    {
      'name': 'Tetanus Toxoid 1 (TT-1)',
      'dosage': 'Dose 1 of 2 (0.5 mL IM)',
      'recommendedWeek': 'Week 16 - 20 (Early Pregnancy)',
      'scheduledDate': '7 Jul 2026',
      'administeredBy': 'Nurse Anitha · Apollo Cradle',
      'status': 'Administered',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'purpose': 'Protects mother and newborn baby against maternal and neonatal tetanus infection.',
      'sideEffects': 'Mild localized soreness at injection site for 24 hours. Resolved normally.',
    },
    {
      'name': 'Tetanus Toxoid 2 (TT-2)',
      'dosage': 'Dose 2 of 2 (0.5 mL IM)',
      'recommendedWeek': 'Week 24 (4 weeks after TT-1)',
      'scheduledDate': '18 Sep 2026',
      'administeredBy': 'Apollo Cradle Maternity Center',
      'status': 'Next Upcoming',
      'statusColor': Color(0xFFFF3B5C),
      'statusBg': Color(0xFFFFF0F4),
      'purpose': 'Booster dose essential to ensure full maternal immunity and active placental antibody transfer.',
      'sideEffects': 'Mild local soreness. Paracetamol safe if needed per doctor guidance.',
    },
    {
      'name': 'Inactivated Influenza (Flu Shot)',
      'dosage': 'Single Seasonal Dose (0.5 mL IM)',
      'recommendedWeek': 'Week 20 - 28 (During Flu Season)',
      'scheduledDate': '22 Sep 2026',
      'administeredBy': 'City Maternity Clinic',
      'status': 'Scheduled',
      'statusColor': Color(0xFF3898EC),
      'statusBg': Color(0xFFEDF6FF),
      'purpose': 'Shields pregnant mother from severe influenza complications and protects baby for first 6 months of life.',
      'sideEffects': 'Low-grade fever or mild headache may occasionally occur.',
    },
    {
      'name': 'Tdap (Tetanus, Diphtheria & Pertussis)',
      'dosage': 'Single Dose Booster (0.5 mL IM)',
      'recommendedWeek': 'Week 27 - 36 (Ideal: Week 28-32)',
      'scheduledDate': '15 Oct 2026',
      'administeredBy': 'Apollo Cradle Maternity Hospital',
      'status': 'Scheduled',
      'statusColor': Color(0xFF8E95A5),
      'statusBg': Color(0xFFF6F7FA),
      'purpose': 'Crucial vaccine that gives baby maternal antibodies against Whooping Cough (Pertussis) before their own 2-month vaccine.',
      'sideEffects': 'Temporary upper arm soreness.',
    },
    {
      'name': 'Hepatitis B Booster (If Non-Immune)',
      'dosage': 'Standard Dose (Recombinant)',
      'recommendedWeek': 'Prior to Conception / Screened',
      'scheduledDate': 'Verified in Blood Screen',
      'administeredBy': 'Apollo Diagnostics',
      'status': 'Immune (HBsAg -ve)',
      'statusColor': Color(0xFF10B981),
      'statusBg': Color(0xFFD1FAE5),
      'purpose': 'Prevents vertical transmission of Hepatitis B virus from mother to infant during delivery.',
      'sideEffects': 'No additional dose required based on protective antibody titers.',
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
          'Pregnancy Vaccinations',
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
                    speechText: "Am 23 weeks, Amma! 💕\nStaying protected and strong.",
                    bubblePosition: SpeechBubblePosition.left,
                    height: 320,
                    greetingText: "",
                  ),
                  const SizedBox(height: 16),

                  // ─── VACCINES LIST ───
                  for (final vaccine in _vaccines) ...[
                    _buildVaccineCard(vaccine),
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

  Widget _buildVaccineCard(Map<String, dynamic> vaccine) {
    final isNext = vaccine['status'] == 'Next Upcoming';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isNext ? const Color(0xFF8B5CF6) : const Color(0xFFF0F1F5),
          width: isNext ? 1.8 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isNext
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name & Status Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vaccine['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vaccine['dosage'],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: vaccine['statusBg'],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  vaccine['status'],
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: vaccine['statusColor'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Recommended Timing & Scheduled Date
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: Color(0xFF8E95A5)),
                    const SizedBox(width: 6),
                    const Text(
                      'Timing: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                    ),
                    Expanded(
                      child: Text(
                        vaccine['recommendedWeek'],
                        style: const TextStyle(fontSize: 12, color: Color(0xFF1E2024), fontWeight: FontWeight.w700),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF8E95A5)),
                    const SizedBox(width: 6),
                    const Text(
                      'Date: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                    ),
                    Text(
                      vaccine['scheduledDate'],
                      style: const TextStyle(fontSize: 12, color: Color(0xFF1E2024), fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Purpose / Protection
          Text(
            vaccine['purpose'],
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF4B5563),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
