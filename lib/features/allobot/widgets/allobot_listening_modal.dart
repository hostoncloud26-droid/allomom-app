import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

class AlloBotListeningModal extends StatefulWidget {
  final VoidCallback onOpenChat;
  final Function(String response)? onSpeechProcessed;

  const AlloBotListeningModal({
    super.key,
    required this.onOpenChat,
    this.onSpeechProcessed,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onOpenChat,
    Function(String response)? onSpeechProcessed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AlloBotListeningModal(
        onOpenChat: onOpenChat,
        onSpeechProcessed: onSpeechProcessed,
      ),
    );
  }

  @override
  State<AlloBotListeningModal> createState() => _AlloBotListeningModalState();
}

class _AlloBotListeningModalState extends State<AlloBotListeningModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  Timer? _simulatedTimer;
  String _liveTranscript = 'Listening... Speak clearly into your mic';

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Simulate speech detection
    _simulatedTimer = Timer(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          _liveTranscript = '"Why does the baby kick more after I eat?"';
        });
      }
    });
  }

  @override
  void dispose() {
    _waveController.dispose();
    _simulatedTimer?.cancel();
    super.dispose();
  }

  void _finishListening() {
    widget.onSpeechProcessed?.call(
      'Babies kick more after you eat because your blood glucose levels rise, giving them a surge of natural energy! ❤️',
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Top Row: Title + Close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFF4E6A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AlloBot is Listening...',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF3F4F6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Animated Baby in Glowing Pink Ring
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return Container(
                      width: 140 + (_waveController.value * 20),
                      height: 140 + (_waveController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4E6A).withValues(alpha: 0.12),
                      ),
                    );
                  },
                ),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFE4E9),
                    border: Border.all(
                      color: const Color(0xFFFF4E6A),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: Lottie.asset(
                        'assets/animations/Baby Speaking F.json',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/Baby3D.png',
                            fit: BoxFit.contain,
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Live Transcript Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD2DC)),
              ),
              child: Column(
                children: [
                  Text(
                    _liveTranscript,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFF4E6A),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Soundwaves animation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildWave(12),
                      const SizedBox(width: 4),
                      _buildWave(22),
                      const SizedBox(width: 4),
                      _buildWave(32),
                      const SizedBox(width: 4),
                      _buildWave(18),
                      const SizedBox(width: 4),
                      _buildWave(28),
                      const SizedBox(width: 4),
                      _buildWave(14),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Action Buttons Row
            Row(
              children: [
                // Keyboard / Type instead
                Expanded(
                  flex: 5,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onOpenChat();
                    },
                    icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
                    label: Text(
                      'Type instead',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4B5563),
                      side: const BorderSide(color: Color(0xFFD1D5DB)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Stop & Process Button
                Expanded(
                  flex: 6,
                  child: ElevatedButton.icon(
                    onPressed: _finishListening,
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: Text(
                      'Done Speaking',
                      style: GoogleFonts.poppins(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5277),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildWave(double maxHeight) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final height = (maxHeight * _waveController.value).clamp(6.0, maxHeight);
        return Container(
          width: 4,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4E6A),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }
}
