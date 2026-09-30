import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';

// Controllers

// Views
import 'package:allomom/allowear/features/device/views/device_list_item.dart';

// Widgets
import 'package:allomom/allowear/widgets/empty_state.dart';
import 'package:allomom/allowear/widgets/scanning_animation.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class AllowearDisconnectedView extends StatefulWidget {
  const AllowearDisconnectedView({super.key});

  @override
  State<AllowearDisconnectedView> createState() =>
      _AllowearDisconnectedViewState();
}

class _AllowearDisconnectedViewState extends State<AllowearDisconnectedView>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceController = allowear;
    final primaryColor = getPrimaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      // floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Obx(() {
        final isScanning = deviceController.isScanning.value;
        return FloatingActionButton.extended(
          onPressed: isScanning
              ? () => deviceController.stopScan()
              : () => deviceController.pickDeviceTypeAndScan(),
          backgroundColor: isScanning ? const Color(0xFFE74C3C) : primaryColor,
          elevation: 4,
          highlightElevation: 8,
          icon: isScanning
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(
                  Icons.bluetooth_searching_rounded,
                  color: Colors.white,
                  size: 22,
                ),
          label: Text(
            isScanning ? 'Stop Scanning' : 'Start Scan',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        );
      }),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Standard App Bar
          SliverAppBar(
            elevation: 0,
            floating: true,
            backgroundColor: Colors.transparent,
            title: const Text(
              'Allowear',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Connect Your Device Header
          SliverToBoxAdapter(
            child: _buildSectionHeader(
              context,
              'Connect Your Device',
              Icons.bluetooth_searching_rounded,
              primaryColor,
              isDark,
            ),
          ),

          // Devices List Header
          Obx(() {
            if (deviceController.devices.isEmpty)
              return const SliverToBoxAdapter();
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.devices_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Available Devices',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Black800,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${deviceController.devices.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          // Device List
          Obx(() => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => DeviceListItem(
                      device: deviceController.devices[index],
                      isConnecting: deviceController.connectingDeviceId.value ==
                          deviceController.devices[index].id,
                      isConnected: deviceController.connectedDevice.value?.id ==
                          deviceController.devices[index].id,
                      onTap: () => deviceController
                          .connectToDevice(deviceController.devices[index]),
                      primaryColor: primaryColor,
                    ),
                    childCount: deviceController.devices.length,
                  ),
                ),
              )),

          // Empty State
          Obx(() {
            if (deviceController.devices.isEmpty &&
                !deviceController.isScanning.value) {
              return SliverToBoxAdapter(
                child: EmptyState(primaryColor: primaryColor),
              );
            }
            return const SliverToBoxAdapter();
          }),

          // Scanning Animation
          Obx(() {
            if (deviceController.isScanning.value &&
                deviceController.devices.isEmpty) {
              return SliverToBoxAdapter(
                child: ScanningAnimation(
                  animation: _pulseController,
                  primaryColor: primaryColor,
                ),
              );
            }
            return const SliverToBoxAdapter();
          }),

          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon,
      Color primaryColor, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Black800,
            ),
          ),
        ],
      ),
    );
  }
}
