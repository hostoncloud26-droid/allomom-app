import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/features/auth/language_selection_page.dart';
import 'package:allomom/repositories/user_session_manager.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_registration/pregnancy_confirmation_page.dart';
import 'package:allomom/components/language_selector.dart';

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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              const SizedBox(height: 20),

              // ─── PROFILE HEADER ───
              _buildProfileHeader(context),
              const SizedBox(height: 24),

              // ─── SETTINGS ITEMS LIST ───
              _buildSettingsItem(
                icon: Icons.edit_outlined,
                title: 'Edit profile',
                subtitle: 'Name, photo, due date',
                onTap: () => _showEditProfileBottomSheet(context),
              ),
              _buildSettingsItem(
                icon: Icons.translate_rounded,
                title: 'Language',
                subtitle: 'English · Voice: தமிழ்',
                onTap: () => _showLanguagePickerModal(context),
              ),
              _buildSettingsItem(
                icon: Icons.group_outlined,
                title: 'My family',
                subtitle: 'Appa joined · 1 more invited',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PeoplePage()),
                  );
                },
              ),
              _buildSwitchSettingsItem(
                icon: Icons.notifications_none_rounded,
                title: 'Notifications',
                subtitle: 'Baby voice reminders on',
                value: _notificationsEnabled,
                onChanged: (val) {
                  setState(() {
                    _notificationsEnabled = val;
                  });
                },
              ),
              _buildSettingsItem(
                icon: Icons.access_time_rounded,
                title: 'Reminders',
                subtitle: 'Baby voice, twice a day',
                onTap: () => _showRemindersModal(context),
              ),
              _buildSettingsItem(
                icon: Icons.volume_up_outlined,
                title: 'Accessibility',
                subtitle: 'Bigger text and slower voice',
                onTap: () => _showAccessibilityModal(context),
              ),
              _buildSettingsItem(
                icon: Icons.sd_storage_outlined,
                title: 'Keep on phone',
                subtitle: '38 MB downloaded',
                onTap: () => _showStorageModal(context),
              ),
              _buildSettingsItem(
                icon: Icons.verified_user_outlined,
                title: 'Terms and privacy',
                subtitle: 'How we keep your data',
                onTap: () => _showPrivacyPolicyModal(context),
              ),
              _buildSettingsItem(
                icon: Icons.info_outline_rounded,
                title: 'App info',
                subtitle: 'Version 1.0.4 (Build 2026)',
                onTap: () => _showAppInfoDialog(context),
              ),
              _buildSettingsItem(
                icon: Icons.logout_rounded,
                title: 'Logout',
                subtitle: 'Sign out of AlloMom account',
                isLogout: true,
                onTap: () => _showLogoutConfirmation(context),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  // ─── PROFILE HEADER ───
  Widget _buildProfileHeader(BuildContext context) {
    return Row(
      children: [
        // Circular Avatar with pink ring
        Container(
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFFF4E6A),
              width: 1.8,
            ),
          ),
          child: ClipOval(
            child: Container(
              width: 58,
              height: 58,
              color: const Color(0xFFFDECEF),
              child: Image.asset(
                'assets/allobaby/woman.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.face_3_rounded,
                    size: 38,
                    color: const Color(0xFFFF4E6A).withValues(alpha: 0.9),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Name & Email
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Mom',
                style: GoogleFonts.outfit(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E2024),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 14,
                    color: Color(0xFF7A7E85),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'mom@allomom.app',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: const Color(0xFF7A7E85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── SETTINGS ITEM ROW ───
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              children: [
                // Icon
                Icon(
                  icon,
                  size: 22,
                  color: isLogout
                      ? const Color(0xFFFF4E6A)
                      : const Color(0xFF2C3038),
                ),
                const SizedBox(width: 16),

                // Title & Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isLogout
                              ? const Color(0xFFFF4E6A)
                              : const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: const Color(0xFF8E95A5),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isLogout
                      ? const Color(0xFFFF4E6A)
                      : const Color(0xFFB0B5C0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── SWITCH SETTINGS ITEM ROW ───
  Widget _buildSwitchSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // Icon
            Icon(
              icon,
              size: 22,
              color: const Color(0xFF2C3038),
            ),
            const SizedBox(width: 16),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E2024),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),

            // Coral/Pink Switch
            CupertinoSwitch(
              value: value,
              activeTrackColor: const Color(0xFFFF5277),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  // ─── MODALS & ACTIONS ───

  void _showEditProfileBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const SizedBox(height: 18),
            Text(
              'Edit Profile',
              style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Display Name',
                hintText: 'Mom',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email Address',
                hintText: 'mom@allomom.app',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.child_care_rounded, color: Color(0xFFFF4E6A)),
              title: Text('Pregnancy Due Date & Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PregnancyConfirmationPage()),
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile updated successfully!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5277),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('Save Changes', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Reminder Frequency', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Twice a day (Morning & Evening)'),
              trailing: const Icon(Icons.check, color: Color(0xFFFF4E6A)),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Once a day (Morning)'),
              onTap: () => Navigator.pop(ctx),
            ),
            ListTile(
              title: const Text('Custom interval'),
              onTap: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  void _showAccessibilityModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Accessibility', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Customize text size, high contrast mode, and baby voice speech rate to your preference.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF5A5D64), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showStorageModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Offline Storage', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloaded audio voices & guides: 38 MB', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 8),
            Text('All essential maternal tracking tools remain accessible offline.', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache cleared.')),
              );
            },
            child: Text('Clear Cache', style: GoogleFonts.poppins(color: Colors.red, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Done', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Terms & Privacy', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Your pregnancy data and medical vitals are end-to-end encrypted and strictly confidential according to health privacy standards.',
          style: GoogleFonts.poppins(fontSize: 13.5, color: const Color(0xFF5A5D64), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Close', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAppInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('AlloMom App', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: 1.0.4 (Build 2026)', style: GoogleFonts.poppins(fontSize: 14)),
            const SizedBox(height: 4),
            Text('Designed with love for mothers & babies.', style: GoogleFonts.poppins(fontSize: 12.5, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: GoogleFonts.poppins(color: const Color(0xFFFF4E6A), fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Logout from AlloMom?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to sign out of your account on this device?',
          style: GoogleFonts.poppins(fontSize: 14, color: const Color(0xFF5A5D64)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.poppins(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4E6A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await UserSessionManager.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
                  (route) => false,
                );
              }
            },
            child: Text('Logout', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
