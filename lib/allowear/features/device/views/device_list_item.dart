import 'package:flutter/material.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/core/models/ble_device.dart';

class DeviceListItem extends StatelessWidget {
  final BleDevice device;
  final bool isConnecting;
  final bool isConnected;
  final VoidCallback? onTap;
  final Color? primaryColor;

  const DeviceListItem({
    super.key,
    required this.device,
    required this.isConnecting,
    required this.isConnected,
    this.onTap,
    this.primaryColor,
  });

  IconData _getDeviceIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('airpod') || lowerName.contains('buds')) {
      return Icons.earbuds_rounded;
    }
    if (lowerName.contains('headphone') || lowerName.contains('head')) {
      return Icons.headphones_rounded;
    }
    if (lowerName.contains('speaker')) {
      return Icons.speaker_rounded;
    }
    if (lowerName.contains('watch')) {
      return Icons.watch_rounded;
    }
    if (lowerName.contains('ring')) {
      return Icons.circle_outlined;
    }
    if (lowerName.contains('phone')) {
      return Icons.phone_android_rounded;
    }
    return Icons.bluetooth_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = primaryColor ?? getPrimaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final textColor = isDark ? Colors.white : Black800;
    final subtitleColor = isDark ? Colors.white38 : Black700;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? themeColor : (isDark ? Colors.transparent : Colors.grey.shade200),
          width: isConnected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isConnecting || isConnected ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildDeviceIcon(themeColor),
                const SizedBox(width: 16),
                _buildDeviceInfo(textColor, subtitleColor),
                _buildTrailingWidget(themeColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceIcon(Color themeColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            themeColor.withOpacity(0.15),
            themeColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        _getDeviceIcon(device.name),
        color: themeColor,
        size: 26,
      ),
    );
  }

  Widget _buildDeviceInfo(Color textColor, Color subtitleColor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device.name.isNotEmpty ? device.name : 'Unknown Device',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            device.id,
            style: TextStyle(
              color: subtitleColor,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(Color themeColor) {
    if (isConnecting) {
      return Container(
        padding: const EdgeInsets.all(8),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(themeColor),
          ),
        ),
      );
    }

    if (isConnected) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade400,
              Colors.green.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
            SizedBox(width: 4),
            Text(
              'Connected',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: themeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.arrow_forward_ios_rounded,
        color: themeColor,
        size: 16,
      ),
    );
  }
}
