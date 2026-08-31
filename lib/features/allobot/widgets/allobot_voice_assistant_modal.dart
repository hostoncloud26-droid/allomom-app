import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:allomom/services/tts_service.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';

enum VoiceAssistantState {
  listening,
  processing,
  botAskingKickConfirmation,
  botPromptingKickCounter,
  generalResponse,
}

class AlloBotVoiceAssistantModal extends StatefulWidget {
  final VoidCallback onOpenChat;
  final Function(String response)? onSpeechProcessed;

  const AlloBotVoiceAssistantModal({
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
      builder: (ctx) => AlloBotVoiceAssistantModal(
        onOpenChat: onOpenChat,
        onSpeechProcessed: onSpeechProcessed,
      ),
    );
  }

  @override
  State<AlloBotVoiceAssistantModal> createState() =>
      _AlloBotVoiceAssistantModalState();
}

class _AlloBotVoiceAssistantModalState extends State<AlloBotVoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  VoiceAssistantState _state = VoiceAssistantState.listening;
  String _liveTranscript = 'Listening... Speak into your mic';
  String _botMessage = '';
  bool _speechEnabled = false;
  bool _isListening = false;
  Timer? _silenceTimer;

  final List<String> _quickSuggestions = [
    '👶 My baby is kicking',
    '🦶 I need to go to kick count',
    '🥗 Healthy meals for week 24',
    '💧 How much water should I drink?',
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _initSpeechAndStartListening();
  }

  Future<void> _initSpeechAndStartListening() async {
    await _ttsService.init();

    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('STT Error: ${error.errorMsg}');
          if (mounted) {
            setState(() {
              _isListening = false;
            });
          }
        },
        onStatus: (String status) {
          debugPrint('STT Status: $status');
          if (mounted) {
            setState(() {
              _isListening = status == 'listening';
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing STT: $e');
      _speechEnabled = false;
    }

    if (mounted) {
      _startListening();
    }
  }

  void _startListening() async {
    _silenceTimer?.cancel();
    if (_speechEnabled) {
      setState(() {
        _isListening = true;
        _liveTranscript = 'Listening... Speak clearly';
      });

      try {
        await _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _liveTranscript = result.recognizedWords;
              });

              if (result.finalResult || result.recognizedWords.isNotEmpty) {
                _processUserSpeech(result.recognizedWords);
              }
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.confirmation,
            partialResults: true,
            cancelOnError: true,
          ),
        );
      } catch (e) {
        debugPrint('Error starting speech listen: $e');
      }
    } else {
      setState(() {
        _isListening = true;
        _liveTranscript = 'Listening... (Tap a suggestion or speak)';
      });
    }
  }

  void _stopListening() async {
    _silenceTimer?.cancel();
    if (_speechEnabled) {
      try {
        await _speechToText.stop();
      } catch (e) {
        debugPrint('Error stopping STT: $e');
      }
    }
    if (mounted) {
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _animController.dispose();
    try {
      _speechToText.stop();
    } catch (_) {}
    _ttsService.stop();
    super.dispose();
  }

  void _processUserSpeech(String speech) {
    final lower = speech.toLowerCase().trim();

    // Check if we are waiting for kick confirmation (Yes / No)
    if (_state == VoiceAssistantState.botAskingKickConfirmation) {
      if (lower.contains('yes') ||
          lower.contains('yeah') ||
          lower.contains('sure') ||
          lower.contains('okay') ||
          lower.contains('ok') ||
          lower.contains('open') ||
          lower.contains('count') ||
          lower.contains('please') ||
          lower.contains('yep')) {
        _onConfirmKickCounter();
        return;
      } else if (lower.contains('no') ||
          lower.contains('cancel') ||
          lower.contains('not now') ||
          lower.contains('later')) {
        _onDeclineKickCounter();
        return;
      }
    }

    // Check if speech relates to baby kicking or kick counter
    final isKickTrigger = lower.contains('kick') ||
        lower.contains('kicking') ||
        lower.contains('baby is moving') ||
        lower.contains('baby move') ||
        lower.contains('count kick');

    if (isKickTrigger) {
      _triggerKickConfirmationFlow(speech);
      return;
    }

    // Check other general topics
    if (lower.contains('eat') ||
        lower.contains('food') ||
        lower.contains('meal') ||
        lower.contains('diet')) {
      _triggerGeneralResponse(
        speech,
        "For week 24, focus on nutrient-dense meals rich in iron, calcium, and protein like spinach, curd, lentils, and fresh fruits!",
      );
    } else if (lower.contains('water') || lower.contains('hydrat')) {
      _triggerGeneralResponse(
        speech,
        "Aim for 8 to 10 glasses of water daily, Amma! Hydration supports healthy amniotic fluid levels.",
      );
    } else if (speech.isNotEmpty && lower.length > 5) {
      _triggerGeneralResponse(
        speech,
        "I'm here for you and baby, Amma! Feel free to ask about baby kicks, nutrition, or your daily health.",
      );
    }
  }

  void _triggerKickConfirmationFlow(String userText) {
    _stopListening();
    const botPrompt =
        "I noticed your baby is kicking! Would you like to record kicks in the Kick Counter?";

    setState(() {
      _state = VoiceAssistantState.botAskingKickConfirmation;
      _liveTranscript = '"$userText"';
      _botMessage = botPrompt;
    });

    _ttsService.speak(botPrompt, onComplete: () {
      if (mounted && _state == VoiceAssistantState.botAskingKickConfirmation) {
        // Resume listening for the "Yes" confirmation
        _startListening();
      }
    });
  }

  void _onConfirmKickCounter() {
    _stopListening();
    const botResponse = "Okay mom, use this Kick Counter feature";

    setState(() {
      _state = VoiceAssistantState.botPromptingKickCounter;
      _botMessage = botResponse;
    });

    _ttsService.speak(botResponse);
  }

  void _onDeclineKickCounter() {
    _stopListening();
    const response = "No problem, Amma! Let me know if you need anything else.";
    setState(() {
      _state = VoiceAssistantState.generalResponse;
      _botMessage = response;
    });
    _ttsService.speak(response);
  }

  void _triggerGeneralResponse(String userText, String response) {
    _stopListening();
    setState(() {
      _state = VoiceAssistantState.generalResponse;
      _liveTranscript = '"$userText"';
      _botMessage = response;
    });

    _ttsService.speak(response);
  }

  void _navigateToKickCounter() {
    _ttsService.stop();
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const KickCounterPage()),
    );
  }

  void _resetToListening() {
    _ttsService.stop();
    setState(() {
      _state = VoiceAssistantState.listening;
      _botMessage = '';
      _liveTranscript = 'Listening... Speak into your mic';
    });
    _startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 30,
            offset: Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag notch
              Container(
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 16),

              // Header: Status + Close button
              _buildHeader(),
              const SizedBox(height: 18),

              // Baby Avatar with Concentric Glowing Pulse & Lottie
              _buildAvatarVisualizer(),
              const SizedBox(height: 18),

              // Active State Content (Listening / Asking Confirmation / Kick Counter Card / General)
              _buildStateContent(),
              const SizedBox(height: 18),

              // Bottom Action Controls
              _buildBottomControls(),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    String statusTitle = 'AlloBot Voice';
    Color dotColor = const Color(0xFFFF4E6A);

    if (_state == VoiceAssistantState.listening) {
      statusTitle = 'AlloBot is Listening...';
      dotColor = const Color(0xFF10B981);
    } else if (_state == VoiceAssistantState.botAskingKickConfirmation ||
        _state == VoiceAssistantState.botPromptingKickCounter) {
      statusTitle = 'AlloBot Speaking...';
      dotColor = const Color(0xFFFF4E6A);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.5),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              statusTitle,
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E2024),
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () {
            _ttsService.stop();
            Navigator.pop(context);
          },
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
    );
  }

  Widget _buildAvatarVisualizer() {
    final isBotTalking =
        _state == VoiceAssistantState.botAskingKickConfirmation ||
        _state == VoiceAssistantState.botPromptingKickCounter ||
        _ttsService.isSpeaking;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Concentric glowing pulse ring 1
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final scale = 1.0 + (_animController.value * 0.22);
            return Container(
              width: 140 * scale,
              height: 140 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4E6A).withValues(
                  alpha: 0.08 * (1.0 - _animController.value),
                ),
              ),
            );
          },
        ),

        // Concentric glowing pulse ring 2
        AnimatedBuilder(
          animation: _animController,
          builder: (context, child) {
            final scale = 1.0 + (_animController.value * 0.12);
            return Container(
              width: 125 * scale,
              height: 125 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.14),
              ),
            );
          },
        ),

        // Center Baby Circle Container
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F3), Color(0xFFFFE2E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: const Color(0xFFFF4E6A),
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.25),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: SizedBox(
              width: 85,
              height: 85,
              child: Lottie.asset(
                isBotTalking
                    ? 'assets/animations/Baby Speaking F.json'
                    : 'assets/animations/Baby Non Speaking Final.json',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/allobaby/AlloMombaby.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.child_care_rounded,
                      size: 48,
                      color: Color(0xFFFF4E6A),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStateContent() {
    switch (_state) {
      case VoiceAssistantState.botPromptingKickCounter:
        return _buildKickCounterActionCard();
      case VoiceAssistantState.botAskingKickConfirmation:
        return _buildKickConfirmationView();
      case VoiceAssistantState.generalResponse:
        return _buildGeneralResponseView();
      case VoiceAssistantState.listening:
      case VoiceAssistantState.processing:
        return _buildListeningTranscriptView();
    }
  }

  // 1. Listening Transcript View + Quick Suggestions
  Widget _buildListeningTranscriptView() {
    return Column(
      children: [
        // Transcript Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F7),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFD2DC)),
          ),
          child: Column(
            children: [
              Text(
                _liveTranscript,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E2024),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Animated Sound Waves
              _buildAnimatedSoundWaves(),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Suggestion Chips for Testing & Instant Input
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Or tap to speak:',
            style: GoogleFonts.poppins(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8E95A5),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _quickSuggestions.map((suggestion) {
            final cleanText = suggestion.replaceAll(RegExp(r'[^\w\s]'), '').trim();
            return GestureDetector(
              onTap: () {
                _processUserSpeech(cleanText);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  suggestion,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF374151),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // 2. Question View: "I noticed your baby is kicking! Would you like to record kicks in Kick Counter?"
  Widget _buildKickConfirmationView() {
    return Column(
      children: [
        // User transcript
        if (_liveTranscript.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _liveTranscript,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF4B5563),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

        // Bot Voice Bubble
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF0F3), Color(0xFFFFE8EE)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFC0CE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.record_voice_over_rounded,
                    color: Color(0xFFFF4E6A),
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _botMessage,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E2024),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAnimatedSoundWaves(),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Yes / No Confirmation Buttons
        Row(
          children: [
            // No button
            Expanded(
              flex: 4,
              child: OutlinedButton(
                onPressed: _onDeclineKickCounter,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: Color(0xFFD1D5DB)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Not Now',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Yes button
            Expanded(
              flex: 6,
              child: ElevatedButton.icon(
                onPressed: _onConfirmKickCounter,
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: Text(
                  'Yes, Count Kicks',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4E6A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 3. Kick Counter Navigation Card: "Okay mom, use this Kick Counter feature"
  Widget _buildKickCounterActionCard() {
    return Column(
      children: [
        // TTS Bot Speech Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFECFDF5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFA7F3D0)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.volume_up_rounded,
                color: Color(0xFF059669),
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '“$_botMessage”',
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Interactive Kick Counter Feature Card
        GestureDetector(
          onTap: _navigateToKickCounter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF0F3), Color(0xFFFFE1E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFFFF4E6A).withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4E6A).withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                // Kick Counter Icon Container
                Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF4E6A).withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/allobaby/KickCounter.png',
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(
                      Icons.directions_walk_rounded,
                      color: Color(0xFFFF4E6A),
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Card Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kick Counter',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF1E2024),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Track active hours & record baby movements',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          color: const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),

                // Arrow icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF4E6A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Glowing Big Navigation Button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _navigateToKickCounter,
            icon: const Icon(Icons.touch_app_rounded, size: 20),
            label: Text(
              'Open Kick Counter Now',
              style: GoogleFonts.poppins(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4E6A),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0x60FF4E6A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 4. General Response View
  Widget _buildGeneralResponseView() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5F7),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFFFD2DC)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _botMessage,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1E2024),
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => _ttsService.speak(_botMessage),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE4E9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.volume_up_rounded,
                            color: Color(0xFFFF4E6A),
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Replay',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF4E6A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _resetToListening,
                icon: const Icon(Icons.mic, size: 18),
                label: const Text('Ask Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF4E6A),
                  side: const BorderSide(color: Color(0xFFFF4E6A)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  _ttsService.stop();
                  Navigator.pop(context);
                  widget.onOpenChat();
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                label: const Text('Open Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E2024),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimatedSoundWaves() {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        final val = _animController.value;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildWaveBar(10 + (val * 14)),
            const SizedBox(width: 4),
            _buildWaveBar(18 + (val * 12)),
            const SizedBox(width: 4),
            _buildWaveBar(28 + (val * 10)),
            const SizedBox(width: 4),
            _buildWaveBar(14 + (val * 16)),
            const SizedBox(width: 4),
            _buildWaveBar(24 + (val * 8)),
            const SizedBox(width: 4),
            _buildWaveBar(12 + (val * 14)),
          ],
        );
      },
    );
  }

  Widget _buildWaveBar(double height) {
    return Container(
      width: 4,
      height: height.clamp(6.0, 36.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFF4E6A),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Row(
      children: [
        // Type Instead / Open Chat
        Expanded(
          flex: 5,
          child: OutlinedButton.icon(
            onPressed: () {
              _ttsService.stop();
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
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Mic Restart / Done button
        Expanded(
          flex: 6,
          child: ElevatedButton.icon(
            onPressed: () {
              if (_isListening) {
                _stopListening();
              } else {
                _resetToListening();
              }
            },
            icon: Icon(
              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
              size: 18,
            ),
            label: Text(
              _isListening ? 'Stop Listening' : 'Speak Again',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isListening
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFFF4E6A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
