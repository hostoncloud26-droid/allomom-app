import 'package:flutter/material.dart';
import 'package:allomom/allowear/allowear_colors.dart';

class ScanningAnimation extends StatelessWidget {
  final Animation<double> animation;
  final Color? primaryColor;

  const ScanningAnimation({
    super.key,
    required this.animation,
    this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final themeColor = primaryColor ?? getPrimaryColor(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white70 : Black700;
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: animation,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [themeColor, themeColor.withOpacity(0.8)],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.bluetooth_searching_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    ...List.generate(3, (index) {
                      final delay = index * 0.3;
                      final animValue = ((animation.value + delay) % 1.0);
                      return Container(
                        width: 80 + (animValue * 80),
                        height: 80 + (animValue * 80),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeColor.withOpacity(1 - animValue),
                            width: 2,
                          ),
                        ),
                      );
                    }),
                    if (child != null) child,
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Scanning for devices...',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please make sure your device is\nturned on and in pairing mode',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor.withOpacity(0.7),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

