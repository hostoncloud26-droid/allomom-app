import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';

import 'health_tile_parts.dart';

/// Water tile in AlloConnect's style — a wave bubble filling towards the
/// day's goal beside quick "+ glass" presets. Allomom logs water in glasses
/// (each row an increment, so a correction is a -1 row), so the tile counts
/// glasses and shows millilitres alongside.
class WaterTile extends StatefulWidget {
  final int glasses;
  final int targetGlasses;
  final bool readOnly;
  final VoidCallback onOpen;
  final ValueChanged<int> onAdd;
  final VoidCallback onRemove;

  /// Millilitres in one glass.
  final int glassMl;

  const WaterTile({
    super.key,
    required this.glasses,
    required this.onOpen,
    required this.onAdd,
    required this.onRemove,
    this.targetGlasses = 10,
    this.glassMl = 250,
    this.readOnly = false,
  });

  @override
  State<WaterTile> createState() => _WaterTileState();
}

class _WaterTileState extends State<WaterTile> with TickerProviderStateMixin {
  late final AnimationController _scaleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 150),
  );
  late final Animation<double> _scaleAnimation =
      Tween<double>(begin: 1.0, end: 0.97).animate(
    CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
  );
  late final AnimationController _waveController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2500),
  )..repeat();

  @override
  void dispose() {
    _scaleController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _bounce() async {
    await _scaleController.forward();
    if (mounted) await _scaleController.reverse();
  }

  void _add(int glasses) {
    if (widget.readOnly) return;
    _bounce();
    widget.onAdd(glasses);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = context.palette.isDark;
    final waterColor = Colors.cyan.shade600;
    final textColor = tileTextColor(context);

    final glasses = widget.glasses < 0 ? 0 : widget.glasses;
    final target = widget.targetGlasses > 0 ? widget.targetGlasses : 10;
    final progress = (glasses / target).clamp(0.0, 1.0);
    final percentInt = (progress * 100).toInt();
    final targetLitres = (target * widget.glassMl / 1000).toStringAsFixed(1);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTap: widget.onOpen,
        behavior: HitTestBehavior.opaque,
        child: HealthTileCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HealthTileHeader(
                title: 'Water Tracking',
                accent: waterColor,
                trailing: [
                  HealthTileBadge(
                    text: '$glasses / $target glasses',
                    color: waterColor,
                    fontSize: 10,
                  ),
                  if (!widget.readOnly && glasses > 0) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: widget.onRemove,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: waterColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: waterColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDarkMode
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.cyan.shade50.withValues(alpha: 0.4),
                          border: Border.all(
                            color: waterColor.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: AnimatedBuilder(
                            animation: _waveController,
                            builder: (context, child) => ClipPath(
                              clipper: _WaveClipper(
                                progress,
                                _waveController.value,
                              ),
                              child: child,
                            ),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.cyan.shade600,
                                    Colors.blue.shade400,
                                  ],
                                ),
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                      ),
                      Text(
                        '$percentInt%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: percentInt > 45 ? Colors.white : textColor,
                          shadows: percentInt > 45
                              ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          glasses >= target
                              ? 'Fully Hydrated!'
                              : 'Stay Hydrated!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${glasses * widget.glassMl} ml of $targetLitres L goal',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor.withValues(alpha: 0.5),
                          ),
                        ),
                        if (!widget.readOnly) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              HealthTileQuickAction(
                                label: '+1 Glass',
                                icon: Icons.local_drink_rounded,
                                color: waterColor,
                                verticalPadding: 10,
                                fontSize: 11,
                                onTap: () => _add(1),
                              ),
                              const SizedBox(width: 8),
                              HealthTileQuickAction(
                                label: '+2 Glasses',
                                icon: Icons.local_drink_rounded,
                                color: waterColor,
                                verticalPadding: 10,
                                fontSize: 11,
                                onTap: () => _add(2),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  final double progress;
  final double animationValue;

  _WaveClipper(this.progress, this.animationValue);

  @override
  Path getClip(Size size) {
    final path = Path();
    final y = size.height * (1.0 - progress);
    path.moveTo(0, y);
    const waveHeight = 5.0;
    for (double x = 0; x <= size.width; x++) {
      final angle = (x / size.width) * 2 * math.pi +
          (animationValue * 2 * math.pi);
      path.lineTo(x, y + waveHeight * math.sin(angle));
    }
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _WaveClipper oldClipper) =>
      oldClipper.progress != progress ||
      oldClipper.animationValue != animationValue;
}
