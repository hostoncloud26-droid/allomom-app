import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/services/sq_lite/drift_database.dart';

const _rose = Color(0xFFFF3B5C);
const _mint = Color(0xFF10B981);
const _indigo = Color(0xFF6366F1);
const _amber = Color(0xFFF59E0B);
const _blue = Color(0xFF3B82F6);

final _dobFmt = DateFormat('d MMM yyyy');

/// The baby's card above the milestone train: photo with an edit button,
/// name, and a row of chips — date of birth, age and gender.
class BabyProfileCard extends StatelessWidget {
  const BabyProfileCard({
    super.key,
    required this.baby,
    required this.avatar,
    this.avatarKey,
    this.avatarVisible = true,
    this.onEdit,
  });

  final Baby baby;

  /// The baby's photo, or the illustration standing in for it.
  final Widget avatar;

  /// On the photo, for the switcher's avatar to fly to.
  final Key? avatarKey;

  /// False while that avatar is in flight, so the photo is not there twice.
  final bool avatarVisible;

  /// Opens the edit sheet.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ink = p.pick(const Color(0xFF1E2024), p.textPrimary);

    final birth = DateUtils.dateOnly(baby.deliveryDate);
    final days = DateUtils.dateOnly(DateTime.now()).difference(birth).inDays;
    final name = baby.name.trim().isEmpty ? 'Baby' : baby.name.trim();

    final gender = switch (baby.gender?.toLowerCase()) {
      'male' => (label: 'Boy', icon: Icons.male_rounded, color: _blue),
      'female' => (label: 'Girl', icon: Icons.female_rounded, color: _rose),
      _ => null,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.pick(const Color(0xFFF0F1F5), p.border)),
        gradient: p.isDark
            ? null
            : const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  Color(0xFFFFF1EE),
                  Colors.white,
                  Colors.white,
                  Color(0xFFEFFBF5),
                ],
                stops: [0, 0.35, 0.7, 1],
              ),
        boxShadow: [
          BoxShadow(
            color: p.shadow.withValues(alpha: p.isDark ? 0.2 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── PHOTO ───
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: avatarKey,
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: p.card,
                  border: Border.all(
                    color: _rose.withValues(alpha: 0.18),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: p.tint(_rose, const Color(0xFFFFF5F7)),
                    child: SizedBox.expand(
                      child: Opacity(
                        opacity: avatarVisible ? 1 : 0,
                        child: avatar,
                      ),
                    ),
                  ),
                ),
              ),
              if (onEdit != null)
                Positioned(
                  right: -4,
                  bottom: -2,
                  child: Material(
                    color: _rose,
                    shape: CircleBorder(
                      side: BorderSide(color: p.card, width: 2),
                    ),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEdit,
                      child: const SizedBox(
                        width: 24,
                        height: 24,
                        child: Icon(
                          Icons.edit_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // ─── NAME ───
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: ink,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 17,
                color: _mint,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ─── DATE OF BIRTH · AGE · GENDER ───
          // One line, scaled down rather than cut off on a narrow phone.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _chip(
                  context,
                  icon: Icons.cake_outlined,
                  label: _dobFmt.format(birth),
                  accent: _amber,
                ),
                const SizedBox(width: 8),
                _chip(
                  context,
                  icon: Icons.child_care_rounded,
                  label: _ageLabel(days),
                  accent: _indigo,
                ),
                if (gender != null) ...[
                  const SizedBox(width: 8),
                  _chip(
                    context,
                    icon: gender.icon,
                    label: gender.label,
                    accent: gender.color,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    final p = context.palette;
    final fg = p.pick(Color.lerp(accent, Colors.black, 0.35)!, accent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: p.isDark ? 0.18 : 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  /// Days for the first week, weeks for the first six months, months until two, then years.
  static String _ageLabel(int days) {
    if (days < 0) return 'Not born';
    if (days < 7) return '$days ${days == 1 ? 'Day' : 'Days'}';
    final weeks = days ~/ 7;
    if (weeks < 26) return '$weeks ${weeks == 1 ? 'Week' : 'Weeks'}';
    final months = days ~/ 30;
    if (months < 24) return '$months Months';
    final years = days ~/ 365;
    return '$years Years';
  }
}
