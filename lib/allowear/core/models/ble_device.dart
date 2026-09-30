import 'package:allowear_sdk/allowear_sdk.dart';
import 'package:flutter/material.dart';

/// An Allowear wearable as the UI sees it: a scan result, the connected device,
/// or the remembered one we are trying to reach.
class BleDevice {
  const BleDevice({
    required this.name,
    required this.id,
    this.deviceType,
    this.rssi,
  });

  final String name;

  /// The BLE MAC address.
  final String id;

  final AllowearDeviceType? deviceType;
  final int? rssi;

  factory BleDevice.fromDiscovered(DiscoveredDevice device) => BleDevice(
        name: device.name,
        id: device.macAddress,
        deviceType: device.deviceType,
        rssi: device.rssi,
      );
}

/// Battery icon and colour for a charge level, shared by every battery badge.
class AllowearBatteryStyle {
  AllowearBatteryStyle._();

  static IconData icon(int level) {
    if (level >= 90) return Icons.battery_full_rounded;
    if (level >= 70) return Icons.battery_6_bar_rounded;
    if (level >= 50) return Icons.battery_4_bar_rounded;
    if (level >= 30) return Icons.battery_3_bar_rounded;
    if (level >= 15) return Icons.battery_2_bar_rounded;
    return Icons.battery_1_bar_rounded;
  }

  static Color color(int level) {
    if (level >= 50) return Colors.green.shade300;
    if (level >= 20) return Colors.orange.shade300;
    return Colors.red.shade300;
  }
}
