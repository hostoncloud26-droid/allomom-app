import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/settings/edit_profile_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/components/language_selector.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/features/baby/my_babies_page.dart';
import 'package:allomom/features/pregnancy/test_pregnancy_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  // AlloMom Theme Color Palette from config/colors.dart
  static const Color _bgTheme = Colors.white;
  static const Color _accentPrimary = primaryColor;
  static const Color _textDark = textDark;
  static const Color _textMuted = textMuted;
  static const Color _textSecondary = textMedium;
  static const Color _dividerTheme = dividerColor;
  static const Color _itemDivider = Color(0xFFF4EBED);
  static const Color _logoutRed = dangerRed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgTheme,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: UserSessionManager.instance,
          builder: (context, _) {
            final session = UserSessionManager.instance;
            final isPregnant = session.isPregnant;
            final gestationalWeek = session.currentGestationalWeek;
            final trimester = session.currentTrimester;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── TOP APP BAR ───
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        // Top Right App Badge
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            border: Border.all(
                              color: accentColor.withValues(alpha: 0.6),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _accentPrimary.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.verified_user_rounded,
                              color: _accentPrimary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

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
                  const Divider(height: 1, thickness: 1, color: _dividerTheme),
                  const SizedBox(height: 6),

                  // ─── FLAT SETTINGS LIST ───
                  // 1. Edit Profile
                  _buildListTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Profile',
                    subtitle: 'Personal info, address & pregnancy details',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EditProfilePage(),
                        ),
                      );
                    },
                  ),
                  _buildItemDivider(),

                  // 2. Pregnancy Timeline & Due Date
                  _buildListTile(
                    icon: Icons.calendar_today_outlined,
                    title: 'Pregnancy Timeline & Due Date',
                    subtitle: isPregnant
                        ? 'Week $gestationalWeek · $trimester'
                        : session.isNewMom
                            ? 'New Mom Journey'
                            : 'Update status & LMP',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PregnancyConfirmationPage(),
                        ),
                      );
                    },
                  ),
                  _buildItemDivider(),

                  // 2b. My Babies
                  _buildListTile(
                    icon: Icons.child_care_outlined,
                    title: 'My Babies',
                    subtitle: session.hasKids
                        ? '${session.kidsCount} '
                              '${session.kidsCount == 1 ? 'baby' : 'babies'} '
                              '· Vaccines & milestones'
                        : 'Add your newborn or older child',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyBabiesPage()),
                      );
                      if (mounted) setState(() {});
                    },
                  ),
                  _buildItemDivider(),

                  // 3. Family & Care Circle
                  _buildListTile(
                    icon: Icons.group_outlined,
                    title: 'Family & Care Circle',
                    subtitle: session.partnerName != null &&
                            session.partnerName!.isNotEmpty
                        ? '${session.partnerName} · Connected'
                        : 'Invite partner & family',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PeoplePage()),
                      );
                    },
                  ),
                  _buildItemDivider(),

                  // 4. Allowear Smart Band
                  _buildListTile(
                    icon: Icons.watch_outlined,
                    title: 'Allowear Smart Band',
                    subtitle: session.allowearMacAddress != null &&
                            session.allowearMacAddress!.isNotEmpty
                        ? 'Paired: ${session.allowearMacAddress}'
                        : 'Connect Bluetooth vitals band',
                    onTap: () => _showAllowearDialog(context, session),
                  ),
                  _buildItemDivider(),

                  // 5. Language
                  _buildListTile(
                    icon: Icons.translate_rounded,
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () => _showLanguagePickerModal(context),
                  ),
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

                  // 7. Reminders
                  _buildListTile(
                    icon: Icons.alarm_rounded,
                    title: 'Reminders',
                    subtitle: 'Medicine & nutrition alerts',
                    onTap: () => _showRemindersModal(context),
                  ),
                  _buildItemDivider(),

                  // 8. Accessibility & Voice
                  _buildListTile(
                    icon: Icons.volume_up_outlined,
                    title: 'Accessibility & Voice',
                    subtitle: 'Speech speed & voice volume',
                    onTap: () => _showAccessibilityModal(context),
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

                  // 12. Developer (Debug Builds Only)
                  if (kDebugMode) ...[
                    _buildItemDivider(),
                    _buildListTile(
                      icon: Icons.storage_rounded,
                      title: 'Test Pregnancy · Local DB',
                      subtitle: 'Developer test harness',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TestPregnancyPage(),
                          ),
                        );
                      },
                    ),
                  ],

                  _buildItemDivider(),

                  // 13. Log out
                  _buildListTile(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    isLogout: true,
                    onTap: () => _showLogoutConfirmation(context),
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
    UserSessionManager session,
    bool isPregnant,
    int week,
    String trimester,
  ) {
    final name = session.userName.isNotEmpty ? session.userName : 'Mommy';
    final contact = session.userEmail.isNotEmpty
        ? session.userEmail
        : (session.userPhone.isNotEmpty ? session.userPhone : 'deekshaveeramanikandan@gmail.com');
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
                border: Border.all(
                  color: _accentPrimary,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: Container(
                  width: 66,
                  height: 66,
                  color: accentLight,
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
                    style: const TextStyle(
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
                      const Icon(
                        Icons.mail_outline_rounded,
                        size: 15,
                        color: _textMuted,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          contact,
                          style: const TextStyle(
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
                        color: accentLight,
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
                        style: const TextStyle(
                          fontSize: 12,
                          color: _textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: isLogout ? _logoutRed : const Color(0xFF9CA3AF),
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
          Icon(
            icon,
            size: 24,
            color: _accentPrimary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
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
    return const Divider(
      height: 1,
      thickness: 0.8,
      color: _itemDivider,
      indent: 50,
      endIndent: 8,
    );
  }

  // ─── MODALS & DIALOGS ───

  void _showAllowearDialog(BuildContext context, UserSessionManager session) {
    final macController = TextEditingController(
      text: session.allowearMacAddress ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.watch_rounded, color: _accentPrimary),
            SizedBox(width: 10),
            Text(
              'Allowear Band',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Allowear Smart Band MAC address to enable continuous maternal vital streaming:',
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: macController,
              style: const TextStyle(color: _textDark),
              decoration: InputDecoration(
                labelText: 'MAC Address',
                labelStyle: const TextStyle(color: _textMuted),
                hintText: 'AA:BB:CC:11:22:33',
                hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _accentPrimary, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await session.updateProfile(
                allowearMacAddress: macController.text.trim(),
              );
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
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  color: Colors.grey.shade300,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Column(
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
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Column(
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
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
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
                Icon(
                  Icons.email_outlined,
                  color: _accentPrimary,
                  size: 20,
                ),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: const Column(
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
              style: TextStyle(
                fontSize: 13,
                color: _textSecondary,
              ),
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: _accentPrimary),
            SizedBox(width: 10),
            Text(
              'AlloMom Maternal Care',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _textDark,
              ),
            ),
          ],
        ),
        content: const Column(
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Log out of AlloMom?',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _textDark,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out from this device?',
          style: TextStyle(
            fontSize: 13,
            color: _textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserSessionManager.instance.logout();
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
}
