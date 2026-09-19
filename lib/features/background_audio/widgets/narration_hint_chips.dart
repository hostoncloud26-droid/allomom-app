import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// One "ask the baby" chip: a short label and the line it plays.
class NarrationHint {
  const NarrationHint(this.label, this.narrationKey);

  final String label;
  final String narrationKey;
}

/// A row of small chips that put a side-question on the baby head card.
///
/// Several lines in the script answer something the mother might wonder rather
/// than something the flow asks her — why the date matters, what to do if she
/// cannot remember it, what happens if the doctor said something different.
/// Without a control they would never be heard, so each gets a chip; tapping
/// one swaps the card to that line.
class NarrationHintChips extends StatelessWidget {
  const NarrationHintChips({
    super.key,
    required this.hints,
    required this.onSelected,
    this.selectedKey,
    this.padding = EdgeInsets.zero,
  });

  final List<NarrationHint> hints;

  /// Given the key of the tapped chip. The page both plays it and binds it to
  /// its baby head card, so the text and the voice stay in step.
  final ValueChanged<String> onSelected;

  /// The chip currently showing on the card, highlighted.
  final String? selectedKey;

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (hints.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: padding,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final hint in hints)
            _Chip(
              label: hint.label,
              selected: hint.narrationKey == selectedKey,
              onTap: () => onSelected(hint.narrationKey),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF4E6A)
                : const Color(0xFFE5E7EB),
            width: selected ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.help_outline_rounded,
              size: 13,
              color: selected
                  ? const Color(0xFFFF4E6A)
                  : const Color(0xFF8E95A5),
            ),
            const SizedBox(width: 5),
            // Flexible, not bare: `Wrap` breaks between chips but never inside
            // one, so a label longer than the row — a narrow screen, a large
            // font scale — would overflow rather than wrap.
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? const Color(0xFFFF4E6A)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
