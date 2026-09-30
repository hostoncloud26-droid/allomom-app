import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

/// A reusable frosted-glass bar: the page shows through a blurred, tinted fill,
/// with the accent color on the label and icon. Used to stop baby/TTS voice narration.
class StopSpeakingButton extends StatelessWidget {
  const StopSpeakingButton({
    super.key,
    required this.onTap,
    this.accentColor = const Color(0xFFFF4E6A),
    this.label = 'Stop Speaking',
    this.height = 36,
    this.borderRadius = 12,
    this.margin,
  });

  final VoidCallback onTap;
  final Color accentColor;
  final String label;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isDark = context.palette.isDark;
    final radius = BorderRadius.circular(borderRadius);

    Widget button = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(
            alpha: isDark ? 0.08 : 0.65,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: double.infinity,
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded, size: 18, color: accentColor),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (margin != null) {
      return Padding(padding: margin!, child: button);
    }
    return button;
  }
}
