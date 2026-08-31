import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class PregnancyConfirmationPage extends StatefulWidget {
  const PregnancyConfirmationPage({super.key});

  @override
  State<PregnancyConfirmationPage> createState() => _PregnancyConfirmationPageState();
}

class _PregnancyConfirmationPageState extends State<PregnancyConfirmationPage> {
  int _currentStep = 0;
  bool? _isDoctorConfirmed = true;
  DateTime? _selectedDueDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            _buildAppBar(context),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  children: [
                    // ─── CUTE HERO BABY ILLUSTRATION ───
                    _buildBabyIllustration(),
                    const SizedBox(height: 16),

                    // ─── HEADLINE & SUBTEXT ───
                    Text(
                      "Let's get your\ncare journey ready",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "I'll help you keep track of what your\ndoctor recommends.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF6B707B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── INTERACTIVE QUESTION CARD ───
                    _buildQuestionCard(context),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),

            // ─── BOTTOM DOTS INDICATOR ───
            _buildPageIndicatorDots(),
            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ───
  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Color(0xFFFF4E6A),
              size: 24,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Pregnancy Confirmation',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E2024),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO BABY ───
  Widget _buildBabyIllustration() {
    return Center(
      child: SizedBox(
        height: 190,
        child: Image.asset(
          'assets/allobaby/Baby3D.png',
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Image.asset(
            'assets/allobaby/BabyIllustration.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.child_care_rounded,
              size: 140,
              color: Color(0xFFFF4E6A),
            ),
          ),
        ),
      ),
    );
  }

  // ─── QUESTION CARD ───
  Widget _buildQuestionCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4E6A).withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Have you confirmed your\npregnancy with a doctor?',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              height: 1.3,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 22),

          // Button 1: Yes ✓
          GestureDetector(
            onTap: () {
              setState(() {
                _isDoctorConfirmed = true;
                _currentStep = 1;
              });
              _showDueDateBottomSheet(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _isDoctorConfirmed == true
                    ? const Color(0xFFFF5277)
                    : const Color(0xFFFDECEF),
                borderRadius: BorderRadius.circular(25),
                boxShadow: _isDoctorConfirmed == true
                    ? [
                        BoxShadow(
                          color: const Color(0xFFFF5277).withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  'Yes  ✓',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isDoctorConfirmed == true
                        ? Colors.white
                        : const Color(0xFF2A2D34),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Button 2: Not yet
          GestureDetector(
            onTap: () {
              setState(() {
                _isDoctorConfirmed = false;
              });
              _showNotYetGuidanceDialog(context);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 15),
              decoration: BoxDecoration(
                color: _isDoctorConfirmed == false
                    ? const Color(0xFFFF5277)
                    : const Color(0xFFFDECEF),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Center(
                child: Text(
                  'Not yet',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _isDoctorConfirmed == false
                        ? Colors.white
                        : const Color(0xFF2A2D34),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BOTTOM DOTS INDICATOR ───
  Widget _buildPageIndicatorDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isActive = index == _currentStep;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 8 : 6,
          height: isActive ? 8 : 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
          ),
        );
      }),
    );
  }

  void _showDueDateBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
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
              'Expected Due Date (EDD)',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E2024),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your doctor provides an estimated delivery date during early scans.',
              style: GoogleFonts.poppins(fontSize: 13, color: const Color(0xFF7A7E85)),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFD2DC)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: Color(0xFFFF4E6A)),
                      const SizedBox(width: 12),
                      Text(
                        _selectedDueDate != null
                            ? '${_selectedDueDate!.day}/${_selectedDueDate!.month}/${_selectedDueDate!.year}'
                            : 'Select Due Date',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 120)),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 300)),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDueDate = picked;
                        });
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          _showDueDateBottomSheet(context);
                        }
                      }
                    },
                    child: Text('Change', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final healthData = UserSessionManager.instance.currentHealthData;
                  if (healthData != null) {
                    await HealthDbService.instance.saveHealthData(
                      HealthDataTableCompanion(
                        id: drift.Value(healthData.id),
                        pregnancyStatus: const drift.Value('pregnant'),
                        edDate: drift.Value(_selectedDueDate ?? DateTime.now().add(const Duration(days: 112))),
                      ),
                    );
                    await UserSessionManager.instance.refresh();
                  }
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Care journey successfully registered!'),
                        backgroundColor: Color(0xFFFF4E6A),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E6A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(
                  'Continue Care Journey',
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

  void _showNotYetGuidanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0F3),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info_outline_rounded, color: Color(0xFFFF4E6A), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'First Doctor Visit',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Text(
          'We recommend scheduling your first Antenatal Care (ANC) appointment with your healthcare provider or PHC to confirm pregnancy and start essential supplements like Folic Acid.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF5A5D64), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Understood', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
