import 'package:flutter/material.dart';
import 'package:allomom/components/app_backdrop.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/language_selector.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/reminders/reminders_page.dart';
import 'package:allomom/features/settings/edit_profile_page.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/services/app_language.dart';

/// The app bar every main screen wears: the product name on the left, and the
/// three things she reaches for from anywhere — her language, what the app has
/// been telling her, and her own profile.
///
/// A [PreferredSizeWidget], so it drops straight into `Scaffold.appBar`.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Shown on the left. Defaults to the product name.
  final String title;

  /// How many unread notifications to mark the bell with. Zero hides the dot.
  final int notificationCount;

  /// Overrides for the three actions. Each falls back to its default screen.
  final VoidCallback? onLanguageTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const CustomAppBar({
    super.key,
    this.title = 'Allomom',
    this.notificationCount = 0,
    this.onLanguageTap,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  static const double _height = 64;

  @override
  Size get preferredSize => const Size.fromHeight(_height);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Material(
      color: AppBackdrop.scaffoldColor(context, palette.background),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: _height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.afacadFlux(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    color: palette.textPrimary,
                  ),
                ),
                const Spacer(),

                // ─── LANGUAGE ───
                _IconAction(
                  icon: Icons.translate,
                  tooltip: 'Language',
                  onTap: onLanguageTap ?? () => _openLanguagePicker(context),
                ),
                const SizedBox(width: 6),

                // ─── NOTIFICATIONS ───
                _IconAction(
                  icon: Icons.notifications_none_rounded,
                  tooltip: 'Notifications',
                  badge: notificationCount > 0,
                  onTap:
                      onNotificationsTap ?? () => _openNotifications(context),
                ),
                const SizedBox(width: 6),

                // ─── PROFILE ───
                GestureDetector(
                  onTap: onProfileTap ?? () => _openProfile(context),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The same picker Settings shows, reachable without leaving the screen she
  /// is on. Unlike Settings', this one persists the choice: the sheet is the
  /// only place some mothers will ever change it.
  void _openLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
        decoration: BoxDecoration(
          color: ctx.palette.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            LanguageSelector(
              initialAppLanguage: AppLanguage.cachedOrFallback,
              initialSpeechLanguage: AppLanguage.cachedOrFallback,
              // Saves it and moves AlloBot's catalogue with it, so her
              // settings page shows the same language.
              onAppLanguageChanged:
                  OfflineChatbotController.instance.applyAppLanguage,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RemindersPage()),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EditProfilePage()),
    );
  }
}

/// One of the two outline icons, with the unread dot the bell sometimes needs.
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool badge;
  final VoidCallback onTap;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 24,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(icon, size: 26, color: context.palette.textPrimary),
              if (badge)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: context.palette.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
