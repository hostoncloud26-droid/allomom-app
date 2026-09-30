import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';

/// Represents a 3D family portrait option for the family section.
class FamilyIllustrationOption {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;

  const FamilyIllustrationOption({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
  });
}

class FamilyIllustrationHelper {
  static const String defaultAsset = 'assets/family/family_newborn.png';
  static const String houseAsset = 'assets/family/family_house.png';

  static const List<FamilyIllustrationOption> options = [
    FamilyIllustrationOption(
      id: 'newborn',
      title: 'Mom, Dad & Newborn',
      subtitle: 'Parents holding swaddled newborn',
      assetPath: 'assets/family/family_newborn.png',
    ),
    FamilyIllustrationOption(
      id: 'girl',
      title: 'Baby Girl',
      subtitle: 'Mom, Dad & cheerful girl in pink dress',
      assetPath: 'assets/family/family_girl.png',
    ),
    FamilyIllustrationOption(
      id: 'boy',
      title: 'Baby Boy',
      subtitle: 'Mom, Dad & smiling boy in blue onesie',
      assetPath: 'assets/family/family_boy.png',
    ),
    FamilyIllustrationOption(
      id: 'twokids',
      title: 'Two Children',
      subtitle: 'Mom, Dad, elder daughter & baby son',
      assetPath: 'assets/family/family_twokids.png',
    ),
    FamilyIllustrationOption(
      id: 'pregnant',
      title: 'Mom-to-be / Expecting',
      subtitle: 'Gentle mother holding baby bump',
      assetPath: 'assets/family/family_pregnant.png',
    ),
    FamilyIllustrationOption(
      id: 'house',
      title: 'Sweet Family Home',
      subtitle: 'Cozy 3D home with heart balloon',
      assetPath: 'assets/family/family_house.png',
    ),
  ];

  /// Resolves which 3D PNG illustration to display based on either:
  /// 1. Manual user override ([manualChoice]), or
  /// 2. Automatic family scenario detection ([members]).
  static String resolveIllustration({
    String? manualChoice,
    required List<dynamic> members,
  }) {
    if (manualChoice != null &&
        manualChoice.isNotEmpty &&
        manualChoice != 'auto') {
      for (final opt in options) {
        if (opt.assetPath == manualChoice || opt.id == manualChoice) {
          return opt.assetPath;
        }
      }
      // If manualChoice is a valid asset path containing family/
      if (manualChoice.contains('assets/family/')) {
        return manualChoice;
      }
    }

    // Auto-detect based on family composition
    final children = members.where((m) {
      if (m is! Map) return false;
      final rel = (m['relation'] ?? '').toString().toLowerCase();
      final id = (m['id'] ?? m['userid'] ?? '').toString().toLowerCase();
      return rel == 'child' ||
          rel.contains('baby') ||
          rel.contains('kid') ||
          rel.contains('son') ||
          rel.contains('daughter') ||
          id.startsWith('baby_');
    }).toList();

    if (children.length >= 2) {
      return 'assets/family/family_twokids.png';
    } else if (children.length == 1) {
      final child = children.first as Map;
      final gender = (child['gender'] ?? '').toString().toLowerCase();
      final rel = (child['relation'] ?? '').toString().toLowerCase();

      if (gender == 'female' ||
          gender == 'girl' ||
          gender == 'f' ||
          rel.contains('daughter')) {
        return 'assets/family/family_girl.png';
      } else if (gender == 'male' ||
          gender == 'boy' ||
          gender == 'm' ||
          rel.contains('son')) {
        return 'assets/family/family_boy.png';
      }
      return 'assets/family/family_newborn.png';
    }

    // If no children recorded yet (e.g. pregnancy stage)
    if (children.isEmpty && members.length <= 2) {
      return 'assets/family/family_pregnant.png';
    }

    return 'assets/family/family_newborn.png';
  }

  /// Displays a modal bottom sheet allowing the user to switch the family
  /// illustration among the available 3D styles or pick auto scenario mode.
  static Future<void> showPickerSheet({
    required BuildContext context,
    required String currentAsset,
    required ValueChanged<String> onSelected,
  }) async {
    final palette = context.palette;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: palette.border,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Family Portrait',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select the 3D illustration for your family section',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        onSelected('auto');
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 16),
                      label: const Text(
                        'Auto',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                Flexible(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: options.map((opt) {
                        final isSelected = currentAsset == opt.assetPath;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(ctx);
                              onSelected(opt.assetPath);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? primaryColor.withValues(alpha: 0.08)
                                    : palette.scaffoldSoft,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryColor
                                      : palette.border.withValues(alpha: 0.5),
                                  width: isSelected ? 1.8 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    padding: const EdgeInsets.all(4),
                                    child: Image.asset(
                                      opt.assetPath,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          opt.title,
                                          style: TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected
                                                ? primaryColor
                                                : palette.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          opt.subtitle,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: palette.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 26,
                                    height: 26,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? primaryColor
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? primaryColor
                                            : palette.textMuted.withValues(
                                                alpha: 0.4,
                                              ),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(
                                            Icons.check_rounded,
                                            size: 16,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
