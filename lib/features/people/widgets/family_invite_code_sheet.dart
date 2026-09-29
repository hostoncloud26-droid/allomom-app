/// The family's invite code and QR — shown from anywhere, not only from
/// inside [PeoplePage].
///
/// Pulled out of `_PeoplePageState._showShareQrModal` so the offline
/// chatbot's `show_family_code` action can open the same sheet without
/// needing that page's state: it looks the family up itself rather than
/// reading a field already loaded on screen.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:allomom/components/baby_bottom_avatar.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/controllers/main_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:allomom/services/sq_lite/services/family_db_service.dart';

Future<void> showFamilyInviteCodeSheet(BuildContext context) async {
  speak(NarrationKeys.pgFamilyCode, force: true);

  final userId = MainController.instance.userId;
  final family = userId.isEmpty
      ? null
      : await FamilyDbService.instance.getMyFamily(userId);
  final code = (family?.code ?? '').isNotEmpty ? family!.code! : 'ALLOMOM';

  if (!context.mounted) return;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => BabyOnScreen(
      wholeScreen: true,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Family Invite Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: textDark,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Share this 6-character code with your partner to join your family',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: textLight),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: QrImageView(
                data: code,
                version: QrVersions.auto,
                size: 160,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: textDark,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: textDark,
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('Family Code $code copied to clipboard!'),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.copy_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'INVITE CODE: $code',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
