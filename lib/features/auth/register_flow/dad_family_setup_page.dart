import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/features/auth/register_flow/join_family_code_page.dart';
import 'package:allomom/features/auth/register_flow/register_partner_details_page.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

/// Family Setup: where a parent either finds the household they already belong
/// to, or picks how to get into one.
///
/// It is the same screen for both parents and at both moments. Somebody
/// half-way through registration sees it as a step and "Continue" carries them
/// into the rest of the flow; somebody who has already finished — `is_registered`
/// — sees it as the family they are in, and "Continue" simply takes them back.
/// Which of the two applies is read off the account, not passed in, so a screen
/// that pushes this one cannot get it wrong.
class DadFamilySetupPage extends StatefulWidget {
  final String userName;
  final String phone;
  final String countryCode;
  final String selectedLanguage;

  /// The viewer's own role — "Dad" or "Mom". Decides who the screen talks
  /// about: Daddy is asked about Mommy and the other way round.
  final String selectedRole;

  const DadFamilySetupPage({
    super.key,
    required this.userName,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Dad',
  });

  @override
  State<DadFamilySetupPage> createState() => _DadFamilySetupPageState();
}

class _DadFamilySetupPageState extends State<DadFamilySetupPage> {
  AppPalette get _p => context.palette;

  static const _primaryColor = Color(0xFFFF5277);

  bool _loading = true;
  bool _leaving = false;
  FamilyGroup? _family;

  bool get _isDad => widget.selectedRole.trim().toLowerCase() == 'dad';

  /// Who the other parent is, in the words this viewer uses.
  String get _partnerWord => _isDad ? 'Mommy' : 'Daddy';

  /// True while the user is still being registered. A finished account opening
  /// this screen is managing their family, not completing a sign-up, so
  /// "Continue" must not push them back into the registration flow.
  bool get _isOnboarding => !MainController.instance.isRegistered;

  @override
  void initState() {
    super.initState();
    _load();
  }

  /// Reads the household — local tables first so the card can appear at once,
  /// then the server, which is the only place a family somebody *else* created
  /// for this user can come from.
  Future<void> _load() async {
    final controller = FamilyController.instance;
    await controller.loadFromLocal();
    if (mounted) {
      setState(() {
        _family = controller.family;
        _loading = controller.family == null;
      });
    }

    await controller.refreshFromServer();
    if (!mounted) return;
    setState(() {
      _family = controller.family;
      _loading = false;
    });
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  Future<void> _openJoinByCode() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => JoinFamilyCodePage(
          userName: widget.userName,
          phone: widget.phone,
          countryCode: widget.countryCode,
          selectedLanguage: widget.selectedLanguage,
          selectedRole: widget.selectedRole,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openPartnerDetails() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPartnerDetailsPage(
          userName: widget.userName,
          status: 'notpregnant',
          eddDate: null,
          lmpDate: null,
          phone: widget.phone,
          countryCode: widget.countryCode,
          selectedRole: widget.selectedRole,
        ),
      ),
    );
    if (!mounted) return;
    await _load();
  }

  /// Where "Continue" goes once the user has a family.
  ///
  /// Registration carries on into the rest of the flow, handing forward what
  /// the family already knows so the later screens do not ask for it again. A
  /// finished account just goes back to wherever it came from.
  void _onContinue() {
    final family = _family;

    if (!_isOnboarding) {
      Navigator.pop(context, true);
      return;
    }

    final partner = family?.otherParent;
    if (partner == null) {
      _openPartnerDetails();
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
          familyCode: family?.code,
          partnerName: partner.name,
          partnerPhone: partner.phone,
        ),
      ),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Family code $code copied'),
        duration: const Duration(milliseconds: 1200),
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final family = _family;
    if (family == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Leave ${family.displayName}?',
          style: GoogleFonts.outfit(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
          ),
        ),
        content: Text(
          "You'll stop seeing shared vitals, timeline and pregnancy records. "
          'Your own profile and babies stay with you, and you can join again '
          'with the family code.',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            height: 1.45,
            color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Stay',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Leave family',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                color: const Color(0xFFDC2626),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _leaving = true);
    final error = await FamilyController.instance.exitFamily();
    if (!mounted) return;
    setState(() {
      _leaving = false;
      _family = FamilyController.instance.family;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'You have left ${family.displayName}'),
        backgroundColor: error == null ? null : const Color(0xFFDC2626),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  String get _speechText {
    if (_loading) return 'One moment! 🍼\nLooking for your family...';
    final family = _family;
    if (family != null) {
      return "You're part of\n${family.displayName}! 🎉";
    }
    return _isDad
        ? 'Welcome Daddy! 🌟\nDo you already have a Family Code?'
        : 'Welcome Mommy! 🌟\nDo you already have a Family Code?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Fills the viewport so the baby can expand into whatever the card
            // below does not claim, and scrolls instead of overflowing when the
            // card needs more room than the screen has.
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
                            decoration: BoxDecoration(
                              color: _p.card,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _p.pick(Colors.black12, _p.shadow),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                              size: 24,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Family Setup',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ─── BABY SPEECH AVATAR ───
                  Expanded(
                    child: BabyHeroBanner(
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      expand: true,
                      speechText: _speechText,
                      onSpeakerTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Playing family guide...'),
                            duration: Duration(milliseconds: 1000),
                          ),
                        );
                      },
                    ),
                  ),

                  // ─── BOTTOM CARD CONTAINER ───
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      24,
                      28,
                      24,
                      28 + MediaQuery.paddingOf(context).bottom,
                    ),
                    decoration: BoxDecoration(
                      color: _p.card,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _p.pick(Colors.black12, _p.shadow),
                          blurRadius: 20,
                          offset: Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _loading
                          ? _loadingChildren()
                          : (_family == null
                                ? _chooseChildren()
                                : _familyChildren(_family!)),
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

  List<Widget> _loadingChildren() {
    return [
      const SizedBox(height: 40),
      const Center(
        child: CircularProgressIndicator(
          color: _primaryColor,
          strokeWidth: 2.5,
        ),
      ),
      const SizedBox(height: 18),
      Center(
        child: Text(
          'Checking your family...',
          style: GoogleFonts.poppins(
            fontSize: 13.5,
            color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
          ),
        ),
      ),
    ];
  }

  /// The screen for somebody who is already in a household: what it is, who is
  /// in it, and the two ways out — carry on, or leave.
  List<Widget> _familyChildren(FamilyGroup family) {
    final partner = family.otherParent;

    return [
      _sectionLabel('YOUR FAMILY'),
      const SizedBox(height: 10),
      Text(
        family.displayName,
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        partner == null
            ? "You're set up, but $_partnerWord hasn't been added yet. "
                  'Share the code below, or add their details yourself.'
            : 'You share vitals, timeline and pregnancy records with '
                  '${family.memberCount} '
                  '${family.memberCount == 1 ? 'person' : 'people'} here.',
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
          height: 1.45,
        ),
      ),

      if ((family.code ?? '').isNotEmpty) ...[
        const SizedBox(height: 16),
        _codeChip(family.code!),
      ],

      const SizedBox(height: 18),
      ...family.members.map(_memberTile),

      const SizedBox(height: 22),

      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _leaving ? null : _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            disabledBackgroundColor: _p.pick(const Color(0xFFFFB3C1), const Color(0xFF7A3A48)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isOnboarding ? 'Continue' : 'Done',
                style: GoogleFonts.poppins(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),

      // A household with only one parent in it can still have the other added
      // from here — the family exists, so this fills the empty seat rather
      // than creating anything.
      if (partner == null) ...[
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton(
            onPressed: _leaving ? null : _openPartnerDetails,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: _p.border, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_add_alt_1_rounded,
                  color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    "Add $_partnerWord's details",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],

      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: _leaving ? null : _confirmLeave,
          icon: _leaving
              ? const SizedBox(
                  width: 15,
                  height: 15,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFFDC2626),
                  ),
                )
              : const Icon(
                  Icons.logout_rounded,
                  size: 17,
                  color: Color(0xFFDC2626),
                ),
          label: Text(
            _leaving ? 'Leaving...' : 'Leave this family',
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFDC2626),
            ),
          ),
        ),
      ),
    ];
  }

  /// The screen for somebody with no household yet: join one, or build one by
  /// entering their partner's details.
  List<Widget> _chooseChildren() {
    return [
      _sectionLabel('FAMILY GROUP'),
      const SizedBox(height: 10),
      Text(
        'Connect with $_partnerWord',
        style: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        'A 6-character family code lets you link directly with $_partnerWord to '
        'access shared vitals, timeline, and pregnancy records.',
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
          height: 1.45,
        ),
      ),
      const SizedBox(height: 28),

      // Option A: Yes, I have a code
      SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _openJoinByCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.vpn_key_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                'I have a Family Code',
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

      const SizedBox(height: 14),

      // Option B: No code, set the partner up and let the family be created
      SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton(
          onPressed: _openPartnerDetails,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _p.border, width: 1.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.family_restroom_rounded,
                color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  "No, I'll set up $_partnerWord's details",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _p.pick(const Color(0xFF4B5563), _p.textSecondary),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  // ── Pieces ─────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _codeChip(String code) {
    return GestureDetector(
      onTap: () => _copyCode(code),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF5F8)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _p.pick(const Color(0xFFFCD9E3), _p.accentBorder), width: 1.2),
        ),
        child: Row(
          children: [
            const Icon(Icons.tag_rounded, color: _primaryColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'FAMILY CODE',
                    style: GoogleFonts.poppins(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    code,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.copy_rounded, size: 18, color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _memberTile(FamilyMemberInfo member) {
    final photo = member.profilePicture;
    final name = member.isMe ? '${member.name} (You)' : member.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFCE7F0)),
            backgroundImage: photo == null || photo.isEmpty
                ? null
                : NetworkImage(photo),
            child: photo == null || photo.isEmpty
                ? Text(
                    member.name.isEmpty ? '?' : member.name[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFFF4E6A),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  member.displayRelation,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                  ),
                ),
              ],
            ),
          ),
          // Says whether this person has claimed their account. An invited
          // member is somebody's placeholder until they sign in themselves.
          if (!member.isMe)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: member.isRegistered
                    ? _p.tint(const Color(0xFF10B981), const Color(0xFFECFDF5))
                    : _p.pick(const Color(0xFFF3F4F6), _p.surface),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.isRegistered ? 'Joined' : 'Invited',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: member.isRegistered
                      ? const Color(0xFF059669)
                      : _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
