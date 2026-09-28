import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/auth_controller.dart';
import 'package:get/get.dart';
import 'package:allomom/features/auth/language_selection_page.dart';

/// About AlloMom, and the one place to delete the account — kept off the main
/// settings list so it sits a screen away from Log out.
class AppInfoPage extends StatefulWidget {
  const AppInfoPage({super.key});

  @override
  State<AppInfoPage> createState() => _AppInfoPageState();
}

class _AppInfoPageState extends State<AppInfoPage> {
  static const String _version = '1.0.4';
  static const String _build = '2026';

  static const Color _accentPrimary = primaryColor;
  static const Color _logoutRed = dangerRed;
  Color get _cardTheme => context.palette.card;
  Color get _textDark => context.palette.textPrimary;
  Color get _textMuted => context.palette.textMuted;
  Color get _textSecondary => context.palette.textSecondary;
  Color get _pinkWash => context.palette.tint(primaryColor, accentLight);
  Color get _itemDivider =>
      context.isDarkMode ? context.palette.divider : const Color(0xFFF4EBED);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.scaffoldSoft,
      appBar: AppBar(
        backgroundColor: context.palette.scaffoldSoft,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'App Info',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildSection([
            _buildInfoRow('Version', '$_version (Build $_build)'),
            _buildDivider(),
            _buildInfoRow('Ecosystem', 'SaveMom AlloConnect'),
            _buildDivider(),
            _buildInfoRow('Developer', 'SaveMom Healthcare Technologies'),
          ]),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              'ACCOUNT',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: _textMuted,
              ),
            ),
          ),
          _buildSection([_buildDeleteRow()]),
          const SizedBox(height: 28),
          Text(
            '© 2026 SaveMom Healthcare Technologies.\nAll rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: _textMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(color: _pinkWash, shape: BoxShape.circle),
          child: const Icon(
            Icons.favorite_rounded,
            color: _accentPrimary,
            size: 36,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'AlloMom Maternal Care',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Version $_version',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      ],
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _cardTheme,
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: _textSecondary)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 0.8,
      color: _itemDivider,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildDeleteRow() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showDeleteAccountConfirmation(context),
        splashColor: _logoutRed.withValues(alpha: 0.08),
        highlightColor: _logoutRed.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Row(
            children: [
              const Icon(
                Icons.delete_forever_rounded,
                size: 24,
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
                      style: TextStyle(fontSize: 12, color: _textMuted),
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
