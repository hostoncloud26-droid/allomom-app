import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/theme_controller.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/features/auth/register_flow/dad_family_setup_page.dart';
import 'package:allomom/features/settings/edit_profile_page.dart';
import 'package:allomom/features/settings/hospital/my_hospitals_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/components/language_selector.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:get/get.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => speak(NarrationKeys.pgSettingsOpen),
    );
  }

  // AlloMom Theme Color Palette from config/colors.dart
  // Brand colours stay fixed; surfaces and text follow light / dark mode.
  static const Color _accentPrimary = primaryColor;
  static const Color _logoutRed = dangerRed;
  Color get _bgTheme => context.palette.background;
  Color get _cardTheme => context.palette.card;
  Color get _textDark => context.palette.textPrimary;
  Color get _textMuted => context.palette.textMuted;
  Color get _textSecondary => context.palette.textSecondary;
  Color get _dividerTheme => context.palette.divider;
  Color get _itemDivider =>
      context.isDarkMode ? context.palette.divider : const Color(0xFFF4EBED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTheme,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: MainController.instance,
          builder: (context, _) {
            final session = MainController.instance;
            final isPregnant = session.isPregnant;
            final gestationalWeek = session.currentGestationalWeek;
            final trimester = session.currentTrimester;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── PROFILE HEADER (FLAT, NO CARD WRAPPER) ───
                  _buildProfileHeader(
                    context,
                    session,
                    isPregnant,
                    gestationalWeek,
                    trimester,
                  ),
                  const SizedBox(height: 12),

                  // ─── SUBTLE SECTION DIVIDER ───
                  Divider(height: 1, thickness: 1, color: _dividerTheme),
                  const SizedBox(height: 6),

                  // ─── FLAT SETTINGS LIST ───
                  // 1. Edit Profile
                  _buildListTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Personal info, address & pregnancy details',
                    onTap: () {
                      speak(NarrationKeys.pgSettingsProfile);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildItemDivider(),

                  _buildListTile(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Family Group',
                    subtitle: 'Family code, join or leave a family',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DadFamilySetupPage(
                            userName: session.userName,
                            phone: session.userPhone,
                            countryCode: session.countryCode,
                            selectedRole:
                                session.gender.trim().toLowerCase() == 'male'
                                ? 'Dad'
                                : 'Mom',
                          ),
                        ),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  _buildItemDivider(),

                  _buildListTile(
                    icon: Icons.local_hospital_outlined,
                    title: 'My Hospital',
                    subtitle: 'Add, leave or remove your hospital',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MyHospitalsPage(),
                      ),
                    ),
                  ),
                  _buildItemDivider(),

                  // 5. Language
                  _buildListTile(
                    icon: Icons.translate_rounded,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () {
                      speak(NarrationKeys.pgSettingsLanguage);
                      _showLanguagePickerModal(context);
                    },
                  ),
                  _buildItemDivider(),

                  // 5b. Theme — light, dark, or follow the phone.
                  Obx(() {
                    final theme = ThemeController.instance;
                    return _buildListTile(
                      icon: theme.themeModeIcon,
                      title: 'Theme',
                      subtitle: '${theme.themeModeLabel} mode',
                      onTap: () => _showThemePickerModal(context),
                    );
                  }),
                  _buildItemDivider(),

                  // 6. Notifications (Switch Toggle)
                  _buildSwitchTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: _notificationsEnabled
                        ? 'Enabled · Real-time alerts & tips'
                        : 'Disabled',
                    isSubtitleAccent: _notificationsEnabled,
                    value: _notificationsEnabled,
                    onChanged: (val) {
                      setState(() => _notificationsEnabled = val);
                    },
                  ),
                  _buildItemDivider(),

                  // 6b. Baby's voice (Switch Toggle)
                  //
                  // The one control over the background audio: off means the
                  // baby stops speaking everywhere, and the speech bubbles keep
                  // showing her lines in text. Persisted, so it stays off.
                  if (BackgroundAudioController.isReady) ...[
                    Obx(() {
                      final enabled =
                          BackgroundAudioController.to.isVoiceEnabled.value;
                      return _buildSwitchTile(
                        icon: Icons.record_voice_over_outlined,
                        title: "Baby's voice",
                        subtitle: enabled
                            ? 'On · I read every screen out to you'
                            : 'Off · You will still see what I say',
                        isSubtitleAccent: enabled,
                        value: enabled,
                        onChanged: BackgroundAudioController.to.setVoiceEnabled,
                      );
                    }),
                    _buildItemDivider(),
                  ],

                  // 7. Reminders
                  _buildListTile(
                    icon: Icons.alarm_rounded,
                    title: 'Reminders',
                    subtitle: 'Medicine & nutrition alerts',
                    onTap: () => _showRemindersModal(context),
                  ),
                  _buildItemDivider(),

                  // 9. Help & Support
                  _buildListTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () => _showHelpModal(context),
                  ),
                  _buildItemDivider(),

                  // 10. Terms & Privacy Policy
                  _buildListTile(
                    icon: Icons.description_outlined,
                    title: 'Terms & Privacy Policy',
                    onTap: () => _showPrivacyPolicyModal(context),
                  ),
                  _buildItemDivider(),

                  // 11. App Info
                  _buildListTile(
                    icon: Icons.info_outline_rounded,
                    title: 'App Info',
                    subtitle: 'Version 1.0.4 (Build 2026)',
                    onTap: () => _showAppInfoDialog(context),
                  ),

                  _buildItemDivider(),

                  // 13. Log out
                  _buildListTile(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    isLogout: true,
                    onTap: () => _showLogoutConfirmation(context),
                  ),
                  _buildItemDivider(),

                  // 14. Delete account
                  _buildListTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete account',
                    subtitle: 'Permanently remove your account and data',
                    isLogout: true,
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── PROFILE HEADER (FLAT / NO CARD WRAPPER) ───
  Widget _buildProfileHeader(
    BuildContext context,
    MainController session,
    bool isPregnant,
    int week,
    String trimester,
  ) {
    final name = session.userName.isNotEmpty ? session.userName : 'Mommy';
    final contact = session.userEmail.isNotEmpty
        ? session.userEmail
        : (session.userPhone.isNotEmpty
              ? session.userPhone
              : 'deekshaveeramanikandan@gmail.com');
    final avatarUrl = session.image;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EditProfilePage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Row(
          children: [
            // Circular Avatar
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _accentPrimary, width: 2),
              ),
              child: ClipOval(
                child: Container(
                  width: 66,
                  height: 66,
                  color: context.palette.accentSoft,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(
                          avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: _accentPrimary,
                          ),
                        )
                      : Image.asset(
                          'assets/allobaby/woman.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: _accentPrimary,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 16),

            // User Name & Email / Contact Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w700,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(
                        Icons.mail_outline_rounded,
                        size: 15,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: _textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (isPregnant || session.isNewMom) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: context.palette.accentSoft,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.8),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isPregnant
                            ? 'Week $week · $trimester'
                            : 'New Mom Journey',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _accentPrimary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FLAT SETTINGS LIST ROW ───
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: _accentPrimary.withValues(alpha: 0.08),
        highlightColor: _accentPrimary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: Row(
            children: [
              Icon(
                icon,
                size: 24,
                color: isLogout ? _logoutRed : _accentPrimary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w600,
                        color: isLogout ? _logoutRed : _textDark,
                      ),
                    ),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: _textMuted),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isLogout ? _logoutRed : _textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SWITCH SETTINGS ROW ───
  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isSubtitleAccent = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 24, color: _accentPrimary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSubtitleAccent ? _accentPrimary : _textMuted,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: _accentPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildItemDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: _itemDivider,
      indent: 50,
      endIndent: 8,
    );
  }

  // ─── MODALS & DIALOGS ───

  void _showAllowearDialog(BuildContext context, MainController session) {
    // Said as the field appears: the number is printed on the band and she may
    // have to go and find it.
    speak(NarrationKeys.pgSettingsBandMac);

    final macController = TextEditingController(
      text: session.allowearMacAddress ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardTheme,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.watch_rounded, color: _accentPrimary),
            SizedBox(width: 10),
            Text(
              'Allowear Band',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Allowear Smart Band MAC address to enable continuous maternal vital streaming:',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: macController,
              style: TextStyle(color: _textDark),
              decoration: InputDecoration(
                labelText: 'MAC Address',
                labelStyle: TextStyle(color: _textMuted),
                hintText: 'AA:BB:CC:11:22:33',
                hintStyle: TextStyle(color: _textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _dividerTheme),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _accentPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await session.setAllowearMacAddress(macController.text.trim());
              speakAll([
                NarrationKeys.pgConfBandSaved,
                NarrationKeys.pgSettingsBandOk,
              ], force: true);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Allowear settings saved!'),
                  backgroundColor: _accentPrimary,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _accentPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguagePickerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: _cardTheme,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _dividerTheme,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const LanguageSelector(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showThemePickerModal(BuildContext context) {
    const options = [
      (
        'light',
        'Light',
        'Bright screens for daytime',
        Icons.light_mode_rounded,
      ),
      ('dark', 'Dark', 'Easier on the eyes at night', Icons.dark_mode_rounded),
      (
        'system',
        'System',
        'Match your phone setting',
        Icons.brightness_auto_rounded,
      ),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
        decoration: BoxDecoration(
          color: ctx.palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Obx(() {
          final theme = ThemeController.instance;
          final selected = theme.themeMode.value;
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.palette.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: ctx.palette.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              for (final (value, label, hint, icon) in options)
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                  leading: Icon(icon, color: _accentPrimary),
                  title: Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: ctx.palette.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    hint,
                    style: TextStyle(
                      fontSize: 12,
                      color: ctx.palette.textMuted,
                    ),
                  ),
                  trailing: selected == value
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: _accentPrimary,
                        )
                      : null,
                  onTap: () {
                    theme.setThemeMode(value);
                    Navigator.pop(ctx);
                  },
                ),
            ],
          );
        }),
      ),
    );
  }

  void _showRemindersModal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemindersPage()),
    );
  }

  void _showAccessibilityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardTheme,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility & Voice',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 14),
            Text(
              'Baby voice speech rate, haptic feedback, and text scaling for comfortable maternal experience.',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showHelpModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardTheme,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Need urgent pregnancy guidance or technical assistance? AlloMom support is here 24/7.',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            SizedBox(height: 18),
            Row(
              children: [
                Icon(
                  Icons.phone_in_talk_rounded,
                  color: _accentPrimary,
                  size: 20,
                ),
                SizedBox(width: 10),
                Text(
                  'Support Helpline: 1800-SAVEMOM',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.email_outlined, color: _accentPrimary, size: 20),
                SizedBox(width: 10),
                Text(
                  'support@savemom.app',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _cardTheme,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Terms',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'Your maternal vitals and medical data are end-to-end encrypted and safeguarded with strict clinical standards.',
              style: TextStyle(fontSize: 13, color: _textSecondary),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardTheme,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _accentPrimary),
            SizedBox(width: 10),
            Text(
              'AlloMom Maternal Care',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.4 (Build 2026)',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: _textDark,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'SaveMom AlloConnect Ecosystem',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
            SizedBox(height: 6),
            Text(
              '© 2026 SaveMom Healthcare Technologies. All rights reserved.',
              style: TextStyle(fontSize: 11.5, color: _textMuted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Close',
              style: TextStyle(
                color: _accentPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cardTheme,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out of AlloMom?',
          style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
        ),
        content: Text(
          'Are you sure you want to log out from this device?',
          style: TextStyle(fontSize: 13, color: _textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: _textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthController.instance.logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const ContactNumberPage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _logoutRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Log out',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Deleting is for good, so she types DELETE before the button wakes up —
  /// a tap alone is too easy to make by accident on a row next to Log out.
  void _showDeleteAccountConfirmation(BuildContext context) {
    final confirm = TextEditingController();
    var deleting = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final armed = confirm.text.trim().toUpperCase() == 'DELETE';

          Future<void> delete() async {
            setDialogState(() {
              deleting = true;
              error = null;
            });
            final failure = await AuthController.instance.deleteAccount();
            if (failure != null) {
              if (ctx.mounted) {
                setDialogState(() {
                  deleting = false;
                  error = failure;
                });
              }
              return;
            }
            if (ctx.mounted) Navigator.pop(ctx);
            if (!context.mounted) return;
            // Back to where a fresh install starts: the phone no longer
            // remembers her language either.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Your account has been deleted.')),
            );
          }

          return AlertDialog(
            backgroundColor: _cardTheme,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              'Delete your account?',
              style: TextStyle(fontWeight: FontWeight.bold, color: _textDark),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'This permanently deletes your AlloMom account. It cannot '
                    'be undone.',
                    style: TextStyle(fontSize: 13, color: _textSecondary),
                  ),
                  const SizedBox(height: 10),
                  for (final line in const [
                    'Your profile and personal details',
                    'Your pregnancy and baby records',
                    'Your place in your family, on every device',
                    'Your sign-in on every device',
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(
                              Icons.remove_circle_outline_rounded,
                              size: 14,
                              color: _logoutRed,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              line,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: _textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Reports saved to your Google Drive stay in your Drive.',
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Type DELETE to confirm',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirm,
                    enabled: !deleting,
                    autocorrect: false,
                    textCapitalization: TextCapitalization.characters,
                    onChanged: (_) => setDialogState(() {}),
                    style: TextStyle(color: _textDark),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'DELETE',
                      hintStyle: TextStyle(color: _textMuted),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      error!,
                      style: const TextStyle(fontSize: 12, color: _logoutRed),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: deleting ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: TextStyle(color: _textMuted)),
              ),
              ElevatedButton(
                onPressed: armed && !deleting ? delete : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _logoutRed,
                  disabledBackgroundColor: _logoutRed.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: deleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    ).whenComplete(confirm.dispose);
  }
}
