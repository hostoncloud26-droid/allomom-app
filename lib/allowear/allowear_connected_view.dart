import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';

// Controllers

// Services

// Views & Pages
import 'package:allomom/allowear/allowear_settings_page.dart';
import 'package:allomom/allowear/features/camera/views/allowear_camera_page.dart';

// Widgets
import 'package:allomom/allowear/widgets/allowear_vital_tiles.dart';
import 'package:allomom/allowear/core/models/ble_device.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class AllowearConnectedView extends StatefulWidget {
  final bool isSearching;

  const AllowearConnectedView({
    super.key,
    this.isSearching = false,
  });

  static void showDisconnectConfirmationBottomSheet(
    BuildContext context,
    AllowearController deviceController,
    bool isDark,
  ) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
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
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE74C3C).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.link_off_rounded,
                color: Color(0xFFE74C3C),
                size: 32,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Disconnect Device'.tr,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Black800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to disconnect your Allowear device?'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Black700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),
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
                      'Cancel'.tr,
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
                      deviceController.disconnectAllowear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Disconnect'.tr,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  State<AllowearConnectedView> createState() => _AllowearConnectedViewState();
}

class _AllowearConnectedViewState extends State<AllowearConnectedView> {
  late final AllowearController _batteryController;

  @override
  void initState() {
    super.initState();
    _batteryController = allowear;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _batteryController.refreshBattery();
    });
  }

  @override
  Widget build(BuildContext context) {
    final deviceController = allowear;
    final healthSyncController = allowear;

    final primaryColor = getPrimaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Stack(
      children: [
        Column(
          children: [
            _ConnectedHeaderWidget(
              deviceController: deviceController,
              batteryController: _batteryController,
              healthSyncController: healthSyncController,
              primaryColor: primaryColor,
              isDark: isDark,
              isSearching: widget.isSearching,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _QuickActionsCard(
                      deviceController: deviceController,
                      healthSyncController: healthSyncController,
                      primaryColor: primaryColor,
                      isDark: isDark,
                      isSearching: widget.isSearching,
                    ),
                    const AllowearVitalsList(),
                    const SizedBox(height: 6),
                    if (widget.isSearching)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _FeatureCard(
                          title: 'Disconnect Device',
                          subtitle: 'Stop searching and pair a new device',
                          icon: Icons.link_off_rounded,
                          color: const Color(0xFFE74C3C),
                          isDark: isDark,
                          onTap: () => AllowearConnectedView
                              .showDisconnectConfirmationBottomSheet(
                                  context, deviceController, isDark),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Obx(() {
                      final mac = deviceController.deviceMac.value ?? '';
                      if (mac.isEmpty) return const SizedBox.shrink();

                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Device MAC : $mac',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.white54
                                    : Black700.withOpacity(0.6),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Obx(() => _buildBottomSyncLoader(
                context,
                healthSyncController,
                primaryColor,
                isDark,
              )),
        ),
      ],
    );
  }

  Widget _buildBottomSyncLoader(
    BuildContext context,
    AllowearController healthSyncController,
    Color primaryColor,
    bool isDark,
  ) {
    final isSyncing = healthSyncController.isSyncing.value;
    final progress = healthSyncController.syncProgress.value;
    final status = healthSyncController.syncStatus.value;

    return AnimatedSlide(
      offset: isSyncing ? Offset.zero : const Offset(0, 1.5),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: isSyncing ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(isDark ? 0.3 : 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Syncing Health Data'.tr,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Black800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.isNotEmpty
                                    ? status
                                    : 'Synchronizing records with Allowear...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Black700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (progress > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$progress%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  LinearProgressIndicator(
                    value:
                        progress > 0 ? (progress / 100).clamp(0.0, 1.0) : null,
                    minHeight: 3.5,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConnectedHeaderWidget extends StatelessWidget {
  final AllowearController deviceController;
  final AllowearController batteryController;
  final AllowearController healthSyncController;
  final Color primaryColor;
  final bool isDark;
  final bool isSearching;

  const _ConnectedHeaderWidget({
    required this.deviceController,
    required this.batteryController,
    required this.healthSyncController,
    required this.primaryColor,
    required this.isDark,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardBgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Black800;

    return Container(
      decoration: BoxDecoration(
        color: cardBgColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 16, 12),
          child: Row(
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: Icon(
                  Icons.arrow_back_ios_rounded,
                  color: textColor,
                  size: 20,
                ),
                onPressed: () => Get.back(),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Image.asset(
                  'assets/allowear/bracelet_white.png',
                  width: 28,
                  height: 28,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Allowear'.tr,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (!isSearching)
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF27AE60),
                              shape: BoxShape.circle,
                            ),
                          )
                        else
                          SizedBox(
                            width: 7,
                            height: 7,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(primaryColor),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Text(
                          isSearching
                              ? 'Looking for device...'
                              : 'Connected',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Black700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isSearching) ...[
                const SizedBox(width: 8),
                Obx(() {
                  final level = batteryController.batteryLevel.value ?? 0;
                  if (level == 0) return const SizedBox.shrink();

                  final color = AllowearBatteryStyle.color(level);
                  final icon = AllowearBatteryStyle.icon(level);

                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => batteryController.refreshBattery(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: color.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, color: color, size: 16),
                            const SizedBox(width: 5),
                            Text(
                              '$level%',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Black800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  final AllowearController deviceController;
  final AllowearController healthSyncController;
  final Color primaryColor;
  final bool isDark;
  final bool isSearching;

  const _QuickActionsCard({
    required this.deviceController,
    required this.healthSyncController,
    required this.primaryColor,
    required this.isDark,
    this.isSearching = false,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = isDark
        ? Colors.white.withOpacity(0.12)
        : Colors.black.withOpacity(0.08);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Divider(
          //   height: 1,
          //   thickness: 1,
          //   color: dividerColor,
          // ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Sync Data
                Expanded(
                  child: Obx(() {
                    final isSyncing = healthSyncController.isSyncing.value;
                    return _HeaderQuickAction(
                      icon: isSyncing
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            )
                          : Icon(
                              Icons.sync_rounded,
                              color: primaryColor,
                              size: 24,
                            ),
                      label: 'Sync Data'.tr,
                      onTap: isSearching
                          ? null
                          : () {
                              if (!healthSyncController.isSyncing.value) {
                                healthSyncController.startSync();
                              }
                            },
                      primaryColor: primaryColor,
                      isDark: isDark,
                    );
                  }),
                ),

                // 2. Settings
                Expanded(
                  child: _HeaderQuickAction(
                    icon: Icon(
                      Icons.settings_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                    label: 'Settings'.tr,
                    onTap: () => Get.to(() => const AllowearSettingsPage()),
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                ),

                // 3. Camera (the bracelet's remote shutter)
                if (deviceController.isBracelet)
                Expanded(
                  child: _HeaderQuickAction(
                    icon: Icon(
                      Icons.camera_alt_rounded,
                      color: primaryColor,
                      size: 24,
                    ),
                    label: 'Camera'.tr,
                    onTap: () => Get.to(() => const AllowearCameraPage()),
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                ),

                // 4. Disconnect
                Expanded(
                  child: _HeaderQuickAction(
                    icon: const Icon(
                      Icons.link_off_rounded,
                      color: Color(0xFFE74C3C),
                      size: 24,
                    ),
                    label: 'Disconnect'.tr,
                    customColor: const Color(0xFFE74C3C),
                    onTap: () => AllowearConnectedView
                        .showDisconnectConfirmationBottomSheet(
                            context, deviceController, isDark),
                    primaryColor: primaryColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),
        ],
      ),
    );
  }
}

class _HeaderQuickAction extends StatelessWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final Color primaryColor;
  final bool isDark;
  final Color? customColor;

  const _HeaderQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.primaryColor,
    required this.isDark,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = customColor ?? primaryColor;
    final circleBg =
        isDark ? baseColor.withOpacity(0.18) : baseColor.withOpacity(0.10);
    final textColor = isDark ? Colors.white : Black800;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: icon,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: textColor,
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

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isDark;
  final VoidCallback? onTap;

  const _FeatureCard({
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

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0),
      child: Material(
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
      ),
    );
  }
}
