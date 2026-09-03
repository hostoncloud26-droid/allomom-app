import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:drift/drift.dart' as drift;
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';
import 'package:allomom/services/sq_lite/services/health_db_service.dart';

class HealthProfilePage extends StatefulWidget {
  const HealthProfilePage({super.key});

  @override
  State<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<HealthProfilePage> {
  static const List<String> _bloodGroups = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _conditionsController;
  late final TextEditingController _recoveryPhoneController;

  String? _selectedBloodGroup;
  DateTime? _selectedDob;
  DateTime? _selectedLmp;
  DateTime? _selectedEdd;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final session = UserSessionManager.instance;
    final vitals = HealthVitalsController.instance;

    final initialHeight = vitals.heightVital?.value ?? session.currentHealthData?.height;
    final initialWeight = vitals.weightVital?.value ?? session.currentHealthData?.weight;
    final initialBg = session.bloodGroup ?? vitals.bloodGroupVital?.unit ?? '';

    _nameController = TextEditingController(text: session.userName);
    _heightController = TextEditingController(
      text: initialHeight != null && initialHeight > 0 ? initialHeight.toStringAsFixed(0) : '',
    );
    _weightController = TextEditingController(
      text: initialWeight != null && initialWeight > 0 ? initialWeight.toStringAsFixed(1) : '',
    );
    _allergiesController = TextEditingController(
      text: session.currentHealthData?.allergies ?? 'None reported',
    );
    _conditionsController = TextEditingController(
      text: session.currentHealthData?.medicalConditions ?? 'None reported',
    );
    _recoveryPhoneController = TextEditingController(
      text: session.currentHealthData?.recoveryPhone ?? session.partnerPhone ?? '',
    );

    _selectedBloodGroup = initialBg.isNotEmpty && initialBg != '--' ? initialBg : null;
    _selectedDob = session.dob;
    _selectedLmp = session.lmpDate;
    _selectedEdd = session.eddDate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _allergiesController.dispose();
    _conditionsController.dispose();
    _recoveryPhoneController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, DateTime? initial, Function(DateTime) onSelected) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(1960),
      lastDate: DateTime.now().add(const Duration(days: 300)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFFF3B5C),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E2024),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      onSelected(picked);
    }
  }

  Future<void> _saveHealthProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final session = UserSessionManager.instance;
      final vitals = HealthVitalsController.instance;

      final heightVal = double.tryParse(_heightController.text.trim());
      final weightVal = double.tryParse(_weightController.text.trim());
      final now = DateTime.now();

      if (heightVal != null && heightVal > 0) {
        await vitals.addVitalEntry(
          key: 'height',
          value: heightVal,
          unit: 'cm',
          createdAt: now,
          userId: session.userId,
        );
      }

      if (weightVal != null && weightVal > 0) {
        await vitals.addVitalEntry(
          key: 'weight',
          value: weightVal,
          unit: 'kg',
          createdAt: now,
          userId: session.userId,
        );
      }

      if (_selectedBloodGroup != null) {
        await vitals.addVitalEntry(
          key: 'blood_group',
          value: 0,
          unit: _selectedBloodGroup!,
          createdAt: now,
          userId: session.userId,
          data: {'blood_group': _selectedBloodGroup},
        );
        session.updateBloodGroup(_selectedBloodGroup!);
      }

      // Save to SQLite HealthDataTable
      final healthId = session.currentHealthData?.id ?? (session.userId.isNotEmpty ? session.userId : 'health_me');
      await HealthDbService.instance.saveHealthData(
        HealthDataTableCompanion(
          id: drift.Value(healthId),
          userId: drift.Value(session.userId),
          height: drift.Value(heightVal),
          weight: drift.Value(weightVal),
          bloodGroup: drift.Value(_selectedBloodGroup),
          allergies: drift.Value(_allergiesController.text.trim()),
          medicalConditions: drift.Value(_conditionsController.text.trim()),
          recoveryPhone: drift.Value(_recoveryPhoneController.text.trim()),
          lmpDate: drift.Value(_selectedLmp),
          edDate: drift.Value(_selectedEdd),
          pregnancyStatus: drift.Value(session.pregnancyStatus),
        ),
      );

      if (_selectedLmp != null) {
        session.updateLmpDate(_selectedLmp!);
      }
      if (_selectedEdd != null) {
        session.updateEddDate(_selectedEdd!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health profile updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating health profile: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSessionManager.instance;

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D3142), size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Health Profile',
          style: GoogleFonts.manrope(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E2024),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar header
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF5277), Color(0xFFFF3B5C)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF3B5C).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          session.userName.isNotEmpty ? session.userName[0].toUpperCase() : 'A',
                          style: GoogleFonts.manrope(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2D3142),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  session.userName,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E2024),
                  ),
                ),
              ),
              Center(
                child: Text(
                  'Week ${session.currentGestationalWeek} • ${session.currentTrimester}',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF3B5C),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section: Biometrics
              _buildSectionHeader('Biometric Measurements'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Height (cm)',
                      controller: _heightController,
                      icon: Icons.height_rounded,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField(
                      label: 'Weight (kg)',
                      controller: _weightController,
                      icon: Icons.monitor_weight_outlined,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Blood Group
              Text(
                'Blood Group',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                hint: const Text('Select Blood Group'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.bloodtype_rounded, color: Color(0xFFFF3B5C), size: 20),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                items: _bloodGroups.map((bg) {
                  return DropdownMenuItem(
                    value: bg,
                    child: Text(bg, style: GoogleFonts.manrope(fontWeight: FontWeight.w600)),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedBloodGroup = val),
              ),
              const SizedBox(height: 24),

              // Section: Pregnancy & Personal Dates
              _buildSectionHeader('Key Dates'),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildDateTile(
                      label: 'Date of Birth',
                      date: _selectedDob,
                      icon: Icons.cake_outlined,
                      onTap: () => _selectDate(context, _selectedDob, (d) => setState(() => _selectedDob = d)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateTile(
                      label: 'LMP Date',
                      date: _selectedLmp,
                      icon: Icons.calendar_today_rounded,
                      onTap: () => _selectDate(context, _selectedLmp, (d) => setState(() => _selectedLmp = d)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _buildDateTile(
                label: 'Estimated Due Date (EDD)',
                date: _selectedEdd,
                icon: Icons.child_care_rounded,
                onTap: () => _selectDate(context, _selectedEdd, (d) => setState(() => _selectedEdd = d)),
              ),
              const SizedBox(height: 24),

              // Section: Medical History
              _buildSectionHeader('Medical History & Allergies'),
              const SizedBox(height: 12),

              _buildFormField(
                label: 'Allergies',
                controller: _allergiesController,
                icon: Icons.warning_amber_rounded,
                hint: 'e.g. Peanuts, Penicillin (or None)',
              ),
              const SizedBox(height: 14),

              _buildFormField(
                label: 'Medical Conditions',
                controller: _conditionsController,
                icon: Icons.health_and_safety_outlined,
                hint: 'e.g. Thyroid, Gestational Diabetes (or None)',
              ),
              const SizedBox(height: 14),

              _buildFormField(
                label: 'Emergency / Recovery Phone',
                controller: _recoveryPhoneController,
                icon: Icons.phone_rounded,
                keyboardType: TextInputType.phone,
                hint: 'Partner / Doctor phone number',
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHealthProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Save Profile',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.manrope(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E2024),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 20),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFFF3B5C), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: const Color(0xFFFF3B5C)),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              date != null ? '${date.day}/${date.month}/${date.year}' : 'Not set',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
