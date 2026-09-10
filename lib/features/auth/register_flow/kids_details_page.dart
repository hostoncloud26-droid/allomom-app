// ignore_for_file: unused_import, unused_local_variable, unused_field
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/main_layout.dart';
import 'package:allomom/api/auth_api.dart';
import 'package:allomom/api/api_base.dart';
import 'package:allomom/repositories/pregnancy_state.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/repositories/baby_repository.dart';
import 'package:intl/intl.dart';
import 'package:allomom/features/baby/baby_options.dart';

class KidsDetailsPage extends StatefulWidget {
  final String userName;
  final String status;

  /// Null when the mother is not pregnant — there is no due date to carry.
  final DateTime? eddDate;
  final DateTime? lmpDate;
  final int? averageCycleLength;
  final String? partnerName;
  final String? partnerPhone;
  final String phone;
  final String countryCode;
  final String selectedRole;
  final String? familyCode;
  final bool registerPregnancyForPartner;

  const KidsDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.partnerName,
    this.partnerPhone,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
    this.familyCode,
    this.registerPregnancyForPartner = false,
  });

  @override
  State<KidsDetailsPage> createState() => _KidsDetailsPageState();
}

class _KidsDetailsPageState extends State<KidsDetailsPage> {
  /// Previous children entered here. Each one becomes a `birth_records` row
  /// once registration succeeds, so their vaccination schedule and milestone
  /// checklist can be built from the date of birth.
  final List<_KidEntry> _kidsList = [];

  static final _dateFmt = DateFormat('dd MMM yyyy');

  bool _isAddingKid = false;
  bool _isLoading = false;
  final TextEditingController _kidNameController = TextEditingController();
  DateTime? _kidDob;

  @override
  void dispose() {
    _kidNameController.dispose();
    super.dispose();
  }

  Future<void> _pickKidDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _kidDob ?? DateTime(now.year - 2, now.month, now.day),
      firstDate: DateTime(now.year - 18),
      lastDate: now,
      helpText: "Child's date of birth",
    );
    if (picked != null) setState(() => _kidDob = picked);
  }

  Future<void> _finishSetup() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isDad = widget.selectedRole.trim().toLowerCase() == 'dad';
      final storedStatus = pregnancyStatusForRegistration(
        widget.status,
        isDad: isDad,
        registeringForPartner: widget.registerPregnancyForPartner,
      );
      final payload = {
        "name": widget.userName.trim(),
        "phone": widget.phone.trim(),
        "countryCode": widget.countryCode,
        "userRole": widget.selectedRole,
        "gender": isDad ? "male" : "female",
        "userType": isDad ? "dad" : "patient",
        "pregnancyStatus": storedStatus,
        if (widget.eddDate != null) "edDate": widget.eddDate!.toIso8601String(),
        "lmpDate": widget.lmpDate?.toIso8601String(),
        if (widget.partnerName != null && widget.partnerName!.trim().isNotEmpty)
          "partnerName": widget.partnerName!.trim(),
        if (widget.partnerPhone != null &&
            widget.partnerPhone!.trim().isNotEmpty)
          "partnerPhone": widget.partnerPhone!.trim(),
        if (widget.familyCode != null && widget.familyCode!.trim().isNotEmpty)
          "familyCode": widget.familyCode!.trim(),
        "registerPregnancyForPartner": widget.registerPregnancyForPartner,
      };

      String? registeredUserId;
      String? jwt;
      String? refresh;
      String? healthDataId;

      final res = await AuthApi.registerMother(payload);
      if (!res.success) {
        throw Exception(
          res.detail.isNotEmpty
              ? res.detail
              : "Registration failed. Please try again.",
        );
      }

      if (res.item is Map) {
        final item = res.item as Map;
        registeredUserId = item["user_id"]?.toString() ?? res.id?.toString();
        jwt = item["jwt"]?.toString() ?? item["access_token"]?.toString();
        refresh = item["refresh"]?.toString();
        healthDataId = item["healthDataID"]?.toString();
      } else if (res.id != null) {
        registeredUserId = res.id.toString();
      }

      await UserSessionManager.instance.saveRegistration(
        name: widget.userName,
        phone: widget.phone,
        countryCode: widget.countryCode,
        pregnancyStatus: storedStatus,
        eddDate: widget.eddDate,
        averageCycleLength: widget.averageCycleLength,
        lmpDate: widget.lmpDate,
        partnerName: widget.partnerName,
        partnerPhone: widget.partnerPhone,
        hasKids: _kidsList.isNotEmpty,
        kidsCount: _kidsList.length,
        userId: registeredUserId,
        jwt: jwt,
        refresh: refresh,
        healthDataId: healthDataId,
      );

      await _saveKidsAsBirthRecords();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Welcome, ${widget.userName}! Your family profile is complete.',
          ),
          backgroundColor: const Color(0xFFFF4E6A),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainLayout()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing registration: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addNewKid() {
    final name = _kidNameController.text.trim();
    final dob = _kidDob;
    if (dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please pick your child's date of birth"),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _kidsList.add(_KidEntry(name: name.isEmpty ? null : name, dob: dob));
      _kidNameController.clear();
      _kidDob = null;
      _isAddingKid = false;
    });
  }

  /// Writes the children entered above as birth records.
  ///
  /// They carry no `pregnancyId` — these births predate the app, so there is
  /// no pregnancy row to link them to. Failures are swallowed deliberately:
  /// registration has already succeeded at this point and must not be rolled
  /// back because a child record could not be written locally.
  Future<void> _saveKidsAsBirthRecords() async {
    for (final kid in _kidsList) {
      try {
        await BabyRepository.instance.addBaby(dob: kid.dob, babyName: kid.name);
      } catch (e) {
        debugPrint('Could not save child ${kid.name ?? ''}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.maybePop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E2024),
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Children Details',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // ─── BABY SPEECH AVATAR ───
            BabyHeroBanner(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              speechText: 'Tell me about my brothers & sisters! 🎈',
              onSpeakerTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Playing siblings joy note...'),
                    duration: Duration(milliseconds: 1000),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // ─── BOTTOM CARD CONTAINER ───
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 20,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'ADDED CHILDREN',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8E95A5),
                              letterSpacing: 0.8,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isAddingKid = !_isAddingKid;
                              });
                            },
                            child: Row(
                              children: [
                                Icon(
                                  _isAddingKid
                                      ? Icons.close_rounded
                                      : Icons.add_circle_outline_rounded,
                                  size: 16,
                                  color: const Color(0xFFFF4E6A),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _isAddingKid ? 'Cancel' : 'Add Child',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFFF4E6A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Kids list
                      ..._kidsList.asMap().entries.map((entry) {
                        final index = entry.key;
                        final kid = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFD8E0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.face_rounded,
                                  color: Color(0xFFFF4E6A),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kid.name ?? 'Child ${index + 1}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1E2024),
                                      ),
                                    ),
                                    Text(
                                      '${_dateFmt.format(kid.dob)}  ·  '
                                      '${babyAgeLabel(kid.dob)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _kidsList.removeAt(index);
                                  });
                                },
                                child: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 20,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),

                      // Inline add form
                      if (_isAddingKid) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF4E6A),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              TextField(
                                controller: _kidNameController,
                                decoration: InputDecoration(
                                  hintText: 'Child\'s Name',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Divider(color: Color(0xFFFFD8E0)),
                              InkWell(
                                onTap: _pickKidDob,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.cake_rounded,
                                        size: 16,
                                        color: Color(0xFFFF4E6A),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        _kidDob == null
                                            ? 'Date of birth'
                                            : _dateFmt.format(_kidDob!),
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _kidDob == null
                                              ? const Color(0xFF9CA3AF)
                                              : const Color(0xFF1E2024),
                                        ),
                                      ),
                                      const Spacer(),
                                      if (_kidDob != null)
                                        Text(
                                          babyAgeLabel(_kidDob),
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _addNewKid,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF4E6A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Child',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      const SizedBox(height: 16),

                      // ─── FINISH BUTTON ───
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _finishSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5277),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Complete Setup',
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One child entered on the registration kids question, before it becomes a
/// birth record.
class _KidEntry {
  const _KidEntry({required this.dob, this.name});

  final String? name;
  final DateTime dob;
}
