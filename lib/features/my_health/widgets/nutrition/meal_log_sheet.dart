import 'package:flutter/material.dart';

import 'package:allomom/config/app_theme.dart';
import 'package:allomom/controllers/health_vital_controller.dart';

/// My Health's "Log meal" sheet: a description and a kcal figure, saved as
/// one `addVitalEntry` under [mealType] (`breakfast`, `lunch`, `dinner`,
/// `snacks`) with `data: {'items', 'meal'}`. Resolves to true when saved.
Future<bool> showMealLogSheet(
  BuildContext context, {
  required String mealType,
  required String label,
  required Color color,
  required IconData icon,
  required String userId,
}) async {
  final calController = TextEditingController();
  final itemController = TextEditingController();

  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      final p = ctx.palette;
      InputDecoration field(String hint) => InputDecoration(
            hintStyle: TextStyle(color: p.textMuted),
            hintText: hint,
            filled: true,
            fillColor: p.pick(const Color(0xFFF8FAFC), p.inputFill),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: p.pick(const Color(0xFFE2E8F0), p.border),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: p.pick(const Color(0xFFE2E8F0), p.border),
              ),
            ),
          );
      final labelStyle = TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: p.pick(const Color(0xFF475569), p.textSecondary),
      );

      return Container(
        padding: EdgeInsets.fromLTRB(
          24,
          20,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 30,
        ),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: p.pick(const Color(0xFFE2E8F0), p.divider),
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
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  'Log $label',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Meal Description / Food Items', style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: itemController,
              style: TextStyle(color: p.textPrimary),
              decoration: field('e.g. Oats porridge with almonds & milk'),
            ),
            const SizedBox(height: 14),
            Text('Calories (kcal)', style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              controller: calController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: p.textPrimary),
              decoration: field('e.g. 350'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final cal =
                      double.tryParse(calController.text.trim()) ?? 300.0;
                  final text = itemController.text.trim();

                  await HealthVitalsController.instance.addVitalEntry(
                    key: mealType.toLowerCase(),
                    value: cal,
                    unit: 'kcal',
                    createdAt: DateTime.now(),
                    userId: userId,
                    data: {'items': text, 'meal': label},
                  );

                  if (ctx.mounted) Navigator.pop(ctx, true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save $label',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
  return saved == true;
}
