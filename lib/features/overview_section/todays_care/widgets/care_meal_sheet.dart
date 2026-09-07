import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/overview_section/todays_care/care_day_part.dart';

/// What the user entered for a meal.
class CareMealLog {
  const CareMealLog({required this.calories, required this.details});

  final double calories;
  final String details;
}

/// Bottom sheet for logging a meal in the current time window. Offers a few
/// portion presets (so a check-in is one tap) and falls back to typing an
/// exact calorie count.
class CareMealSheet extends StatefulWidget {
  const CareMealSheet({
    super.key,
    required this.meal,
    required this.color,
    required this.icon,
    this.suggestion,
  });

  final CareMeal meal;
  final Color color;
  final IconData icon;

  /// Trimester-aware tip shown under the title.
  final String? suggestion;

  static Future<CareMealLog?> show(
    BuildContext context, {
    required CareMeal meal,
    required Color color,
    required IconData icon,
    String? suggestion,
  }) {
    return showModalBottomSheet<CareMealLog>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CareMealSheet(
        meal: meal,
        color: color,
        icon: icon,
        suggestion: suggestion,
      ),
    );
  }

  @override
  State<CareMealSheet> createState() => _CareMealSheetState();
}

class _CareMealSheetState extends State<CareMealSheet> {
  late final TextEditingController _detailsController;
  late final TextEditingController _caloriesController;

  /// Portion multipliers applied to the meal's typical calorie count.
  static const _portions = <({String label, String emoji, double factor})>[
    (label: 'Light', emoji: '🥗', factor: 0.6),
    (label: 'Balanced', emoji: '🍱', factor: 1.0),
    (label: 'Heavy', emoji: '🍛', factor: 1.45),
  ];

  int _selectedPortion = 1;
  bool _isCustomCalories = false;

  int _caloriesFor(int portionIndex) =>
      (widget.meal.typicalCalories * _portions[portionIndex].factor).round();

  @override
  void initState() {
    super.initState();
    _detailsController = TextEditingController();
    _caloriesController = TextEditingController(
      text: _caloriesFor(_selectedPortion).toString(),
    );
  }

  @override
  void dispose() {
    _detailsController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _selectPortion(int index) {
    setState(() {
      _selectedPortion = index;
      _isCustomCalories = false;
      _caloriesController.text = _caloriesFor(index).toString();
    });
  }

  void _submit() {
    final typed = double.tryParse(_caloriesController.text.trim());
    final calories = typed ?? _caloriesFor(_selectedPortion).toDouble();
    final portion = _portions[_selectedPortion];
    final typedDetails = _detailsController.text.trim();

    Navigator.pop(
      context,
      CareMealLog(
        calories: calories,
        details: typedDetails.isNotEmpty
            ? typedDetails
            : '${portion.label} ${widget.meal.label.toLowerCase()}',
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    const border = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
      borderSide: BorderSide(color: Color(0xFFE2E8F0)),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.manrope(
        fontSize: 13,
        color: const Color(0xFF94A3B8),
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(14)),
        borderSide: BorderSide(color: widget.color, width: 1.4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        14,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32),
          topRight: Radius.circular(32),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log ${widget.meal.label}',
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      if (widget.suggestion != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.suggestion!,
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              'Portion',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (var i = 0; i < _portions.length; i++) ...[
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _selectPortion(i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedPortion == i
                              ? widget.color.withValues(alpha: 0.12)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _selectedPortion == i
                                ? widget.color
                                : const Color(0xFFE2E8F0),
                            width: _selectedPortion == i ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _portions[i].emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _portions[i].label,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _selectedPortion == i
                                    ? widget.color
                                    : const Color(0xFF475569),
                              ),
                            ),
                            Text(
                              '~${_caloriesFor(i)} kcal',
                              style: GoogleFonts.manrope(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (i != _portions.length - 1) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),

            Text(
              'What did you have? (optional)',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _detailsController,
              style: GoogleFonts.manrope(fontSize: 13.5),
              decoration: _fieldDecoration(
                'e.g. Oats porridge with almonds & milk',
              ),
            ),
            const SizedBox(height: 14),

            GestureDetector(
              onTap: () =>
                  setState(() => _isCustomCalories = !_isCustomCalories),
              child: Row(
                children: [
                  Icon(
                    _isCustomCalories
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_right_rounded,
                    size: 20,
                    color: const Color(0xFF64748B),
                  ),
                  Text(
                    'Enter exact calories',
                    style: GoogleFonts.manrope(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
            if (_isCustomCalories) ...[
              const SizedBox(height: 8),
              TextField(
                controller: _caloriesController,
                keyboardType: TextInputType.number,
                style: GoogleFonts.manrope(fontSize: 13.5),
                decoration: _fieldDecoration('e.g. 350').copyWith(
                  suffixText: 'kcal',
                  suffixStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 22),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save ${widget.meal.label}',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
