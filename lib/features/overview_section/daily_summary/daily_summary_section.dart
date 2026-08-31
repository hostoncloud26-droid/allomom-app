import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/colors.dart';

class DailySummarySection extends StatelessWidget {
  const DailySummarySection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily summary',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            Text(
              'Tuesday, 11 Aug',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'You have finished 3 of 5 care tasks so far. A few more glasses of water and we are on track today.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: textMedium,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SYNCED FROM ALLOWEAR',
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        _buildSyncedVitalsRow(),
      ],
    );
  }

  Widget _buildSyncedVitalsRow() {
    final vitals = [
      {'icon': Icons.directions_walk, 'value': '4,218', 'label': 'Steps', 'color': primaryColor},
      {'icon': Icons.nightlight_round, 'value': '7h 20m', 'label': 'Sleep', 'color': const Color(0xff6C63FF)},
      {'icon': Icons.favorite, 'value': '82 bpm', 'label': 'Heart rate', 'color': primaryColor},
      {'icon': Icons.water_drop, 'value': '98%', 'label': 'SpO2', 'color': const Color(0xff26C6DA)},
    ];

    return Row(
      children: vitals.map((v) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: (v['color'] as Color).withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(v['icon'] as IconData, color: v['color'] as Color, size: 18),
                const SizedBox(height: 6),
                Text(
                  v['value'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: v['color'] as Color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  v['label'] as String,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: textLight,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
