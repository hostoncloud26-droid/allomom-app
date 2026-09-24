import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/family_controller.dart';
import 'package:allomom/features/auth/register_flow/family_details_page.dart';
import 'package:allomom/features/auth/register_flow/register_lmp_timeline_page.dart';
import 'package:allomom/features/background_audio/data/narration_flow.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class RegisterPartnerDetailsPage extends StatefulWidget {
  final String userName;
  final String status;

  /// Null when the mother is not pregnant — there is no due date to carry.
  final DateTime? eddDate;
  final DateTime? lmpDate;

  /// Her average cycle length, captured on the cycle screen when she is not
  /// pregnant.
  final int? averageCycleLength;
  final String phone;
  final String countryCode;
  final String selectedRole;

  const RegisterPartnerDetailsPage({
    super.key,
    required this.userName,
    required this.status,
    required this.eddDate,
    this.lmpDate,
    this.averageCycleLength,
    this.phone = '',
    this.countryCode = '+91',
    this.selectedRole = 'Mom',
  });

  @override
  State<RegisterPartnerDetailsPage> createState() =>
      _RegisterPartnerDetailsPageState();
}

class _RegisterPartnerDetailsPageState
    extends State<RegisterPartnerDetailsPage> {
  AppPalette get _p => context.palette;

  final TextEditingController _partnerNameController = TextEditingController();
  final TextEditingController _partnerPhoneController = TextEditingController();
  final String _countryCode = '+91';

  /// The saved link, once there is one. Its presence is what swaps the form
  /// for the partner card.
  PartnerLink? _saved;

  /// True while the form is showing over an already-saved link, i.e. the user
  /// tapped Edit. Keeps "Next" meaning "save this edit" rather than "create".
  bool _editing = false;

  bool _isSaving = false;

  bool get _isDad => widget.selectedRole.trim().toLowerCase() == 'dad';

  /// Shown on the card while the flow has not yet saved the user's own name —
  /// the profile is only written at the end of registration, so the server's
  /// copy is still a placeholder at this point.
  String get _familyName {
    final me = widget.userName.trim();
    return me.isEmpty ? 'My Family' : "$me's Family";
  }

  @override
  void initState() {
    super.initState();
    // A partner saved on an earlier pass through this screen — the user
    // stepped back — should come up as the card, not an empty form.
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final family = FamilyController.instance;
    await family.loadFromLocal();
    if (!mounted) return;
    final existing = family.partner;
    if (existing == null) return;
    setState(() {
      _saved = existing;
      _partnerNameController.text = existing.displayName;
      _partnerPhoneController.text = existing.phone ?? '';
    });
  }

  /// The opening line.
  ///
  /// Dad is asked about Mommy and gets his own recording; a mother is asked
  /// about her partner in the wording of whichever journey she is on.
  String get _narrationKey => _isDad
      ? NarrationKeys.pregPartnerDad
      : NarrationFlowKeys.of(widget.status).partner;

  @override
  void dispose() {
    _partnerNameController.dispose();
    _partnerPhoneController.dispose();
    super.dispose();
  }

  void _promptRegisterPregnancy(String partnerName, String partnerPhone) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: _p.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFCE7F0)),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Color(0xFFFF5277),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Register Mommy's Pregnancy?",
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Would you like to record Mommy's pregnancy timeline (LMP & expected due date) so you can track her journey together?",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RegisterLmpTimelinePage(
                          userName: widget.userName,
                          status: 'pregnant',
                          phone: widget.phone,
                          countryCode: widget.countryCode,
                          selectedRole: 'Dad',
                          partnerName: partnerName,
                          partnerPhone: partnerPhone,
                          registerPregnancyForPartner: true,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5277),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Yes, Record Pregnancy',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FamilyDetailsPage(
                          userName: widget.userName,
                          status: 'notpregnant',
                          eddDate: widget.eddDate,
                          averageCycleLength: widget.averageCycleLength,
                          lmpDate: null,
                          partnerName: partnerName,
                          partnerPhone: partnerPhone,
                          phone: widget.phone,
                          countryCode: widget.countryCode,
                          selectedRole: 'Dad',
                          registerPregnancyForPartner: false,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    'No, Continue Without Pregnancy',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Saves the partner, then shows the card rather than moving on.
  ///
  /// The screen deliberately stops here on success: the user has just created
  /// a person and a household, and seeing what was saved — and being able to
  /// correct it — matters more than one fewer tap. Continue carries on.
  Future<void> _onNext() async {
    final pName = _partnerNameController.text.trim();
    final pPhone = _partnerPhoneController.text.trim();

    // An empty name is the same as skipping: there is nobody to create.
    if (pName.isEmpty) {
      _goToFamilyDetails();
      return;
    }

    setState(() => _isSaving = true);

    final family = FamilyController.instance;
    // An edit routes to PATCH so the name lands on the nickname and the phone
    // on the partner's user row; a first save builds the whole link.
    final error = _saved == null
        ? await family.linkPartner(
            name: pName,
            phone: pPhone.isEmpty ? null : pPhone,
            countryCode: _countryCode,
            role: widget.selectedRole,
            familyName: _familyName,
          )
        : await family.updatePartner(name: pName, phone: pPhone);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFFF4E6A),
        ),
      );
      return;
    }

    // The save succeeded, so there is a partner; if the local mirror somehow
    // did not produce one, say so rather than leaving the form sitting there
    // looking like nothing happened.
    final saved = family.partner;
    if (saved == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved, but could not be shown. Please try again.'),
          backgroundColor: Color(0xFFFF4E6A),
        ),
      );
      return;
    }

    speak(NarrationKeys.pregPartnerSaved, force: true);
    setState(() {
      _saved = saved;
      _editing = false;
    });
  }

  /// Leaves the card for the form, pre-filled with what was saved.
  void _onEdit() {
    final saved = _saved;
    if (saved == null) return;
    setState(() {
      _editing = true;
      _partnerNameController.text = saved.displayName;
      _partnerPhoneController.text = saved.phone ?? '';
    });
  }

  /// Abandons an edit and returns to the card, discarding what was typed.
  void _cancelEdit() {
    final saved = _saved;
    if (saved == null) return;
    setState(() {
      _editing = false;
      _partnerNameController.text = saved.displayName;
      _partnerPhoneController.text = saved.phone ?? '';
    });
  }

  /// Carries on from the card into the rest of the flow.
  void _onContinue() {
    final saved = _saved;
    if (_isDad && saved != null) {
      _promptRegisterPregnancy(saved.displayName, saved.phone ?? '');
      return;
    }
    _goToFamilyDetails();
  }

  void _goToFamilyDetails() {
    // What was saved wins over what is in the fields: the user may have opened
    // the form to edit, changed their mind, and tapped Skip.
    final saved = _saved;
    final pName = saved?.displayName ?? _partnerNameController.text.trim();
    final pPhone = saved?.phone ?? _partnerPhoneController.text.trim();

    // Skipping is a normal choice here, not a failure — the baby says so
    // rather than letting the step pass in silence.
    speak(
      pName.isEmpty
          ? NarrationKeys.pregPartnerSkip
          : NarrationKeys.pregPartnerSaved,
      force: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FamilyDetailsPage(
          userName: widget.userName,
          status: _isDad ? 'notpregnant' : widget.status,
          eddDate: widget.eddDate,
          averageCycleLength: widget.averageCycleLength,
          lmpDate: widget.lmpDate,
          partnerName: pName.isNotEmpty ? pName : null,
          partnerPhone: pPhone.isNotEmpty ? pPhone : null,
          phone: widget.phone,
          countryCode: widget.countryCode,
          selectedRole: widget.selectedRole,
          registerPregnancyForPartner: false,
        ),
      ),
    );
  }

  /// Prettifies a stored relation for display: "wife" -> "Wife".
  String _titleCase(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  /// The saved partner, as a card: who they are to the user, which household
  /// they joined, and how to reach them.
  List<Widget> _partnerCardChildren(PartnerLink partner) {
    // "Wife"/"Husband" is what the user asked for and is the more human of the
    // two; the household role is the fallback for a member added elsewhere.
    final relation = _titleCase(
      partner.relationToMe ?? partner.familyRelation ?? 'Partner',
    );
    final family = partner.familyName ?? _familyName;
    final photo = partner.profilePicture;

    return [
      Row(
        children: [
          Text(
            'Partner Details',
            style: GoogleFonts.poppins(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
              letterSpacing: 0.8,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _onEdit,
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 15,
                  color: Color(0xFFFF4E6A),
                ),
                const SizedBox(width: 5),
                Text(
                  'Edit',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      // ─── USER CARD ───
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFFF5F8)),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _p.pick(const Color(0xFFFCD9E3), _p.accentBorder), width: 1.2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFCE7F0)),
              backgroundImage: photo == null || photo.isEmpty
                  ? null
                  : NetworkImage(photo),
              child: photo == null || photo.isEmpty
                  ? Text(
                      partner.displayName.isEmpty
                          ? '?'
                          : partner.displayName[0].toUpperCase(),
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFF4E6A),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    partner.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _pill(relation),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          family,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (partner.phone != null && partner.phone!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.phone_rounded,
                          size: 13,
                          color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${partner.countryCode ?? _countryCode} ${partner.phone}',
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: _onContinue,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5277),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            elevation: 0,
          ),
          child: Text(
            'Continue',
            style: GoogleFonts.poppins(
              fontSize: 15.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    ];
  }

  Widget _pill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFFF5277),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  /// The form: name, phone, and Skip / Next.
  List<Widget> _formChildren({
    required String nameLabel,
    required String nameHint,
    required String phoneLabel,
  }) {
    return [
      Text(
        nameLabel,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 8),

      // Partner Name Input
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _p.border, width: 1.5),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.favorite_outline_rounded,
              color: Color(0xFFFF4E6A),
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _partnerNameController,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
                decoration: InputDecoration(
                  hintText: nameHint,
                  hintStyle: GoogleFonts.poppins(
                    color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 16),

      Text(
        phoneLabel,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
          letterSpacing: 0.8,
        ),
      ),
      const SizedBox(height: 8),

      // Partner Phone Input
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: _p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _p.border, width: 1.5),
        ),
        child: Row(
          children: [
            Text(
              _countryCode,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: _p.border),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _partnerPhoneController,
                keyboardType: TextInputType.phone,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                ),
                decoration: InputDecoration(
                  hintText: '9876543210',
                  hintStyle: GoogleFonts.poppins(
                    color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
                    fontSize: 14.5,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),

      const SizedBox(height: 22),

      // ─── NEXT & SKIP ROW ───
      // Editing an existing partner turns the pair into Cancel / Save: there
      // is nothing to skip past once the link exists, and backing out should
      // return to the card rather than jump the user forward a screen.
      Row(
        children: [
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 52,
              child: OutlinedButton(
                onPressed: _isSaving
                    ? null
                    : _editing
                    ? _cancelEdit
                    : _goToFamilyDetails,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _p.border, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                child: Text(
                  _editing ? 'Cancel' : 'Skip',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          Expanded(
            flex: 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _onNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5277),
                  disabledBackgroundColor: _p.pick(const Color(0xFFFFA8BC), const Color(0xFF7A3A48)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _editing ? 'Save' : 'Next',
                        style: GoogleFonts.poppins(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    final speechText = _isDad
        ? 'Tell me about Mommy so she can be\npart of our journey too! 🌸'
        : 'Tell me about Daddy so he can be\npart of our journey too! 👨‍👩‍👦';

    final nameLabel = _isDad ? "MOMMY'S FULL NAME" : 'PARTNER FULL NAME';
    final nameHint = _isDad ? 'e.g. Ananya Kumar' : 'e.g. Anand Kumar';
    final phoneLabel = _isDad
        ? "MOMMY'S MOBILE NUMBER"
        : 'PARTNER MOBILE NUMBER';

    return Scaffold(
      backgroundColor: _p.pick(const Color(0xFFFAF6F7), _p.scaffoldSoft),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: CustomScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              // Fills the viewport so the Spacer can push the form card to the
              // bottom, and scrolls instead of overflowing once the keyboard
              // takes the space away.
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
                              'Partner Details',
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
                      child: BabyPrompt(
                        compact: isKeyboardOpen,
                        expand: true,
                        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        narrationKey: _narrationKey,
                        text: speechText,
                      ),
                    ),

                    // ─── BOTTOM CARD CONTAINER ───
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        24 + MediaQuery.paddingOf(context).bottom,
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
                        // The card replaces the form once there is
                        // something saved, and Edit brings it back.
                        children: _saved != null && !_editing
                            ? _partnerCardChildren(_saved!)
                            : _formChildren(
                                nameLabel: nameLabel,
                                nameHint: nameHint,
                                phoneLabel: phoneLabel,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
