import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// Enter a family code, see whose household it is, and join it.
///
/// The lookup goes to the server rather than this device's tables: the family
/// being joined was created on somebody else's phone, so a local match could
/// only ever find a household this user already knew about.
class JoinFamilyCodePage extends StatefulWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;

  /// The joiner's own role — "Dad" or "Mom" — which decides the relation their
  /// membership row gets and who the screen looks for in the family.
  final String selectedRole;

  const JoinFamilyCodePage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Dad',
  });

  @override
  State<JoinFamilyCodePage> createState() => _JoinFamilyCodePageState();
}

class _JoinFamilyCodePageState extends State<JoinFamilyCodePage> {
  static const _primaryColor = Color(0xFFFF5277);

  final TextEditingController _codeController = TextEditingController();

  bool _isChecking = false;
  bool _isJoining = false;
  FamilyCodePreview? _preview;
  String? _errorMessage;

  bool get _isDad => widget.selectedRole.trim().toLowerCase() == 'dad';

  /// Who the joiner expects to find behind the code.
  String get _lookingFor => _isDad ? 'mother' : 'father';
  String get _partnerWord => _isDad ? 'Mommy' : 'Daddy';

  bool get _isOnboarding => !MainController.instance.isRegistered;

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

    // Below six characters the code is still being typed, so anything the last
    // lookup said is stale rather than wrong.
    if (code.length < 6) {
      if (_preview != null || _errorMessage != null) {
        setState(() {
          _preview = null;
          _errorMessage = null;
        });
      }
      return;
    }

    if (_isChecking || _preview != null) return;

    setState(() {
      _isChecking = true;
      _errorMessage = null;
    });

    final lookup = await FamilyController.instance.previewCode(code);
    if (!mounted) return;

    setState(() {
      _isChecking = false;
      _preview = lookup.preview;
      _errorMessage = lookup.error ?? _blockerFor(lookup.preview);
    });
  }

  /// Why this family cannot be joined, when that is knowable before trying.
  String? _blockerFor(FamilyCodePreview? preview) {
    if (preview == null) return null;
    if (preview.hasOtherFamily) {
      return "You're already in another family. Leave it first, then join this "
          'one with the code.';
    }
    return null;
  }

  /// The person the joiner came looking for — the other parent — if the family
  /// has one yet.
  FamilyPreviewMember? get _expectedParent =>
      _preview?.parent(_lookingFor);

  Future<void> _joinAndContinue() async {
    final code = _codeController.text.trim().toUpperCase();
    final preview = _preview;
    if (preview == null || _isJoining) return;

    setState(() => _isJoining = true);

    final error = await FamilyController.instance.joinByCode(
      code,
      role: widget.selectedRole,
    );
    if (!mounted) return;

    if (error != null) {
      setState(() {
        _isJoining = false;
        _errorMessage = error;
      });
      return;
    }

    setState(() => _isJoining = false);

    final family = FamilyController.instance.family;
    final partner = family?.otherParent;

    // Somebody who has already finished registration came here to join, not to
    // sign up, so they go back to the family screen with the result.
    if (!_isOnboarding) {
      Navigator.pop(context, true);
      return;
    }

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
          selectedRole: widget.selectedRole,
          familyCode: family?.code ?? code,
          partnerName: partner?.name ?? _expectedParent?.name,
          partnerPhone: partner?.phone,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final canJoin = preview != null && !preview.hasOtherFamily && !_isJoining;

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
                          onTap: () => narratedPop(context),
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
                        'Ask $_partnerWord for the 6-digit\nFamily Code to join! 💌',
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
                                  : (preview != null
                                        ? const Color(0xFF10B981)
                                        : const Color(0xFFE5E7EB)),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tag_rounded,
                                color: preview != null
                                    ? const Color(0xFF10B981)
                                    : _primaryColor,
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
                              if (_isChecking)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: _primaryColor,
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
                              height: 1.4,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],

                        // Family found card
                        if (preview != null) ...[
                          const SizedBox(height: 16),
                          _familyCard(preview),
                        ],

                        const SizedBox(height: 24),

                        // Action Buttons
                        Row(
                          children: [
                            // Back button
                            Expanded(
                              flex: 1,
                              child: SizedBox(
                                height: 52,
                                child: OutlinedButton(
                                  onPressed: _isJoining
                                      ? null
                                      : () => Navigator.pop(context),
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
                                  onPressed: canJoin ? _joinAndContinue : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primaryColor,
                                    disabledBackgroundColor: const Color(
                                      0xFFFFB3C1,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isJoining
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          preview?.isMember == true
                                              ? 'Continue'
                                              : 'Join & Continue',
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

  /// The household behind the code: who is in it, and — when the parent this
  /// user came for is missing — that joining is still the right move.
  Widget _familyCard(FamilyCodePreview preview) {
    final parent = _expectedParent;
    final headline = preview.isMember
        ? "You're already in this family"
        : (parent == null
              ? 'Family Found'
              : '${_lookingFor[0].toUpperCase()}${_lookingFor.substring(1)} '
                    'Found');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFD1FAE5),
                ),
                child: Center(
                  child: Text(
                    _isDad ? '👩‍🦰' : '👨',
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      parent?.name ?? preview.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      '${preview.displayName} · ${preview.memberCount} '
                      '${preview.memberCount == 1 ? 'member' : 'members'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

          // A household whose other parent has not been entered yet is still
          // the right one to join — the seat is simply empty, and this user is
          // the one who fills it.
          if (parent == null && !preview.isMember) ...[
            const SizedBox(height: 10),
            Text(
              'No $_lookingFor has been added to this family yet. You can still '
              'join, then add their details.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.45,
                color: const Color(0xFF047857),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
