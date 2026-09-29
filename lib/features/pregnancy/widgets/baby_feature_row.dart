import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/quick_action_images.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';
import 'package:allomom/features/pregnancy/widgets/baby_growth_track.dart';

/// The baby's features as a sideways slider of square boxes, sized and
/// styled as Home's quick actions: AlloCry, Feeding, Vaccination and Milestones.
class BabyFeatureRow extends StatelessWidget {
  const BabyFeatureRow({super.key, required this.onOpenTrack});

  /// Opens the full Vaccination or Milestones page.
  final ValueChanged<BabyTrackMode> onOpenTrack;

  @override
  Widget build(BuildContext context) {
    void push(Widget page) =>
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

    final boxes = [
      _FeatureBox(
        title: 'AlloCry',
        image: 'assets/Quick Actions/AlloCry.png',
        onTap: () => push(const AlloCryPage()),
      ),
      _FeatureBox(
        title: 'Feeding',
        image: QuickActionImages.feeding,
        onTap: () => push(const FeedingTrackerPage()),
      ),
      _FeatureBox(
        title: 'Vaccination',
        icon: Icons.vaccines_rounded,
        color: const Color(0xFF8B5CF6),
        onTap: () => onOpenTrack(BabyTrackMode.vaccinations),
      ),
      _FeatureBox(
        title: 'Milestones',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFF59E0B),
        onTap: () => onOpenTrack(BabyTrackMode.milestones),
      ),
    ];

    // Home's Quick Actions slider: square boxes of the same size, about
    // three on screen at a time, swiped sideways.
    return SizedBox(
      height: _boxSize,
      child: ListView.separated(
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: boxes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) => SizedBox(width: _boxSize, child: boxes[i]),
      ),
    );
  }

  /// Width and height of each box — Home's Quick Actions size.
  static const _boxSize = 112.0;
}

/// One box: the illustration, or a tinted icon where there is none, over a
/// one-line name.
class _FeatureBox extends StatelessWidget {
  const _FeatureBox({
    required this.title,
    required this.onTap,
    this.image,
    this.icon,
    this.color = const Color(0xFFFF3B5C),
  });

  final String title;
  final VoidCallback onTap;
  final String? image;
  final IconData? icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final image = this.image;

    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        boxShadow: [
          BoxShadow(
            color: p.pick(Colors.black.withValues(alpha: 0.03), p.shadow),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: image != null
                      ? Image.asset(image, fit: BoxFit.contain)
                      : Container(
                          decoration: BoxDecoration(
                            color: p.tint(color, color.withValues(alpha: 0.10)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, size: 30, color: color),
                        ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: p.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
