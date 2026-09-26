import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class AddFamilyMemberSheet extends StatefulWidget {
  final String? familyID;
  final VoidCallback onMemberAdded;

  /// Pre-selects the relationship dropdown — e.g. the chatbot's "add father"
  /// flow opens this sheet already set to "Father" rather than making the
  /// user pick it again.
  final String? initialRelationship;

  /// The family's current members (as the People screen already has them
  /// loaded), used to catch "this phone number is already in your family"
  /// before submitting rather than letting the server silently update the
  /// existing member's relation.
  final List<dynamic> existingMembers;

  const AddFamilyMemberSheet({
    super.key,
    this.familyID,
    required this.onMemberAdded,
    this.initialRelationship,
    this.existingMembers = const [],
  });

  @override
  State<AddFamilyMemberSheet> createState() => _AddFamilyMemberSheetState();
}

class _AddFamilyMemberSheetState extends State<AddFamilyMemberSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();

  String? _selectedGender;
  String? _selectedRelationship;
  DateTime? _selectedLmpDate;
  bool _isLoading = false;

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _relationshipOptions = [
    'Father',
    'Mother',
    'Wife',
    'Children',
    'Brother',
    'Sister',
    'Grandmother',
    'Grandfather',
    'Relative',
    'Caregiver',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRelationship;
    if (initial != null && _relationshipOptions.contains(initial)) {
      _selectedRelationship = initial;
      if (initial == 'Mother' || initial == 'Wife' || initial == 'Grandmother') {
        _selectedGender = 'Female';
      } else if (initial == 'Father' || initial == 'Grandfather') {
        _selectedGender = 'Male';
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// The last 10 digits of [phone], which is what two numbers actually need
  /// to share to be "the same number" regardless of country code or spacing.
  String _phoneKey(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 10 ? digits : digits.substring(digits.length - 10);
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _showMsg('Please enter member name');
      return false;
    }
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      _showMsg('Please enter a valid 10-digit phone number');
      return false;
    }
    final enteredKey = _phoneKey(phone);
    final alreadyInFamily = widget.existingMembers.any((m) {
      if (m is! Map) return false;
      final existingPhone = (m['phone'] ?? '').toString();
      return existingPhone.isNotEmpty && _phoneKey(existingPhone) == enteredKey;
    });
    if (alreadyInFamily) {
      _showMsg('This phone number already belongs to a member of your family');
      return false;
    }
    if (_ageController.text.trim().isEmpty) {
      _showMsg('Please enter member age');
      return false;
    }
    if (_selectedGender == null) {
      _showMsg('Please select gender');
      return false;
    }
    if (_selectedRelationship == null) {
      _showMsg('Please select relationship');
      return false;
    }
    return true;
  }

  void _showMsg(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? const Color(0xFF10B981) : const Color(0xFFFF4E6A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final ownerId = MainController.instance.userId;
      if (ownerId.isEmpty) {
        _showMsg('Sign in before adding family members');
        return;
      }

      // Server-side — a family created only in local SQLite was invisible to
      // the automatic sync that runs right after (`refreshFromServer`), which
      // would then delete the member it had just added, reading its absence
      // from the server as "this person left."
      final error = await FamilyController.instance.addMember(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _selectedGender ?? '',
        relationship: _selectedRelationship ?? '',
        lmpDate: _selectedLmpDate,
      );
      if (error != null) {
        _showMsg(error);
        return;
      }

      _showMsg('Family member added successfully!', isSuccess: true);
      speak(NarrationKeys.pgConfFamilySaved, force: true);
      widget.onMemberAdded();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showMsg('Error adding member: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Sheet Title
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.person_add_alt_1_rounded, color: primaryColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Add Family Member',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Name field
            Text(
              'NAME',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8E95A5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'e.g. Meera Kumar',
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Phone field
            Text(
              'PHONE NUMBER',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8E95A5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              buildCounter: (context, {required currentLength, required isFocused, required maxLength}) => null,
              decoration: InputDecoration(
                hintText: '9876543210',
                prefixIcon: const Icon(Icons.phone_outlined, size: 20, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Age & Gender Row
            Row(
              children: [
                // Age Field
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AGE',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E95A5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _ageController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'e.g. 28',
                          prefixIcon: const Icon(Icons.cake_outlined, size: 20, color: Color(0xFF9CA3AF)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Gender Dropdown
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GENDER',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF8E95A5),
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGender,
                        hint: Text('Select', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: primaryColor, width: 1.5),
                          ),
                        ),
                        items: _genderOptions.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g));
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedGender = val;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Relationship Dropdown
            Text(
              'RELATIONSHIP',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF8E95A5),
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedRelationship,
              hint: Text('Select relationship', style: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade500)),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.family_restroom_rounded, size: 20, color: Color(0xFF9CA3AF)),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
              items: _relationshipOptions.map((r) {
                return DropdownMenuItem(value: r, child: Text(r));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedRelationship = val;
                  if (val == 'Mother' || val == 'Wife' || val == 'Grandmother') {
                    _selectedGender = 'Female';
                  } else if (val == 'Father' || val == 'Grandfather') {
                    _selectedGender = 'Male';
                  }
                });
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Add Member',
                            style: GoogleFonts.poppins(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
