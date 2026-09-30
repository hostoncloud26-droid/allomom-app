import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/allowear/allowear_colors.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class DeviceCapabilityPage extends StatelessWidget {
  const DeviceCapabilityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceController = allowear;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = getPrimaryColor(context);

    // List of all support Menu attributes and metadata
    final List<Map<String, dynamic>> capabilityMeta = [
      {
        'key': 'isHr',
        'label': 'Heart Rate Monitoring',
        'description': 'Monitor heart rate periodically',
        'icon': Icons.favorite_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isBloodOxy',
        'label': 'Blood Oxygen Monitoring',
        'description': 'Measure blood oxygen levels (SpO2)',
        'icon': Icons.bloodtype_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isSleep',
        'label': 'Sleep Mode Tracking',
        'description': 'Analyze sleep patterns and efficiency',
        'icon': Icons.bedtime_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isHrv',
        'label': 'Heart Rate Variability',
        'description': 'Analyze heart rate variability (HRV)',
        'icon': Icons.insights_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isPressure',
        'label': 'Stress / Pressure Monitoring',
        'description': 'Track mental stress levels',
        'icon': Icons.psychology_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isBloodSugar',
        'label': 'Blood Glucose Monitoring',
        'description': 'Track blood glucose measurements',
        'icon': Icons.healing_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isBloodPress',
        'label': 'Blood Pressure Measurement',
        'description': 'Track blood pressure history',
        'icon': Icons.speed_rounded,
        'category': 'Vitals & Health',
      },
      {
        'key': 'isStep',
        'label': 'Step Counter',
        'description': 'Track and calculate daily steps taken',
        'icon': Icons.directions_walk_rounded,
        'category': 'Sports & Activity',
      },
      {
        'key': 'isNewSport',
        'label': 'Multiple Sports Modes',
        'description': 'Tracks different exercise types',
        'icon': Icons.directions_run_rounded,
        'category': 'Sports & Activity',
      },
      {
        'key': 'isAlarm',
        'label': 'Alarm Clock',
        'description': 'Supports setting alarms on the ring',
        'icon': Icons.alarm_rounded,
        'category': 'Device Controls',
      },
      {
        'key': 'isPushMsgEnableSwitch',
        'label': 'Message Control Switch',
        'description': 'Enable or disable message control switch',
        'icon': Icons.message_rounded,
        'category': 'Device Controls',
      },
      {
        'key': 'isBrightScreenSleepTime',
        'label': 'Screen Sleep Time Settings',
        'description': 'Configure ring screen sleep time limits',
        'icon': Icons.nights_stay_rounded,
        'category': 'Device Controls',
      },
      {
        'key': 'isBrightScreenTime',
        'label': 'Screen-on Time Settings',
        'description': 'Adjust how long the ring screen stays on',
        'icon': Icons.brightness_medium_rounded,
        'category': 'Device Controls',
      },
      {
        'key': 'isSupportMotoVibrationLevel',
        'label': 'Motor Vibration Intensity',
        'description': 'Supports adjusting ring vibration levels',
        'icon': Icons.vibration_rounded,
        'category': 'Device Controls',
      },
      {
        'key': 'isSupportHrReminder',
        'label': 'Heart Rate Alarm Alert',
        'description': 'Notify when heart rate exceeds safe bounds',
        'icon': Icons.favorite_border_rounded,
        'category': 'Alerts & Reminders',
      },
      {
        'key': 'isSupportBoReminder',
        'label': 'SpO2 Alarm Alert',
        'description': 'Notify when blood oxygen falls below threshold',
        'icon': Icons.opacity_rounded,
        'category': 'Alerts & Reminders',
      },
      {
        'key': 'isRememberSwitch',
        'label': 'Muslim Prayers Switch',
        'description': 'Support setting and toggling Muslim prayers',
        'icon': Icons.mosque_rounded,
        'category': 'Muslim Prayer features',
      },
      {
        'key': 'isMuslimCountData',
        'label': 'Praise Counter (Muslim Count)',
        'description': 'Record praise and counts on the device',
        'icon': Icons.plus_one_rounded,
        'category': 'Muslim Prayer features',
      },
      {
        'key': 'isSupportMuslimTimeDisplayMode',
        'label': 'Muslim Time Display Mode',
        'description': 'Display prayer times on the device screen',
        'icon': Icons.access_time_rounded,
        'category': 'Muslim Prayer features',
      },
      {
        'key': 'isSupportSensorRawPPG',
        'label': 'PPG Raw Data Stream',
        'description': 'Stream raw PPG sensor measurements',
        'icon': Icons.analytics_rounded,
        'category': 'Raw Sensors',
      },
      {
        'key': 'isSupportSensorRawACC',
        'label': 'ACC Accelerometer Raw Data',
        'description': 'Stream raw 3-axis accelerometer data',
        'icon': Icons.gesture_rounded,
        'category': 'Raw Sensors',
      },
      {
        'key': 'isSupportSensorRawPPGRed',
        'label': 'PPG Red Light Raw Data',
        'description': 'Stream raw Red light wavelength sensor data',
        'icon': Icons.lightbulb_outline_rounded,
        'category': 'Raw Sensors',
      },
      {
        'key': 'isSupportSensorRawIR',
        'label': 'IR Infrared Raw Data',
        'description': 'Stream raw Infrared wavelength sensor data',
        'icon': Icons.sensors_rounded,
        'category': 'Raw Sensors',
      },
    ];

    // Group items by category
    final Map<String, List<Map<String, dynamic>>> groupedCapabilities = {};
    for (var item in capabilityMeta) {
      final category = item['category'] as String;
      groupedCapabilities.putIfAbsent(category, () => []).add(item);
    }

    final scaffoldBgColor = isDark ? const Color(0xFF121218) : const Color(0xFFF5F5F7);
    final cardBgColor = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final titleTextColor = isDark ? Colors.white : Black800;
    final subtitleTextColor = isDark ? Colors.white70 : Black700;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: cardBgColor,
        elevation: 0.5,
        title: Text(
          'Device Capabilities',
          style: TextStyle(
            color: titleTextColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: titleTextColor, size: 20),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final caps = deviceController.deviceCapabilities;

        if (caps.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => deviceController.refreshCapabilities(),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.developer_board_off_rounded,
                              size: 64, color: primaryColor.withOpacity(0.5)),
                          const SizedBox(height: 16),
                          Text(
                            'No Capability Data Found',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: titleTextColor),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'Ensure the smart ring is connected to query and display hardware capability menus.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: subtitleTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => deviceController.refreshCapabilities(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.all(16),
          itemCount: groupedCapabilities.keys.length,
          itemBuilder: (context, index) {
            final category = groupedCapabilities.keys.elementAt(index);
            final items = groupedCapabilities[category]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 16, bottom: 8),
                  child: Text(
                    category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: primaryColor,
                    ),
                  ),
                ),
                Card(
                  elevation: 0,
                  color: cardBgColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: (isDark ? Colors.white : Colors.black).withOpacity(0.05),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: items.asMap().entries.map((entry) {
                        final itemIndex = entry.key;
                        final item = entry.value;
                        final key = item['key'] as String;
                        final label = item['label'] as String;
                        final description = item['description'] as String;
                        final icon = item['icon'] as IconData;

                        final isSupported = caps[key] ?? false;

                        return Column(
                          children: [
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSupported
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  icon,
                                  color: isSupported ? Colors.green : Colors.grey,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                label,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: titleTextColor,
                                ),
                              ),
                              subtitle: Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isSupported
                                      ? Colors.green.withOpacity(0.15)
                                      : Colors.red.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSupported
                                        ? Colors.green.withOpacity(0.2)
                                        : Colors.red.withOpacity(0.1),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isSupported ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                                      size: 14,
                                      color: isSupported ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isSupported ? 'Supported' : 'Unsupported',
                                      style: TextStyle(
                                        color: isSupported ? Colors.green : Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (itemIndex < items.length - 1)
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Divider(
                                  height: 1,
                                  thickness: 0.5,
                                  color: Colors.grey.withOpacity(0.2),
                                ),
                              ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      );
    }),
    );
  }
}
