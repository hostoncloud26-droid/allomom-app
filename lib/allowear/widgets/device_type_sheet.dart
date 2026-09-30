import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';

/// Asks which Allowear model the user has, so the scan and every call after it
/// use that model's SDK.
///
/// Each model is a plain button — nothing is pre-selected — so a new user,
/// or one who just logged out, never sees a previous choice as a toggle.
///
/// Resolves to the picked type, or null when the sheet is dismissed.
class DeviceTypeSheet extends StatelessWidget {
  const DeviceTypeSheet({super.key});

  static Future<AllowearDeviceType?> show() {
    return Get.bottomSheet<AllowearDeviceType>(
      const DeviceTypeSheet(),
      isScrollControlled: true,
    );
  }

  static const List<_DeviceOption> _options = [
    _DeviceOption(
      type: AllowearDeviceType.v1,
      title: 'Bracelet',
      subtitle: 'Allowear band with camera & media controls',
      icon: Icons.watch_outlined,
    ),
    _DeviceOption(
      type: AllowearDeviceType.v8,
      title: 'Allowear Fit',
      subtitle: 'Smart ring with temperature & blood pressure',
      icon: Icons.fit_screen,
    ),
    _DeviceOption(
      type: AllowearDeviceType.nx,
      title: 'Allowear NX',
      subtitle: 'Allowear NX Wear Smartband',
      icon: Icons.watch_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 12, 24, 24 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Select Your Device',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Black800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the Allowear model you want to connect',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          for (final option in _options) ...[
            _DeviceOptionTile(
              option: option,
              primaryColor: primaryColor,
              isDark: isDark,
              onTap: () => Get.back(result: option.type),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _DeviceOption {
  const _DeviceOption({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final AllowearDeviceType type;
  final String title;
  final String subtitle;
  final IconData icon;
}

class _DeviceOptionTile extends StatelessWidget {
  const _DeviceOptionTile({
    required this.option,
    required this.primaryColor,
    required this.isDark,
    required this.onTap,
  });

  final _DeviceOption option;
  final Color primaryColor;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primaryColor.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(option.icon, color: primaryColor, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Black800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : Black700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
