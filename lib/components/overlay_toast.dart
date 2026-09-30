import 'dart:async';

import 'package:flutter/material.dart';

/// A toast drawn on the root overlay, so it sits above bottom sheets and
/// dialogs. A [SnackBar] is shown by the page's Scaffold, which is *under* any
/// open modal route — errors raised inside a sheet ended up hidden behind it.
void showOverlayToast(
  BuildContext context,
  String message, {
  bool isSuccess = false,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.of(ctx).padding.top + 12,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSuccess
                ? const Color(0xFF10B981)
                : const Color(0xFFFF4E6A),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Color(0x33000000), blurRadius: 12),
            ],
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    ),
  );
  overlay.insert(entry);
  Timer(duration, () {
    if (entry.mounted) entry.remove();
  });
}
