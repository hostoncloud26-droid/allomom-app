import 'package:allomom/allowear/allowear_colors.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_connected_view.dart';
import 'package:allomom/allowear/core/models/ble_device.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class ConnectedDeviceCard extends StatefulWidget {
  final BleDevice? connectedDevice;

  const ConnectedDeviceCard({
    super.key,
    required this.connectedDevice,
  });

  @override
  State<ConnectedDeviceCard> createState() => _ConnectedDeviceCardState();
}

class _ConnectedDeviceCardState extends State<ConnectedDeviceCard> {
  final batteryController = allowear;

  @override
  void initState() {
    super.initState();
    batteryController.refreshBattery();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = getPrimaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: primaryColor.withOpacity(isDark ? 0.2 : 0.1),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Device Icon with status glow
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset(
                      'assets/allowear/bracelet_white.png',
                      width: 26,
                      height: 26,
                      color: primaryColor,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF27AE60),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Device Name & Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.connectedDevice?.name ?? "Allowear Device",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Black800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connected & Active',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Black700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Battery Indicator
              Obx(() {
                final level = batteryController.batteryLevel.value ?? 0;
                final color = AllowearBatteryStyle.color(level);
                final icon = AllowearBatteryStyle.icon(level);
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${level}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Black800,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 16),
          // Actions
          Row(
            children: [
              Expanded(
                child: Text(
                  'ID: ${widget.connectedDevice?.id.substring(widget.connectedDevice!.id.length.clamp(8, 100) - 8).toUpperCase() ?? "UNKNOWN"}',
                  style: TextStyle(
                    fontSize: 10,
                    fontFamily: 'monospace',
                    color: isDark ? Colors.white30 : Colors.black26,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () =>
                      AllowearConnectedView.showDisconnectConfirmationBottomSheet(
                          context, allowear, isDark),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.link_off_rounded,
                          color: isDark ? Colors.white70 : Black800,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Disconnect',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Black800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
