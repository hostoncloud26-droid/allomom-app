import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/services/google_auth_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:allomom/features/auth/register_flow/register_status_page.dart';
import 'package:allomom/features/auth/register_flow/dad_family_setup_page.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class RegisterNamePage extends StatefulWidget {
  final String phone;
  final String countryCode;
  final String selectedLanguage;
  final String selectedRole;

  const RegisterNamePage({
    super.key,
    this.phone = '9876543210',
    this.countryCode = '+91',
    this.selectedLanguage = 'en',
    this.selectedRole = 'Mom',
  });

  @override
  State<RegisterNamePage> createState() => _RegisterNamePageState();
}

class _RegisterNamePageState extends State<RegisterNamePage> {
  AppPalette get _p => context.palette;

  final TextEditingController _nameController = TextEditingController();

  /// What Google gave back, shown under the field so she can see which account
  /// filled it in. Null until she picks one — or forever, if she dismisses the
  /// sheet.
  String? _googleEmail;
  String? _googlePhotoUrl;

  /// Who is being asked. Mom and Dad get different recordings, so the opening
  /// line is chosen from the role she picked a screen ago rather than being
  /// one neutral prompt for both.
  late String _narrationKey = _isDad
      ? NarrationKeys.onbNamePromptDad
      : NarrationKeys.onbNamePromptMom;

  bool get _isDad => widget.selectedRole.trim().toLowerCase() == 'dad';

  void _say(String key) {
    if (!mounted) return;
    setState(() => _narrationKey = key);
    if (BackgroundAudioController.isReady) {
      BackgroundAudioController.to.playByKey(key, force: true);
    }
  }

  @override
  void initState() {
    super.initState();
    // After the first frame, so the card and its narration are on screen
    // behind the account sheet rather than appearing once it is dismissed.
    WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromGoogle());
  }

  /// Offers the Google account picker and fills the profile from whatever she
  /// chooses.
  ///
  /// Dismissing the sheet is a normal answer, not a failure: `signIn` returns
  /// null and this returns quietly, leaving her to type the name herself. The
  /// same goes for a sign-in that errors — an account she never asked to use
  /// is not worth a snackbar over a field she can fill in by hand.
  Future<void> _prefillFromGoogle() async {
    final GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signIn();
    } catch (_) {
      return;
    }
    if (account == null || !mounted) return;

    final name = account.displayName?.trim() ?? '';
    final email = account.email.trim();
    final photoUrl = account.photoUrl;

    setState(() {
      // Only when the field is untouched: she may have started typing while
      // the sheet was up, and her own name wins over Google's.
      if (name.isNotEmpty && _nameController.text.trim().isEmpty) {
        _nameController.text = name;
      }
      _googleEmail = email.isEmpty ? null : email;
      _googlePhotoUrl = photoUrl;
    });

    // The account already exists — it was created when the OTP was verified —
    // so the email and picture are saved now rather than carried through the
    // rest of the flow. `updateProfile` writes locally first and queues the
    // push, so this survives a bad connection. The name is left to the flow's
    // own save, which is what she confirms with Next.
    final changes = <String, dynamic>{
      if (_googleEmail != null) 'email': _googleEmail,
      if (_googlePhotoUrl != null) 'profile_picture': _googlePhotoUrl,
    };
    if (changes.isNotEmpty) {
      await MainController.instance.updateProfile(changes);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
                              'Enter Name',
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
                        text: 'You have such a lovely name! 💕',
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
                        children: [
                          Text(
                            'FULL NAME',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _p.pick(const Color(0xFF8E95A5), _p.textMuted),
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Name Input Field
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _p.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _p.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFFFF4E6A),
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _nameController,
                                    style: GoogleFonts.poppins(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w600,
                                      color: _p.pick(const Color(0xFF1E2024), _p.textPrimary),
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Tamilselvi',
                                      hintStyle: GoogleFonts.poppins(
                                        color: _p.pick(const Color(0xFF9CA3AF), _p.textMuted),
                                        fontSize: 15,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ─── GOOGLE ACCOUNT CHIP ───
                          // Only once an account has been picked. It is the
                          // receipt for the email and picture, which are saved
                          // but have no field of their own on this screen.
                          if (_googleEmail != null) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: _p.tint(const Color(0xFFFF4E6A), const Color(0xFFFDE7EC)),
                                  backgroundImage: _googlePhotoUrl == null
                                      ? null
                                      : NetworkImage(_googlePhotoUrl!),
                                  child: _googlePhotoUrl != null
                                      ? null
                                      : const Icon(
                                          Icons.person_rounded,
                                          size: 16,
                                          color: Color(0xFFFF4E6A),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _googleEmail!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: _p.pick(const Color(0xFF6B7280), _p.textSecondary),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 22),

                          // ─── NEXT BUTTON ───
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () {
                                final name = _nameController.text.trim();
                                if (name.isNotEmpty) {
                                  // Plays over the transition; `_say` would
                                  // bind it to a card that is about to go.
                                  speak(
                                    NarrationKeys.onbNameReaction,
                                    force: true,
                                  );
                                  if (_isDad) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DadFamilySetupPage(
                                          userName: name,
                                          phone: widget.phone,
                                          countryCode: widget.countryCode,
                                          selectedLanguage:
                                              widget.selectedLanguage,
                                          selectedRole: widget.selectedRole,
                                        ),
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => RegisterStatusPage(
                                          userName: name,
                                          phone: widget.phone,
                                          countryCode: widget.countryCode,
                                          selectedLanguage:
                                              widget.selectedLanguage,
                                          selectedRole: widget.selectedRole,
                                        ),
                                      ),
                                    );
                                  }
                                } else {
                                  _say(NarrationKeys.onbNameEmpty);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter your name'),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF5277),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      'Next',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
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
                        ],
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
