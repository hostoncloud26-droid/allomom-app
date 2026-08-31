import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/colors.dart';

class TodaysCareSection extends StatefulWidget {
  const TodaysCareSection({super.key});

  @override
  State<TodaysCareSection> createState() => _TodaysCareSectionState();
}

class _TodaysCareSectionState extends State<TodaysCareSection> {
  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.local_hospital, 'title': 'ANC check-up', 'subtitle': 'Thursday at Kallur PHC', 'done': true, 'color': const Color(0xff6C63FF)},
    {'icon': Icons.medication, 'title': 'Iron tablet', 'subtitle': 'After lunch', 'done': true, 'color': primaryColor},
    {'icon': Icons.water_drop_outlined, 'title': 'Drink water', 'subtitle': '5 of 8 glasses', 'done': true, 'color': const Color(0xff26C6DA)},
    {'icon': Icons.child_friendly, 'title': 'Count my kicks', 'subtitle': 'Once a day', 'done': false, 'color': primaryColor},
    {'icon': Icons.favorite_border, 'title': 'How do you feel?', 'subtitle': 'Log any symptoms', 'done': false, 'color': primaryColor},
  ];

  int get _doneCount => _items.where((i) => i['done'] == true).length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Today's care",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            Text(
              '$_doneCount of ${_items.length} done today',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._items.map((item) => _buildCareItem(item)),
      ],
    );
  }

  Widget _buildCareItem(Map<String, dynamic> item) {
    final isDone = item['done'] as bool;
    final color = item['color'] as Color;

    return GestureDetector(
      onTap: () {
        setState(() {
          item['done'] = !isDone;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDone ? Colors.white : accentLight,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textDark,
                    ),
                  ),
                  Text(
                    item['subtitle'] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: textLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isDone)
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: successGreen,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 18),
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
