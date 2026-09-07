import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/contact_number_page.dart';
import 'package:allomom/features/settings/edit_profile_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/components/language_selector.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/features/pregnancy/test_pregnancy_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // ─── TITLE ───
                  Text(
                    'Settings',
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ─── CONTACT PROFILE CARD ───
                  _buildContactCard(
                    context,
                    session,
                    isPregnant,
                    gestationalWeek,
                    trimester,
                  ),
                  const SizedBox(height: 24),

                  // ─── SECTION 1: PROFILE & CARE CIRCLE ───
                  _buildSectionHeader('Profile & Care Circle'),
                  _buildCardGroup([
                    _buildSettingsItem(
                      icon: Icons.person_outline_rounded,
                      iconBg: const Color(0xFFFFECEF),
                      iconColor: const Color(0xFFFF4E6A),
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
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.favorite_outline_rounded,
                      iconBg: const Color(0xFFFFECEF),
                      iconColor: const Color(0xFFFF4E6A),
                      title: 'Pregnancy Timeline & Due Date',
                      subtitle: isPregnant
                          ? 'Week $gestationalWeek · $trimester (Due: ${session.formattedEddDateFull})'
                          : session.isNewMom
                          ? 'Journey complete · register a new pregnancy'
                          : 'Update pregnancy status & LMP',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PregnancyConfirmationPage(),
                          ),
                        );
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.group_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF3B82F6),
                      title: 'My Family & Care Circle',
                      subtitle:
                          session.partnerName != null &&
                              session.partnerName!.isNotEmpty
                          ? '${session.partnerName} · Care circle active'
                          : 'Invite partner & family caregivers',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PeoplePage()),
                        );
                      },
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ─── SECTION 2: WEARABLE & HARDWARE ───
                  _buildSectionHeader('Wearables & Allowear'),
                  _buildCardGroup([
                    _buildSettingsItem(
                      icon: Icons.watch_outlined,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      title: 'Allowear Smart Band',
                      subtitle:
                          session.allowearMacAddress != null &&
                              session.allowearMacAddress!.isNotEmpty
                          ? 'Paired: ${session.allowearMacAddress}'
                          : 'Connect Bluetooth smart band for vitals',
                      onTap: () => _showAllowearDialog(context, session),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ─── SECTION 3: PREFERENCES & ALERTS ───
                  _buildSectionHeader('Preferences & Alerts'),
                  _buildCardGroup([
                    _buildSettingsItem(
                      icon: Icons.translate_rounded,
                      iconBg: const Color(0xFFFEF3C7),
                      iconColor: const Color(0xFFD97706),
                      title: 'Language',
                      subtitle: 'English · Baby Voice: தமிழ்',
                      onTap: () => _showLanguagePickerModal(context),
                    ),
                    _buildDivider(),
                    _buildSwitchSettingsItem(
                      icon: Icons.notifications_none_rounded,
                      iconBg: const Color(0xFFE0F2FE),
                      iconColor: const Color(0xFF0284C7),
                      title: 'Push Notifications',
                      subtitle: 'Daily maternal tips & appointment alerts',
                      value: _notificationsEnabled,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.access_time_rounded,
                      iconBg: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFEF4444),
                      title: 'Daily Reminders',
                      subtitle: 'Medicine & nutrition voice alerts',
                      onTap: () => _showRemindersModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.volume_up_outlined,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Accessibility & Voice',
                      subtitle: 'Voice speed, speech volume & text size',
                      onTap: () => _showAccessibilityModal(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ─── SECTION 4: HELP & LEGAL ───
                  _buildSectionHeader('Help & Legal'),
                  _buildCardGroup([
                    _buildSettingsItem(
                      icon: Icons.help_outline_rounded,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF475569),
                      title: 'Help & FAQ',
                      subtitle: 'Maternal health guide & support hotline',
                      onTap: () => _showHelpModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.verified_user_outlined,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF475569),
                      title: 'Terms & Privacy Policy',
                      subtitle: 'HIPAA & data protection compliance',
                      onTap: () => _showPrivacyPolicyModal(context),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.info_outline_rounded,
                      iconBg: const Color(0xFFF1F5F9),
                      iconColor: const Color(0xFF475569),
                      title: 'App Info',
                      subtitle: 'Version 1.0.4 (Build 2026)',
                      onTap: () => _showAppInfoDialog(context),
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ─── SECTION 4b: DEVELOPER (debug builds only) ───
                  if (kDebugMode) ...[
                    _buildSectionHeader('Developer'),
                    _buildCardGroup([
                      _buildSettingsItem(
                        icon: Icons.storage_rounded,
                        iconBg: const Color(0xFFEDE9FE),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Test Pregnancy · Local DB',
                        subtitle: 'CRUD harness for ANC, vaccines & reports',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TestPregnancyPage(),
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),
                  ],

                  // ─── SECTION 5: LOGOUT ───
                  _buildCardGroup([
                    _buildSettingsItem(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFFFECEF),
                      iconColor: const Color(0xFFFF4E6A),
                      title: 'Log out',
                      subtitle: 'Sign out of your AlloMom account',
                      isLogout: true,
                      onTap: () => _showLogoutConfirmation(context),
                    ),
                  ]),

                  const SizedBox(height: 100),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── CONTACT PROFILE CARD ───
  Widget _buildContactCard(
    BuildContext context,
    UserSessionManager session,
    bool isPregnant,
    int week,
    String trimester,
  ) {
    final name = session.userName;
    final contact = session.userPhone.isNotEmpty
        ? session.userPhone
        : (session.userEmail.isNotEmpty ? session.userEmail : 'AlloMom Member');
    final avatarUrl = session.image;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4E6A).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Circular Avatar
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFF4E6A), width: 2),
            ),
            child: ClipOval(
              child: Container(
                width: 60,
                height: 60,
                color: const Color(0xFFFDECEF),
                child: avatarUrl != null && avatarUrl.isNotEmpty
                    ? Image.network(
                        avatarUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.face_3_rounded,
                          size: 38,
                          color: Color(0xFFFF4E6A),
                        ),
                      )
                    : Image.asset(
                        'assets/allobaby/woman.png',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.face_3_rounded,
                          size: 38,
                          color: Color(0xFFFF4E6A),
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name, Details & Status Chip
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 18.5,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E2024),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  contact,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: const Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFECEF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isPregnant
                            ? 'Week $week · $trimester'
                            : session.isNewMom
                            ? 'New mom'
                            : 'Maternal Journey',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4E6A),
                        ),
                      ),
                    ),
                    if (isPregnant)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.event_available_rounded,
                              size: 12,
                              color: Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Due: ${session.formattedEddDate}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Edit Profile Button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6F7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF3D5DC)),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 20,
                color: Color(0xFFFF4E6A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 12.5,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF9CA3AF),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildCardGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 56, right: 16),
      child: Divider(height: 1, color: Colors.grey.shade100),
    );
  }

  // ─── SETTINGS ITEM ROW ───
  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Icon with colored badge background
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 14),

              // Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: isLogout
                            ? const Color(0xFFFF4E6A)
                            : const Color(0xFF1E2024),
                      ),
                    ),
                    const SizedBox(height: 1.5),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isLogout
                    ? const Color(0xFFFF4E6A)
                    : const Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── SWITCH SETTINGS ITEM ROW ───
  Widget _buildSwitchSettingsItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E2024),
                  ),
                ),
                const SizedBox(height: 1.5),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFFFF5277),
            onChanged: onChanged,
          ),
        ],
      ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.watch_rounded, color: Color(0xFFFF4E6A)),
            const SizedBox(width: 8),
            Text(
              'Allowear Band',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your Allowear Smart Band MAC address to enable continuous vital streaming:',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: macController,
              decoration: InputDecoration(
                labelText: 'MAC Address',
                hintText: 'AA:BB:CC:11:22:33',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
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
                  backgroundColor: Color(0xFFFF4E6A),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4E6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.poppins(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accessibility',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Baby voice speech rate, haptic feedback, and text size scaling for comfortable maternal experience.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Help & Support',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Need urgent pregnancy guidance or technical assistance? AlloMom support is here 24/7.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(
                  Icons.phone_in_talk_rounded,
                  color: Color(0xFFFF4E6A),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'Support Helpline: 1800-SAVEMOM',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFFF4E6A),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'support@savemom.app',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Terms',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your maternal vitals and medical data are end-to-end encrypted and safeguarded with strict clinical standards.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: Color(0xFFFF4E6A)),
            const SizedBox(width: 8),
            Text(
              'AlloMom Maternal Care',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version: 1.0.4 (Build 2026)',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SaveMom AlloConnect Ecosystem',
              style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              '© 2026 SaveMom Healthcare Technologies. All rights reserved.',
              style: GoogleFonts.poppins(fontSize: 11.5, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: GoogleFonts.poppins(
                color: const Color(0xFFFF4E6A),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Log out of AlloMom?',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to log out from this device?',
          style: GoogleFonts.poppins(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
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
              backgroundColor: const Color(0xFFFF4E6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Log out',
              style: GoogleFonts.poppins(
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
