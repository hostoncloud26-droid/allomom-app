import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class AddFamilyMemberSheet extends StatefulWidget {
  final String? familyID;
  final VoidCallback onMemberAdded;

  const AddFamilyMemberSheet({
    super.key,
    this.familyID,
    required this.onMemberAdded,
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
    'Relative',
    'Caregiver',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  bool _validate() {
    if (_nameController.text.trim().isEmpty) {
      _showMsg('Please enter member name');
      return false;
    }
    if (_phoneController.text.trim().length < 10) {
      _showMsg('Please enter a valid 10-digit phone number');
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
      // Local-only: the member is written to SQLite with synced = 0. A family
      // is created on the fly when the user does not have one yet.
      var familyId = widget.familyID;
      if (familyId == null || familyId.isEmpty) {
        final ownerId = UserSessionManager.instance.userId;
        if (ownerId.isEmpty) {
          _showMsg('Sign in before adding family members');
          return;
        }
        final existing = await FamilyDbService.instance.getMyFamily(ownerId);
        familyId = existing?.id ??
            (await FamilyDbService.instance
                    .createFamily(creatorUserId: ownerId))
                .id;
      }

      await FamilyDbService.instance.createFamilyMember(
        familyId: familyId,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        relation: _selectedRelationship,
        gender: _selectedGender,
        age: int.tryParse(_ageController.text.trim()),
        lmpDate: _selectedLmpDate,
      );

      _showMsg('Family member added successfully!', isSuccess: true);
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
                  if (val == 'Mother' || val == 'Wife') {
                    _selectedGender = 'Female';
                  } else if (val == 'Father') {
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
