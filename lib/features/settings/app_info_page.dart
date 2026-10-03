import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:allomom/features/auth/language_selection_page.dart';

class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  String _version = '';

  static const Color _logoutRed = dangerRed;
  static const Color _primary = primaryColor;

  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = info.version);
    });
  }

  void _onLogoTap() {
    final now = DateTime.now();
    if (_lastTapTime == null || now.difference(_lastTapTime!) > const Duration(seconds: 2)) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      _showAdminPasswordSheet();
    }
  }

  void _showAdminPasswordSheet() {
    final passwordController = TextEditingController();
    var hasError = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = sheetContext.palette.isDark;
        final sheetBg = isDark ? const Color(0xFF242424) : Colors.white;
        final textPrimary = sheetContext.palette.textPrimary;
        final textSecondary = sheetContext.palette.textSecondary;

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            void verifyAndProceed() {
              if (passwordController.text.trim() == 'savemom123') {
                Navigator.pop(sheetContext);
                _showDeleteAccountSheet();
              } else {
                setSheetState(() {
                  hasError = true;
                });
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                decoration: BoxDecoration(
                  color: sheetBg,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Admin Verification',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter password to access advanced settings',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      autofocus: true,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Password',
                        hintStyle: TextStyle(color: textSecondary),
                        errorText: hasError ? 'Incorrect password' : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF4A4A4A) : const Color(0xFFD1D5DB),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: _primary, width: 1.8),
                        ),
                      ),
                      onSubmitted: (_) => verifyAndProceed(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: textSecondary),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: verifyAndProceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Verify'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDeleteAccountSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = sheetContext.palette.isDark;
        final sheetBg = isDark ? const Color(0xFF242424) : Colors.white;
        final textPrimary = sheetContext.palette.textPrimary;
        final textSecondary = sheetContext.palette.textSecondary;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Account Options',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showDeleteAccountConfirmation(context);
                  },
                  borderRadius: BorderRadius.circular(14),
                  splashColor: _logoutRed.withValues(alpha: 0.08),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _logoutRed.withValues(alpha: 0.3),
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_forever_rounded,
                          size: 26,
                          color: _logoutRed,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Delete account',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w600,
                                  color: _logoutRed,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Permanently remove your account and data',
                                style: TextStyle(fontSize: 12, color: textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          size: 22,
                          color: _logoutRed,
                        ),
                      ],
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

  void _showDeleteAccountConfirmation(BuildContext context) {
    final confirm = TextEditingController();
    var deleting = false;
    String? error;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final isDark = ctx.palette.isDark;
        final dialogBg = isDark ? const Color(0xFF242424) : Colors.white;
        final textDark = ctx.palette.textPrimary;
        final textSecondary = ctx.palette.textSecondary;
        final textMuted = ctx.palette.textMuted;

        return StatefulBuilder(
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
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LanguageSelectionPage()),
                (route) => false,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Your account has been deleted.')),
              );
            }

            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                'Delete your account?',
                style: TextStyle(fontWeight: FontWeight.bold, color: textDark),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently deletes your AlloMom account. It cannot be undone.',
                      style: TextStyle(fontSize: 13, color: textSecondary),
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
                                  color: textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      'Reports saved to your Google Drive stay in your Drive.',
                      style: TextStyle(fontSize: 12, color: textMuted),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Type DELETE to confirm',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: confirm,
                      enabled: !deleting,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.characters,
                      onChanged: (_) => setDialogState(() {}),
                      style: TextStyle(color: textDark),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'DELETE',
                        hintStyle: TextStyle(color: textMuted),
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
                  child: Text('Cancel', style: TextStyle(color: textMuted)),
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
        );
      },
    ).whenComplete(confirm.dispose);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final bgColor = context.palette.background;
    final textPrimary = context.palette.textPrimary;
    final textSecondary = context.palette.textSecondary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: textPrimary,
            size: 26,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Info',
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // App Icon with ripple / tap detection
            Center(
              child: GestureDetector(
                onTap: _onLogoTap,
                child: ClipOval(
                  child: Container(
                    width: 120,
                    height: 120,
                    color: Colors.white,
                    child: Image.asset(
                      'assets/logo/allomomlogo_padded.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Version text in primary color
            Text(
              'Version : $_version',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _primary,
              ),
            ),

            const Spacer(flex: 4),

            // Footer branding
            Text(
              'from',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDark ? const Color(0xFF9E9E9E) : textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'SAVEMOM PRIVATE LIMITED',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? Colors.white : textPrimary,
              ),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
