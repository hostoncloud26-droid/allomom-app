import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Controllers

// Views
import 'package:allomom/allowear/allowear_connected_view.dart';
import 'package:allomom/allowear/allowear_disconnected_view.dart';

// Widgets
import 'package:allomom/allowear/widgets/allowear_permission_prompt.dart';
import 'package:allomom/allowear/allowear_controller.dart';

class AllowearHome extends StatelessWidget {
  const AllowearHome({super.key});

  @override
  Widget build(BuildContext context) {
    final deviceController = allowear;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBgColor = isDark ? const Color(0xFF121218) : const Color(0xFFF5F5F7);

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Obx(() {
            final isConnected = deviceController.connectedDevice.value != null;
            final hasSavedDevice = deviceController.savedDevice.value != null;

            if (isConnected || hasSavedDevice) {
              return AllowearConnectedView(
                isSearching: !isConnected && hasSavedDevice,
              );
            } else {
              return const AllowearDisconnectedView();
            }
          }),
          const AllowearPermissionPrompt(),
        ],
      ),
    );
  }
}
