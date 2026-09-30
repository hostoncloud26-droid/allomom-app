import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/allowear/core/models/permission_issue.dart';

/// A blocking prompt for whatever is standing between the app and the bracelet.
///
/// It is deliberately not dismissible: it lives in the widget tree rather than
/// on a dialog route, so there is no barrier to tap through and nothing for the
/// back button to pop. It clears itself the moment the underlying issue is
/// resolved. Leaving the Allowear screen entirely still works, so the user is
/// never trapped here.
class AllowearPermissionPrompt extends StatelessWidget {
  const AllowearPermissionPrompt({super.key});

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<AllowearController>()) {
      return const SizedBox.shrink();
    }

    final controller = allowear;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return Obx(() {
      final issue = controller.permissionIssue.value;
      if (issue == null) return const SizedBox.shrink();

      final Color accentColor;
      final IconData iconData;
      switch (issue.type) {
        case AllowearPermissionIssueType.permanentlyDenied:
          accentColor = const Color(0xFFE74C3C);
          iconData = Icons.settings_suggest_rounded;
          break;
        case AllowearPermissionIssueType.denied:
          accentColor = const Color(0xFFF39C12);
          iconData = Icons.security_rounded;
          break;
        case AllowearPermissionIssueType.locationServiceDisabled:
          accentColor = const Color(0xFFE67E22);
          iconData = Icons.location_off_rounded;
          break;
        case AllowearPermissionIssueType.bluetoothDisabled:
          accentColor = primaryColor;
          iconData = Icons.bluetooth_disabled_rounded;
          break;
      }

      return SizedBox.expand(
        child: Stack(
          children: [
            // Scrim. AbsorbPointer swallows taps instead of dismissing, which is
            // what makes this non-closable.
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 380),
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: accentColor.withOpacity(0.3),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.5 : 0.18),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(iconData, color: accentColor, size: 34),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          issue.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Black800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          issue.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: isDark ? Colors.white70 : Black700,
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: controller.resolvePermissionIssue,
                            icon: Icon(
                              issue.isSettingsAction
                                  ? Icons.settings_rounded
                                  : Icons.arrow_forward_rounded,
                              size: 18,
                            ),
                            label: Text(
                              issue.actionText,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
