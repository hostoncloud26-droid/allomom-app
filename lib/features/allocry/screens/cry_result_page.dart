import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:allomom/features/allocry/data/cry_data.dart';
import 'package:allomom/features/allocry/data/cry_record.dart';
import 'package:allomom/features/allocry/screens/cry_history_page.dart';
import 'package:allomom/features/allocry/widgets/cry_audio_player.dart';

/// What AlloCry made of one recording: the cry type, the clip it heard, and
/// what to try.
///
/// The reading is already in the vitals stream by the time this opens — there
/// is no save button, because a cry she has to remember to save is a cry the
/// history will be missing.
class CryResultPage extends StatelessWidget {
  final CryRecord record;

  const CryResultPage({super.key, required this.record});

  static const Color _pink = Color(0xFFFF4E6A);

  @override
  Widget build(BuildContext context) {
    final type = record.type;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.background,
      appBar: AppBar(
        backgroundColor: p.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: _pink),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'AlloCry Result',
          style: GoogleFonts.outfit(
            color: _pink,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cry history',
            onPressed: () => Get.to(() => const CryHistoryPage()),
            icon: const Icon(Icons.history_rounded, color: _pink),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(type, p),
            const SizedBox(height: 18),
            _buildPlayerCard(type, p),
            const SizedBox(height: 18),
            _buildWhatItSoundsLike(type, p),
            const SizedBox(height: 18),
            _buildRecommendations(type, p),
            const SizedBox(height: 20),
            _buildSavedNote(p),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(CryType type, AppPalette p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            type.color.withValues(alpha: 0.14),
            type.color.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: type.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              type.image,
              height: 160,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                type.icon,
                size: 90,
                color: type.color,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Probable reason',
            style: GoogleFonts.poppins(fontSize: 12.5, color: p.pick(const Color(0xFF8C93A3), p.textMuted)),
          ),
          const SizedBox(height: 4),
          Text(
            type.heading,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: p.pick(const Color(0xFF1E2229), p.textPrimary),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('${record.confidenceLabel} match', type.color),
              _chip(record.confidenceBand, p.pick(const Color(0xFF6B7280), p.textSecondary)),
              _chip(
                DateFormat('d MMM, h:mm a').format(record.recordedAt),
                p.pick(const Color(0xFF6B7280), p.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            type.shortDescription,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: p.pick(const Color(0xFF4A4E5A), p.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPlayerCard(CryType type, AppPalette p) {
    return _card(
      p: p,
      title: 'The recording',
      icon: Icons.graphic_eq_rounded,
      color: type.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CryAudioPlayer(audioFile: record.audioFile, color: type.color),
          if (record.soundLabels.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'Sounds heard',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: p.pick(const Color(0xFF6B7280), p.textSecondary),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: record.soundLabels
                  .take(4)
                  .map((label) => _chip(label, p.pick(const Color(0xFF6B7280), p.textSecondary)))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWhatItSoundsLike(CryType type, AppPalette p) {
    return _card(
      p: p,
      title: 'What this cry sounds like',
      icon: Icons.hearing_rounded,
      color: type.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in type.description)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!line.bold) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Icon(
                        Icons.favorite_rounded,
                        size: 12,
                        color: type.color,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      line.text,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        fontWeight:
                            line.bold ? FontWeight.w600 : FontWeight.w400,
                        color: line.bold
                            ? p.pick(const Color(0xFF1E2229), p.textPrimary)
                            : p.pick(const Color(0xFF4A4E5A), p.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(CryType type, AppPalette p) {
    final items = type.recommendations;
    return _card(
      p: p,
      title: 'What you can try',
      icon: Icons.tips_and_updates_rounded,
      color: type.color,
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++)
            Container(
              margin: EdgeInsets.only(bottom: i == items.length - 1 ? 0 : 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.pick(const Color(0xFFF9FAFC), p.inputFill),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.pick(const Color(0xFFEEF0F4), p.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: type.color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i],
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        height: 1.5,
                        color: p.pick(const Color(0xFF4A4E5A), p.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSavedNote(AppPalette p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.tint(const Color(0xFF10B981), const Color(0xFFF3FBF6)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.pick(const Color(0xFFD6F0E0),
              const Color(0xFF10B981).withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved to your cry history with the recording. '
              'The analysis ran on your phone — the audio never left it.',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                height: 1.45,
                color: p.pick(const Color(0xFF3D6B55), const Color(0xFF9FD8B8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required AppPalette p,
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.pick(const Color(0xFFEEF0F4), p.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 15.5,
                  fontWeight: FontWeight.bold,
                  color: p.pick(const Color(0xFF2C2F38), p.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
