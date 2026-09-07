import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';

class JoinFamilyCodePage extends StatefulWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;

  const JoinFamilyCodePage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
  });

  @override
  State<JoinFamilyCodePage> createState() => _JoinFamilyCodePageState();
}

class _JoinFamilyCodePageState extends State<JoinFamilyCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _familyData;
  Map<String, dynamic>? _motherData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _codeController.removeListener(_onCodeChanged);
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onCodeChanged() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code.length == 6 && !_isLoading && _motherData == null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // Local-only: the code is matched against families stored on this
        // device. Cross-device joins need the sync implementation.
        final family = await FamilyDbService.instance.getFamilyByCode(code);
        if (family == null) {
          setState(() {
            _isLoading = false;
            _familyData = null;
            _motherData = null;
            _errorMessage = "Invalid Family Code";
          });
          return;
        }

        final members = await FamilyDbService.instance.getFamilyMembers(
          family.id,
        );
        final mother = members.cast<FamilyMemberWithUser?>().firstWhere(
          (m) =>
              m!.userId == family.motherId ||
              m.relation.toLowerCase().contains('mother'),
          orElse: () => null,
        );

        setState(() {
          _familyData = {
            'id': family.id,
            'name': family.name ?? 'Family',
            'code': family.code ?? code,
          };
          _motherData = mother == null
              ? null
              : {'name': mother.name, 'phone': mother.phone};
          _isLoading = false;
          if (mother == null) {
            _errorMessage = "Family found, but no mother is registered yet.";
          }
        });
      } catch (e) {
        setState(() {
          _isLoading = false;
          _familyData = null;
          _motherData = null;
          _errorMessage = "Could not check code: $e";
        });
      }
    } else if (code.length < 6 &&
        (_motherData != null || _errorMessage != null)) {
      setState(() {
        _familyData = null;
        _motherData = null;
        _errorMessage = null;
      });
    }
  }

  void _proceedToFinish() {
    final code = _codeController.text.trim().toUpperCase();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyDetailsPage(
          userName: widget.userName,
          status: 'notpregnant',
          eddDate: DateTime.now().add(const Duration(days: 280)),
          lmpDate: null,
          phone: widget.phone,
          countryCode: widget.countryCode,
          selectedRole: 'Dad',
          familyCode: code,
          partnerName: _motherData?['name'],
          partnerPhone: _motherData?['phone'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFFF5277);

    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the Spacer can push the card to the
            // bottom, and scrolls instead of overflowing when the content or
            // an open keyboard needs more room than the screen has.
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                children: [
                  // ─── TOP APP BAR ───
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
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
                            'Enter Family Code',
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
                    speechText:
                        'Ask Mommy for her 6-digit\nFamily Code to join! 💌',
                    onSpeakerTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Playing family code instructions...'),
                          duration: Duration(milliseconds: 1000),
                        ),
                      );
                    },
                  ),

                  const Spacer(),

                  // ─── BOTTOM CARD CONTAINER ───
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '6-DIGIT CODE',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF8E95A5),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Code Input Field
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _errorMessage != null
                                  ? Colors.redAccent
                                  : (_motherData != null
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB)),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                color: _motherData != null
                                    ? const Color(0xFF10B981)
                                    : primaryColor,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _codeController,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  maxLength: 6,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    color: const Color(0xFF1E2024),
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: 'e.g. A9B2X1',
                                    hintStyle: GoogleFonts.outfit(
                                      color: const Color(0xFF9CA3AF),
                                      fontSize: 16,
                                      letterSpacing: 2,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: primaryColor,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        if (_errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],

                        // Mother Found Card
                        if (_motherData != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFA7F3D0),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 46,
                                  height: 46,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFD1FAE5),
                                  ),
                                  child: const Center(
                                    child: Text(
                                      '👩‍🦰',
                                      style: TextStyle(fontSize: 24),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: Color(0xFF059669),
                                            size: 16,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Mother Found',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF059669),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _motherData!['name'] ?? 'Mom',
                                        style: GoogleFonts.outfit(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF065F46),
                                        ),
                                      ),
                                      if (_familyData?['name'] != null)
                                        Text(
                                          _familyData!['name'],
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF047857),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Skip button
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: Color(0xFFE5E7EB),
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                  ),
                                  child: Text(
                                    'Back',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Continue button
                            Expanded(
                              flex: 2,
                              child: SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _motherData != null
                                      ? _proceedToFinish
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    disabledBackgroundColor: const Color(
                                      0xFFFFB3C1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Join & Continue',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
