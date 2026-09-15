import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:allomom/features/allocry/data/cry_data.dart';

/// Everything AlloCry knows about one kind of cry, with a sample she can play.
///
/// Reached from the home grid, so a mother can learn the cries before she ever
/// records one — and can compare a sample against what she is hearing now.
class CryTypeDetailPage extends StatefulWidget {
  final CryType type;

  const CryTypeDetailPage({super.key, required this.type});

  @override
  State<CryTypeDetailPage> createState() => _CryTypeDetailPageState();
}

class _CryTypeDetailPageState extends State<CryTypeDetailPage> {
  final AudioPlayer _player = AudioPlayer();
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _playing = state == PlayerState.playing);
    });
  }

  Future<void> _toggleSample() async {
    final sample = widget.type.sampleAudio;
    if (sample == null) return;
    if (_playing) {
      await _player.stop();
    } else {
      await _player.play(AssetSource(sample));
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final type = widget.type;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: type.color),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          type.heading,
          style: GoogleFonts.outfit(
            color: type.color,
            fontSize: 19,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: type.color.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: type.color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Image.asset(
                    type.image,
                    height: 150,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        Icon(type.icon, size: 84, color: type.color),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    type.shortDescription,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.55,
                      color: const Color(0xFF4A4E5A),
                    ),
                  ),
                  if (type.sampleAudio != null) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _toggleSample,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: type.color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      icon: Icon(
                        _playing ? Icons.stop_rounded : Icons.volume_up_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: Text(
                        _playing ? 'Stop sample' : 'Hear this cry',
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),
            _card(
              title: 'How to recognise it',
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
                              child: Icon(Icons.favorite_rounded,
                                  size: 12, color: type.color),
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
                                    ? const Color(0xFF1E2229)
                                    : const Color(0xFF4A4E5A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _card(
              title: 'What you can try',
              icon: Icons.tips_and_updates_rounded,
              color: type.color,
              child: Column(
                children: [
                  for (int i = 0; i < type.recommendations.length; i++)
                    Container(
                      margin: EdgeInsets.only(
                          bottom: i == type.recommendations.length - 1 ? 0 : 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEEF0F4)),
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
                              type.recommendations[i],
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                height: 1.5,
                                color: const Color(0xFF4A4E5A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEEF0F4)),
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
                  color: const Color(0xFF2C2F38),
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
