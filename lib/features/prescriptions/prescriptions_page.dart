import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PrescriptionsPage extends StatefulWidget {
  const PrescriptionsPage({super.key});

  @override
  State<PrescriptionsPage> createState() => _PrescriptionsPageState();
}

class _PrescriptionsPageState extends State<PrescriptionsPage> {
  bool _isActiveTab = true;

  // Medicine items state
  final List<Map<String, dynamic>> _todayMedicines = [
    {
      'name': 'Iron + Folic Acid',
      'instruction': '1 tablet • After lunch • Till Aug 30',
      'time': '8:00 PM',
      'timeColor': const Color(0xFFFF4E6A),
      'iconBg': const Color(0xFFFFF0F3),
      'iconColor': const Color(0xFFFF4E6A),
      'iconType': 'pill',
      'isCompleted': false,
    },
    {
      'name': 'Calcium',
      'instruction': '1 tablet • After dinner • Till Aug 30',
      'time': '9:00 PM',
      'timeColor': const Color(0xFF3898EC),
      'iconBg': const Color(0xFFEBF4FF),
      'iconColor': const Color(0xFF3898EC),
      'iconType': 'bottle',
      'isCompleted': true,
    },
  ];

  final List<Map<String, dynamic>> _tomorrowMedicines = [
    {
      'name': 'Vitamin D3',
      'instruction': '1 tablet • After breakfast',
      'time': '8:00 AM',
      'timeColor': const Color(0xFFF59E0B),
      'iconBg': const Color(0xFFFFF7ED),
      'iconColor': const Color(0xFFF59E0B),
      'iconType': 'pill',
      'isCompleted': false,
    },
  ];

  final List<Map<String, dynamic>> _completedMedicines = [
    {
      'name': 'Folic Acid 5mg',
      'instruction': '1 tablet daily • 1st Trimester',
      'time': 'Completed Jul 15',
      'timeColor': const Color(0xFF10B981),
      'iconBg': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'iconType': 'pill',
      'isCompleted': true,
    },
    {
      'name': 'Progesterone',
      'instruction': '1 capsule at night • 1st Trimester',
      'time': 'Completed Jun 30',
      'timeColor': const Color(0xFF10B981),
      'iconBg': const Color(0xFFECFDF5),
      'iconColor': const Color(0xFF10B981),
      'iconType': 'bottle',
      'isCompleted': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF8F9),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── TOP APP BAR / HEADER ───
              _buildHeader(context),
              const SizedBox(height: 20),

              // ─── ACTIVE / COMPLETED TABS ───
              _buildTabSelector(),
              const SizedBox(height: 24),

              if (_isActiveTab) ...[
                // ─── TODAY SECTION ───
                Text(
                  'Today',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 12),
                ..._todayMedicines.map((m) => _buildMedicineCard(m)),

                const SizedBox(height: 24),

                // ─── TOMORROW SECTION ───
                Text(
                  'Tomorrow',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 12),
                ..._tomorrowMedicines.map((m) => _buildMedicineCard(m)),
              ] else ...[
                // ─── COMPLETED SECTION ───
                Text(
                  'Completed Prescriptions',
                  style: GoogleFonts.outfit(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1B1C1A),
                  ),
                ),
                const SizedBox(height: 12),
                ..._completedMedicines.map((m) => _buildMedicineCard(m)),
              ],

              const SizedBox(height: 24),

              // ─── BOTTOM ADVICE BANNER ───
              _buildAdviceBanner(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // ─── HEADER WIDGET ───
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDECEF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xFF1E2024),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prescriptions',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                Text(
                  'Your medicines',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF7A7E85),
                  ),
                ),
              ],
            ),
          ],
        ),

        // Add Button
        GestureDetector(
          onTap: () => _showAddMedicineDialog(context),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFDECEF),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4E6A).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFFFF4E6A),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // ─── TAB SELECTOR ───
  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEF),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isActiveTab = true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _isActiveTab ? const Color(0xFFFF4E6A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: _isActiveTab
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4E6A).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Active',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isActiveTab ? Colors.white : const Color(0xFF5A5D64),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isActiveTab = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_isActiveTab ? const Color(0xFFFF4E6A) : Colors.transparent,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: !_isActiveTab
                      ? [
                          BoxShadow(
                            color: const Color(0xFFFF4E6A).withValues(alpha: 0.25),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Completed',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: !_isActiveTab ? Colors.white : const Color(0xFF5A5D64),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MEDICINE CARD ───
  Widget _buildMedicineCard(Map<String, dynamic> item) {
    final isCompleted = item['isCompleted'] as bool;
    final iconBg = item['iconBg'] as Color;
    final iconColor = item['iconColor'] as Color;
    final timeColor = item['timeColor'] as Color;
    final isBottle = item['iconType'] == 'bottle';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: isBottle
                  ? Icon(Icons.medication_liquid_rounded, color: iconColor, size: 24)
                  : Transform.rotate(
                      angle: -0.6,
                      child: Icon(Icons.medication_rounded, color: iconColor, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['instruction'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF7A7E85),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: timeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      item['time'] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: timeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Checkbox toggle
          GestureDetector(
            onTap: () {
              setState(() {
                item['isCompleted'] = !isCompleted;
              });
            },
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted ? const Color(0xFFFF4E6A) : Colors.transparent,
                border: isCompleted
                    ? null
                    : Border.all(
                        color: const Color(0xFFD4D7DF),
                        width: 2,
                      ),
              ),
              child: isCompleted
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  // ─── ADVICE BANNER ───
  Widget _buildAdviceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECEF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFFCE0E5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_outlined,
              color: Color(0xFFFF4E6A),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Take medicines as prescribed',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Do not stop any medicine without consulting your doctor.',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF6B707B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Illustration of pills
          _buildPillIllustration(),
        ],
      ),
    );
  }

  Widget _buildPillIllustration() {
    return SizedBox(
      width: 50,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Bottle body
          Positioned(
            right: 0,
            bottom: 2,
            child: Container(
              width: 30,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFFD2DC), width: 1.5),
              ),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3898EC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 18,
                    height: 16,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Pill 1
          Positioned(
            left: 0,
            bottom: 6,
            child: Container(
              width: 24,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3898EC), Colors.white],
                  stops: [0.5, 0.5],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
          // Pill 2
          Positioned(
            left: 12,
            bottom: 0,
            child: Container(
              width: 20,
              height: 10,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFF59E0B)],
                  stops: [0.5, 0.5],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMedicineDialog(BuildContext context) {
    final titleController = TextEditingController();
    final instructionController = TextEditingController();
    final timeController = TextEditingController(text: '8:00 PM');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add Medicine',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Medicine Name',
                hintText: 'e.g. Folic Acid, Calcium',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: instructionController,
              decoration: InputDecoration(
                labelText: 'Dosage & Instructions',
                hintText: 'e.g. 1 tablet • After lunch',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: timeController,
              decoration: InputDecoration(
                labelText: 'Reminder Time',
                hintText: 'e.g. 8:00 PM',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (titleController.text.trim().isNotEmpty) {
                    setState(() {
                      _todayMedicines.add({
                        'name': titleController.text.trim(),
                        'instruction': instructionController.text.trim().isEmpty
                            ? '1 tablet • As directed'
                            : instructionController.text.trim(),
                        'time': timeController.text.trim(),
                        'timeColor': const Color(0xFFFF4E6A),
                        'iconBg': const Color(0xFFFFF0F3),
                        'iconColor': const Color(0xFFFF4E6A),
                        'iconType': 'pill',
                        'isCompleted': false,
                      });
                    });
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Save Prescription',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
