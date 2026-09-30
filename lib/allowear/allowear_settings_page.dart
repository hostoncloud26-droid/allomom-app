import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';

// Controllers

// Services

// Views & Widgets
import 'package:allomom/allowear/features/health_monitoring/views/health_monitoring_page.dart';
import 'package:allomom/allowear/features/camera/views/allowear_camera_page.dart';
import 'package:allomom/allowear/features/device/widgets/firmware_update_bottom_sheet.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class AllowearSettingsPage extends StatelessWidget {
  const AllowearSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceController = allowear;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Black800;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF12121A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: textColor,
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Allowear Settings'.tr,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SettingsFeatureCard(
                title: 'Health Monitoring',
                subtitle: 'Vitals, Activity & Sleep insights',
                icon: Icons.monitor_heart_rounded,
                color: const Color(0xFFE74C3C),
                isDark: isDark,
                onTap: () => Get.to(() => HealthMonitoringPage()),
              ),
              // Camera, media controls, OTA, reset and shutdown are bracelet
              // features; the ring and the watch have no equivalent.
              if (deviceController.isBracelet) ...[
                const SizedBox(height: 12),
                _SettingsFeatureCard(
                  title: 'Camera Control',
                  subtitle: 'Use your device as a remote shutter',
                  icon: Icons.camera_alt_rounded,
                  color: const Color(0xFF3498DB),
                  isDark: isDark,
                  onTap: () => Get.to(() => const AllowearCameraPage()),
                ),
                const SizedBox(height: 12),
                Obx(() {
                  final currentMode = deviceController.videoHidMode.value;
                  String label = 'Mode: Disabled';
                  IconData icon = Icons.videocam_off_rounded;

                  switch (currentMode) {
                    case 1:
                      label = 'Mode: Short Video';
                      icon = Icons.play_circle_outline_rounded;
                      break;
                    case 2:
                      label = 'Mode: Book Reading';
                      icon = Icons.menu_book_rounded;
                      break;
                    case 3:
                      label = 'Mode: Music Control';
                      icon = Icons.music_note_rounded;
                      break;
                  }

                  return _SettingsFeatureCard(
                    title: 'Shorts Control',
                    subtitle: label,
                    icon: icon,
                    color: const Color(0xFFF39C12),
                    isDark: isDark,
                    onTap: () => _showVideoHidBottomSheet(
                      context,
                      deviceController,
                      isDark,
                    ),
                  );
                }),
                const SizedBox(height: 12),
                _SettingsFeatureCard(
                  title: 'Firmware Update',
                  subtitle: 'Keep your device up to date',
                  icon: Icons.system_update_rounded,
                  color: const Color(0xFF1ABC9C),
                  isDark: isDark,
                  onTap: () => Get.bottomSheet(
                    const FirmwareUpdateBottomSheet(),
                    isScrollControlled: true,
                    isDismissible: true,
                    enableDrag: true,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsFeatureCard(
                  title: 'Reset Factory',
                  subtitle: 'Restore to original settings',
                  icon: Icons.settings_backup_restore_rounded,
                  color: const Color(0xFFE67E22),
                  isDark: isDark,
                  onTap: () => _showActionConfirmation(
                    context,
                    title: 'Reset Factory',
                    message:
                        'This will restore your device to its original factory settings. All data on the device will be cleared.',
                    confirmText: 'Reset Now',
                    onConfirm: () => allowear.factoryResetDevice(),
                    isDestructive: true,
                  ),
                ),
                const SizedBox(height: 12),
                _SettingsFeatureCard(
                  title: 'Device Shutdown',
                  subtitle: 'Safely power off your device',
                  icon: Icons.power_settings_new_rounded,
                  color: const Color(0xFF2C3E50),
                  isDark: isDark,
                  onTap: () => _showActionConfirmation(
                    context,
                    title: 'Shutdown Device',
                    message:
                        'Are you sure you want to power off your Allowear device?',
                    confirmText: 'Shutdown',
                    onConfirm: () => allowear.shutdownDevice(),
                    isDestructive: true,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Obx(() => _buildFirmwareInfoFooter(
                  context, deviceController.firmwareInfo.value, isDark)),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFirmwareInfoFooter(
      BuildContext context, Map<String, dynamic>? info, bool isDark) {
    final deviceController = allowear;
    final macAddress = deviceController.deviceMac.value ?? 'Unknown';

    if (info == null && macAddress == 'Unknown') return const SizedBox.shrink();

    final model = info?['deviceModel'] ?? 'Unknown';
    final version = info?['firmwareVersion'] ?? '0.0.0';
    final uiVersion = info?['uiVersion'] ?? '0.0.0';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E1E2E).withOpacity(0.5)
            : Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => deviceController.handleDeviceModelTap(),
            child: _infoRow('Device Model', model, isDark),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _infoRow('Firmware', version, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
          _infoRow('UI Version', uiVersion, isDark),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, thickness: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white38 : Black300,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white70 : Black700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showVideoHidBottomSheet(
      BuildContext context, AllowearController controller, bool isDark) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
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
              'Gesture Control Mode',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Black800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how your ring controls your phone. This requires Bluetooth HID pairing.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Obx(() => _buildModeTile(
                context,
                0,
                'Off',
                'Disable gesture control',
                Icons.block_rounded,
                controller.videoHidMode.value,
                isDark)),
            Obx(() => _buildModeTile(
                context,
                1,
                'Short Video',
                'Scroll through TikTok/Reels',
                Icons.play_circle_outline_rounded,
                controller.videoHidMode.value,
                isDark)),
            Obx(() => _buildModeTile(
                context,
                2,
                'Book Reading',
                'Turn pages in e-books',
                Icons.menu_book_rounded,
                controller.videoHidMode.value,
                isDark)),
            Obx(() => _buildModeTile(
                context,
                3,
                'Music Control',
                'Play/Pause & skip tracks',
                Icons.music_note_rounded,
                controller.videoHidMode.value,
                isDark)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Get.back(),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildModeTile(BuildContext context, int mode, String title,
      String subtitle, IconData icon, int currentMode, bool isDark) {
    final isSelected = currentMode == mode;
    final primaryColor = getPrimaryColor(context);

    return InkWell(
      onTap: () {
        allowear.setVideoControlMode(mode);
        Get.back();
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : (isDark
                  ? Colors.white.withOpacity(0.05)
                  : Colors.black.withOpacity(0.03)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? primaryColor : Colors.grey.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Black800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: primaryColor, size: 24),
          ],
        ),
      ),
    );
  }

  void _showActionConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmText,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.dialog(
      BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (isDestructive ? Colors.red : Colors.blue)
                        .withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDestructive
                        ? Icons.warning_amber_rounded
                        : Icons.info_outline_rounded,
                    color: isDestructive ? Colors.red : Colors.blue,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Black800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Black700,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Get.back(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.white60 : Colors.black45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Get.back();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDestructive
                              ? Colors.red
                              : getPrimaryColor(context),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      barrierColor: Colors.black.withOpacity(0.5),
    );
  }
}

class _SettingsFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _SettingsFeatureCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(isDark ? 0.2 : 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Black800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white38 : Black300,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: (isDark ? Colors.white : Black800).withOpacity(0.2),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
