import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/controllers/health_vital_controller.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class HealthInfoEditorSheet extends StatefulWidget {
  const HealthInfoEditorSheet({
    super.key,
    required this.userId,
    required this.initialHeight,
    required this.initialWeight,
    required this.initialBloodGroup,
    this.primaryColor = const Color(0xFFFF3B5C),
  });

  final String userId;
  final double? initialHeight;
  final double? initialWeight;
  final String? initialBloodGroup;
  final Color primaryColor;

  static void show({
    required BuildContext context,
    required String userId,
    required double? height,
    required double? weight,
    required String? bloodGroup,
    Color primaryColor = const Color(0xFFFF3B5C),
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HealthInfoEditorSheet(
        userId: userId.trim(),
        initialHeight: height,
        initialWeight: weight,
        initialBloodGroup: bloodGroup,
        primaryColor: primaryColor,
      ),
    );
  }

  @override
  State<HealthInfoEditorSheet> createState() => _HealthInfoEditorSheetState();
}

class _HealthInfoEditorSheetState extends State<HealthInfoEditorSheet> {
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
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;
  String? _selectedBloodGroup;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(
      text: widget.initialHeight != null && widget.initialHeight! > 0
          ? widget.initialHeight!.toStringAsFixed(0)
          : '',
    );
    _weightController = TextEditingController(
      text: widget.initialWeight != null && widget.initialWeight! > 0
          ? widget.initialWeight!.toStringAsFixed(1)
          : '',
    );
    final initialBloodGroup = widget.initialBloodGroup?.trim() ?? '';
    _selectedBloodGroup = initialBloodGroup.isNotEmpty && initialBloodGroup != '--'
        ? initialBloodGroup
        : null;
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _saveHealthData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final heightText = _heightController.text.trim();
      final weightText = _weightController.text.trim();
      final parsedHeight = heightText.isNotEmpty ? double.tryParse(heightText) : null;
      final parsedWeight = weightText.isNotEmpty ? double.tryParse(weightText) : null;
      final now = DateTime.now();

      if (parsedHeight != null && parsedHeight > 0) {
        await HealthVitalsController.instance.addVitalEntry(
          key: 'height',
          value: parsedHeight,
          unit: 'cm',
          createdAt: now,
          userId: widget.userId,
        );
      }

      if (parsedWeight != null && parsedWeight > 0) {
        await HealthVitalsController.instance.addVitalEntry(
          key: 'weight',
          value: parsedWeight,
          unit: 'kg',
          createdAt: now,
          userId: widget.userId,
        );
      }

      if (_selectedBloodGroup != null && _selectedBloodGroup!.isNotEmpty) {
        await HealthVitalsController.instance.addVitalEntry(
          key: 'blood_group',
          value: 0,
          unit: _selectedBloodGroup!,
          createdAt: now,
          userId: widget.userId,
          data: {'blood_group': _selectedBloodGroup},
        );
        UserSessionManager.instance.updateBloodGroup(_selectedBloodGroup!);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health details updated successfully!'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving health details: $e'),
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Health Information',
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF8E95A5)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Height
              Text(
                'Height (cm)',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _heightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 162',
                  prefixIcon: const Icon(Icons.height_rounded, color: Color(0xFF8E95A5), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    final num = double.tryParse(val);
                    if (num == null || num < 40 || num > 250) {
                      return 'Please enter a valid height (40 - 250 cm)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Weight
              Text(
                'Weight (kg)',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: InputDecoration(
                  hintText: 'e.g. 62.5',
                  prefixIcon: const Icon(Icons.monitor_weight_outlined, color: Color(0xFF8E95A5), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val != null && val.isNotEmpty) {
                    final num = double.tryParse(val);
                    if (num == null || num < 20 || num > 250) {
                      return 'Please enter a valid weight (20 - 250 kg)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Blood Group
              Text(
                'Blood Group',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedBloodGroup,
                hint: const Text('Select Blood Group'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.bloodtype_rounded, color: Color(0xFFFF3B5C), size: 20),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: widget.primaryColor, width: 1.5),
                  ),
                ),
                items: _bloodGroups.map((bg) {
                  return DropdownMenuItem(
                    value: bg,
                    child: Text(
                      bg,
                      style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedBloodGroup = val);
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveHealthData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          'Save Changes',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
