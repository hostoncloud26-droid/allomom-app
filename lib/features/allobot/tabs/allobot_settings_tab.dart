import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/components/language_selector.dart';

class AlloBotSettingsTab extends StatefulWidget {
  const AlloBotSettingsTab({super.key});

  @override
  State<AlloBotSettingsTab> createState() => _AlloBotSettingsTabState();
}

class _AlloBotSettingsTabState extends State<AlloBotSettingsTab> {
  String _selectedModel = 'Gemini 1.5 Flash';
  double _creativityValue = 0.75;
  bool _maternalMemoryEnabled = true;

  String _selectedVoice = 'High-Pitch Baby';
  double _pitchValue = 1.8;
  double _speedValue = 1.1;
  bool _autoSpeakReplies = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ─── HEADER ───
          Text(
            'AlloBot Settings',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E2024),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Configure agent persona, AI intelligence models, speech engines and languages.',
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 18),

          // ─── PERSONA CARD ───
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE4E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text('👶', style: TextStyle(fontSize: 24)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'AlloBot',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF0F3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Primary AI',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF4E6A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Empathetic Maternal Companion',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                      const SizedBox(height: 2),
                      RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            color: const Color(0xFF8E95A5),
                          ),
                          children: const [
                            TextSpan(text: 'Tone: '),
                            TextSpan(
                              text: 'Nurturing',
                              style: TextStyle(
                                color: Color(0xFFFF4E6A),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF6B7280),
                    size: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── SECTION 1: MODEL CONFIG ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.memory_rounded,
                      color: Color(0xFF6366F1),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MODEL CONFIG',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2024),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Select intelligence engine and latency mode',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Model 1: Gemini 1.5 Flash
                _buildModelOption(
                  name: 'Gemini 1.5 Flash',
                  badge: 'Realtime',
                  badgeBg: const Color(0xFFE0F2FE),
                  badgeColor: const Color(0xFF0284C7),
                  desc: 'High speed, real-time voice latency (Recommended)',
                ),
                const SizedBox(height: 10),

                // Model 2: Gemini 1.5 Pro
                _buildModelOption(
                  name: 'Gemini 1.5 Pro',
                  badge: 'Clinical',
                  badgeBg: const Color(0xFFF3E8FF),
                  badgeColor: const Color(0xFF9333EA),
                  desc: 'Deep clinical reasoning & detailed pregnancy analysis',
                ),
                const SizedBox(height: 10),

                // Model 3: Edge Nano Model
                _buildModelOption(
                  name: 'Edge Nano Model',
                  badge: 'Offline',
                  badgeBg: const Color(0xFFE0F2FE),
                  badgeColor: const Color(0xFF0284C7),
                  desc: '100% on-device offline execution, zero cellular data',
                ),

                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF3F4F6), height: 1),
                const SizedBox(height: 14),

                // Creativity & Tone Slider
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Creativity & Tone',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    Text(
                      'Warm & Conversational',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SliderTheme(
                  data: SliderThemeData(
                    activeTrackColor: const Color(0xFF6366F1),
                    inactiveTrackColor: const Color(0xFFE5E7EB),
                    thumbColor: const Color(0xFF6366F1),
                    trackHeight: 5,
                  ),
                  child: Slider(
                    value: _creativityValue,
                    onChanged: (v) => setState(() => _creativityValue = v),
                  ),
                ),

                // Maternal Memory Checkbox
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Maternal Memory',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          Text(
                            'Feed week 24 vitals & symptoms into prompts',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: _maternalMemoryEnabled,
                      activeColor: const Color(0xFFFF4E6A),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) =>
                          setState(() => _maternalMemoryEnabled = val ?? false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── SECTION 2: SPEECH ENGINE (FIXED OVERFLOW) ───
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE5E7EB)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFE4E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.volume_up_rounded,
                        color: Color(0xFFFF4E6A),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SPEECH ENGINE',
                            style: GoogleFonts.poppins(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E2024),
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Text-to-speech voice tone',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Testing voice sample...'),
                            duration: Duration(milliseconds: 900),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD2DC)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFFFF4E6A),
                              size: 14,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Test Voice',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFFF4E6A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 2x2 Voice Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _buildVoiceCard(
                      name: 'High-Pitch Baby',
                      sub: 'Lottie Animated Sync',
                    ),
                    _buildVoiceCard(
                      name: 'Google WaveNet',
                      sub: 'Natural & Warm',
                    ),
                    _buildVoiceCard(
                      name: 'ElevenLabs HD',
                      sub: 'Ultra Real Studio',
                    ),
                    _buildVoiceCard(
                      name: 'Device Native',
                      sub: 'Zero Battery Drain',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Pitch & Speed Sliders Row
                Row(
                  children: [
                    // Pitch
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pitch',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8E95A5),
                                ),
                              ),
                              Text(
                                '${_pitchValue.toStringAsFixed(1)}x',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF4E6A),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFFF4E6A),
                              inactiveTrackColor: const Color(0xFFE5E7EB),
                              thumbColor: const Color(0xFFFF4E6A),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _pitchValue,
                              min: 0.5,
                              max: 2.5,
                              onChanged: (v) =>
                                  setState(() => _pitchValue = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Speed
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Speed',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF8E95A5),
                                ),
                              ),
                              Text(
                                '${_speedValue.toStringAsFixed(1)}x',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFFF4E6A),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: const Color(0xFFFF4E6A),
                              inactiveTrackColor: const Color(0xFFE5E7EB),
                              thumbColor: const Color(0xFFFF4E6A),
                              trackHeight: 4,
                            ),
                            child: Slider(
                              value: _speedValue,
                              min: 0.5,
                              max: 2.0,
                              onChanged: (v) =>
                                  setState(() => _speedValue = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Auto-Speak Replies Checkbox
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-Speak Replies',
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1E2024),
                            ),
                          ),
                          Text(
                            'Read assistant responses aloud automatically',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: const Color(0xFF8E95A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: _autoSpeakReplies,
                      activeColor: const Color(0xFFFF4E6A),
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) =>
                          setState(() => _autoSpeakReplies = val ?? false),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // ─── SECTION 3: REUSABLE LANGUAGE SELECTOR ───
          const LanguageSelector(),

          const SizedBox(height: 100), // Bottom space for bar
        ],
      ),
    );
  }

  Widget _buildModelOption({
    required String name,
    required String badge,
    required Color badgeBg,
    required Color badgeColor,
    required String desc,
  }) {
    final isSelected = _selectedModel == name;

    return GestureDetector(
      onTap: () => setState(() => _selectedModel = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.poppins(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? const Color(0xFFFF4E6A)
                              : const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: GoogleFonts.poppins(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: badgeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    desc,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: const Color(0xFF8E95A5),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFFFF4E6A) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(Icons.check, size: 12, color: Colors.white),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceCard({required String name, required String sub}) {
    final isSelected = _selectedVoice == name;

    return GestureDetector(
      onTap: () => setState(() => _selectedVoice = name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFF0F3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? const Color(0xFFFF4E6A) : const Color(0xFF1E2024),
              ),
            ),
            Text(
              sub,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: const Color(0xFF8E95A5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
