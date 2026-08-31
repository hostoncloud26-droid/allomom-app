import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:allomom/services/tts_service.dart';
import 'package:allomom/components/baby_hero_banner.dart';
import 'package:allomom/features/kick_counter/kick_counter_page.dart';
import 'package:allomom/features/allocry/allocry_page.dart';
import 'package:allomom/features/reports/reports_page.dart';
import 'package:allomom/features/my_health/my_health_page.dart';
import 'package:allomom/features/prescriptions/prescriptions_page.dart';
import 'package:allomom/features/pregnancy/anc_schedule_page.dart';
import 'package:allomom/features/pregnancy/vaccination_schedule_page.dart';
import 'package:allomom/features/pregnancy/pregnancy_journey_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/settings/settings_page.dart';
import 'package:allomom/features/feeding_tracker/feeding_tracker_page.dart';

enum AlloBotScreenState {
  listening,
  featureMatched,
  showOpenButton,
  generalResponse,
}

class AlloBotAskAiTab extends StatefulWidget {
  final VoidCallback onOpenChat;
  final VoidCallback? onOpenMenu;
  final bool initialListening;
  final ValueChanged<bool>? onListeningChanged;

  const AlloBotAskAiTab({
    super.key,
    required this.onOpenChat,
    this.onOpenMenu,
    this.initialListening = false,
    this.onListeningChanged,
  });

  @override
  State<AlloBotAskAiTab> createState() => AlloBotAskAiTabState();
}

class AlloBotAskAiTabState extends State<AlloBotAskAiTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  AlloBotScreenState _screenState = AlloBotScreenState.listening;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _liveTranscript = '';
  String _matchedFeatureName = '';
  String _matchedFeatureDesc = '';
  String _matchedFeatureType = '';
  String _generalResponseText = '';
  Timer? _stateTransitionTimer;
  Timer? _voiceDebounceTimer;

  final List<Map<String, String>> _quickSuggestions = [
    {'title': '👶 My baby is kicking', 'query': 'baby is kicking'},
    {'title': '😭 My baby is crying', 'query': 'baby is crying'},
    {'title': '📄 View my lab reports', 'query': 'lab reports'},
    {'title': '🩺 Check my health vitals', 'query': 'my health vitals'},
    {'title': '💊 Pregnancy prescriptions', 'query': 'prescriptions'},
    {'title': '🏥 Doctor ANC schedule', 'query': 'anc schedule'},
    {'title': '💉 Vaccination schedule', 'query': 'vaccination schedule'},
    {'title': '🌟 Pregnancy journey', 'query': 'pregnancy journey'},
    {'title': '👨‍👩‍👧 My family & contacts', 'query': 'my family'},
    {'title': '⚙️ App settings & language', 'query': 'settings'},
    {'title': '🍼 Baby feeding tracker', 'query': 'feeding tracker'},
    {'title': '🥗 Healthy pregnancy diet', 'query': 'healthy diet for week 24'},
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
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
            widget.onListeningChanged?.call(false);
            _waveController.stop();
          }
        },
        onStatus: (String status) {
          debugPrint('STT Status: $status');
          if (mounted) {
            if (status == 'listening') {
              setState(() {
                _isListening = true;
              });
              widget.onListeningChanged?.call(true);
              if (!_waveController.isAnimating) {
                _waveController.repeat(reverse: true);
              }
            } else if (status == 'notListening' || status == 'done') {
              setState(() {
                _isListening = false;
              });
              widget.onListeningChanged?.call(false);
              _waveController.stop();
            }
          }
        },
      );
    } catch (e) {
      debugPrint('Error initializing STT: $e');
      _speechEnabled = false;
    }

    if (mounted) {
      startListening();
    }
  }

  void startListening() async {
    _stateTransitionTimer?.cancel();
    _voiceDebounceTimer?.cancel();
    setState(() {
      _screenState = AlloBotScreenState.listening;
      _liveTranscript = '';
      _isListening = true;
    });
    widget.onListeningChanged?.call(true);
    if (!_waveController.isAnimating) {
      _waveController.repeat(reverse: true);
    }

    if (_speechEnabled) {
      try {
        await _speechToText.listen(
          onResult: (result) {
            if (mounted) {
              setState(() {
                _liveTranscript = result.recognizedWords;
              });

              final words = result.recognizedWords.toLowerCase().trim();
              final hasKeyword = words.contains('kick') ||
                  words.contains('kicking') ||
                  words.contains('cry') ||
                  words.contains('crying') ||
                  words.contains('report') ||
                  words.contains('health') ||
                  words.contains('vitals') ||
                  words.contains('prescription') ||
                  words.contains('medicine') ||
                  words.contains('anc') ||
                  words.contains('checkup') ||
                  words.contains('vaccin') ||
                  words.contains('injection') ||
                  words.contains('journey') ||
                  words.contains('family') ||
                  words.contains('people') ||
                  words.contains('setting') ||
                  words.contains('language') ||
                  words.contains('profile') ||
                  words.contains('feed') ||
                  words.contains('eat') ||
                  words.contains('diet') ||
                  words.contains('water');

              if (hasKeyword) {
                _voiceDebounceTimer?.cancel();
                _voiceDebounceTimer =
                    Timer(const Duration(milliseconds: 700), () {
                  if (mounted &&
                      _screenState == AlloBotScreenState.listening) {
                    _processVoiceQuery(result.recognizedWords);
                  }
                });
              } else if (result.finalResult) {
                _processVoiceQuery(result.recognizedWords);
              }
            }
          },
          listenOptions: stt.SpeechListenOptions(
            listenMode: stt.ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
          ),
        );
      } catch (e) {
        debugPrint('Error in STT listen: $e');
      }
    }
  }

  void stopListening() async {
    _stateTransitionTimer?.cancel();
    _voiceDebounceTimer?.cancel();
    _waveController.stop();
    if (_speechEnabled) {
      try {
        await _speechToText.stop();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _isListening = false;
      });
      widget.onListeningChanged?.call(false);
    }
  }

  void toggleListening() {
    if (_isListening) {
      stopListening();
      _ttsService.stop();
    } else {
      startListening();
    }
  }

  @override
  void dispose() {
    _stateTransitionTimer?.cancel();
    _voiceDebounceTimer?.cancel();
    _waveController.dispose();
    try {
      _speechToText.stop();
    } catch (_) {}
    _ttsService.stop();
    super.dispose();
  }

  void _processVoiceQuery(String text) {
    final lower = text.toLowerCase().trim();
    if (lower.isEmpty) return;

    // 1. Kick Counter
    if (lower.contains('kick') ||
        lower.contains('kicking') ||
        lower.contains('baby is moving') ||
        lower.contains('baby move') ||
        lower.contains('count kick')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Kick Counter',
        featureDesc: "Count and track your baby's kicks",
        featureType: 'kick',
        promptSpeech: "I noticed your baby is kicking! Would you like to record kicks in the Kick Counter?",
        confirmSpeech: "Okay mom, use this Kick Counter feature",
      );
      return;
    }

    // 2. AlloCry
    if (lower.contains('cry') ||
        lower.contains('crying') ||
        lower.contains('tears') ||
        lower.contains('weeping')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'AlloCry',
        featureDesc: "Identify why your baby is crying with AI",
        featureType: 'cry',
        promptSpeech: "AlloCry can help you Amma. We'll find out why baby is crying.",
        confirmSpeech: "Opening AlloCry for you, Amma",
      );
      return;
    }

    // 3. Lab / Medical Reports
    if (lower.contains('report') ||
        lower.contains('reports') ||
        lower.contains('lab') ||
        lower.contains('blood test') ||
        lower.contains('scan') ||
        lower.contains('ultrasound')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Medical Reports',
        featureDesc: "View all your lab tests and medical scan reports",
        featureType: 'report',
        promptSpeech: "I found your medical and lab reports, Amma. Would you like to view them?",
        confirmSpeech: "Opening your medical reports, Amma",
      );
      return;
    }

    // 4. My Health & Vitals
    if (lower.contains('my health') ||
        lower.contains('vitals') ||
        lower.contains('blood pressure') ||
        lower.contains('heart rate') ||
        lower.contains('sleep') ||
        lower.contains('steps') ||
        lower.contains('hrv') ||
        lower.contains('oxygen') ||
        lower.contains('bmi') ||
        lower == 'health') {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'My Health Vitals',
        featureDesc: "Track your blood pressure, sleep, heart rate, and vitals",
        featureType: 'health',
        promptSpeech: "Here is your Health Overview with all vitals and metrics, Amma.",
        confirmSpeech: "Opening your Health Vitals dashboard, Amma",
      );
      return;
    }

    // 5. Prescriptions & Medicines
    if (lower.contains('prescription') ||
        lower.contains('medicine') ||
        lower.contains('tablet') ||
        lower.contains('pill') ||
        lower.contains('medication') ||
        lower.contains('dosage') ||
        lower.contains('iron') ||
        lower.contains('folic acid')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Prescriptions',
        featureDesc: "View your daily pregnancy medicines and dosages",
        featureType: 'prescription',
        promptSpeech: "I found your doctor's prescriptions and pregnancy medicines, Amma.",
        confirmSpeech: "Opening your Prescriptions page, Amma",
      );
      return;
    }

    // 6. ANC Care / Doctor Checkups
    if (lower.contains('anc') ||
        lower.contains('checkup') ||
        lower.contains('antenatal') ||
        lower.contains('doctor visit') ||
        lower.contains('clinic visit') ||
        lower.contains('appointment')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'ANC Care Schedule',
        featureDesc: "View your upcoming doctor checkups and ANC clinic visits",
        featureType: 'anc',
        promptSpeech: "Here is your Antenatal Care checkup schedule, Amma.",
        confirmSpeech: "Opening your ANC Care Schedule, Amma",
      );
      return;
    }

    // 7. Vaccination Schedule
    if (lower.contains('vaccin') ||
        lower.contains('immuniz') ||
        lower.contains('injection') ||
        lower.contains('shots') ||
        lower.contains('tetanus') ||
        lower.contains('tt injection')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Vaccination Schedule',
        featureDesc: "Track all pregnancy vaccines and immunization dates",
        featureType: 'vaccine',
        promptSpeech: "Here is your vaccination and immunization schedule, Amma.",
        confirmSpeech: "Opening your Vaccination Schedule, Amma",
      );
      return;
    }

    // 8. My Pregnancy Journey
    if (lower.contains('journey') ||
        lower.contains('pregnancy journey') ||
        lower.contains('my pregnancy') ||
        lower.contains('progress') ||
        lower.contains('trimester') ||
        lower.contains('milestone') ||
        lower.contains('baby growth')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Pregnancy Journey',
        featureDesc: "Track your week-by-week baby development and milestones",
        featureType: 'journey',
        promptSpeech: "Here is your complete Pregnancy Journey and baby milestones, Amma.",
        confirmSpeech: "Opening your Pregnancy Journey, Amma",
      );
      return;
    }

    // 9. My Family & People Section
    if (lower.contains('family') ||
        lower.contains('people') ||
        lower.contains('husband') ||
        lower.contains('partner') ||
        lower.contains('doctor contact') ||
        lower.contains('nurse contact') ||
        lower.contains('emergency contact') ||
        lower.contains('caregiver')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'My Family & People',
        featureDesc: "Manage your care circle, partner details, and emergency contacts",
        featureType: 'family',
        promptSpeech: "Here are your family members, doctor contacts, and caregivers, Amma.",
        confirmSpeech: "Opening My Family and People section, Amma",
      );
      return;
    }

    // 10. Settings / Edit Profile / Language
    if (lower.contains('setting') ||
        lower.contains('profile') ||
        lower.contains('edit profile') ||
        lower.contains('language') ||
        lower.contains('change language') ||
        lower.contains('preference') ||
        lower.contains('account')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Settings & Profile',
        featureDesc: "Manage your profile, change language, and configure app settings",
        featureType: 'settings',
        promptSpeech: "Here are your App Settings where you can edit profile and change language, Amma.",
        confirmSpeech: "Opening Settings for you, Amma",
      );
      return;
    }

    // 11. Feeding Tracker
    if (lower.contains('feed') ||
        lower.contains('feeding') ||
        lower.contains('breastfeed') ||
        lower.contains('bottle feed') ||
        lower.contains('formula') ||
        lower.contains('nursing')) {
      _handleFeatureMatch(
        transcript: text,
        featureName: 'Feeding Tracker',
        featureDesc: "Track breastfeeding and bottle feeds for your baby",
        featureType: 'feed',
        promptSpeech: "Would you like to record baby feeding in the Feeding Tracker, Amma?",
        confirmSpeech: "Opening Feeding Tracker for you, Amma",
      );
      return;
    }

    // 12. General Health, Diet & Nutrition Advice
    if (lower.contains('eat') ||
        lower.contains('food') ||
        lower.contains('diet') ||
        lower.contains('meal') ||
        lower.contains('water') ||
        lower.contains('swelling') ||
        lower.length > 6) {
      stopListening();
      String reply =
          "That's completely normal for week 24, Amma! Stay hydrated with 8-10 glasses of water and rest well.";
      if (lower.contains('eat') || lower.contains('food') || lower.contains('diet')) {
        reply =
            "For week 24, focus on iron & calcium rich foods: fresh spinach, lentils, ragi, curd, and citrus fruits!";
      } else if (lower.contains('water') || lower.contains('hydrat')) {
        reply =
            "Aim for 8 to 10 glasses of water daily, Amma! Hydration supports healthy amniotic fluid levels.";
      }

      setState(() {
        _screenState = AlloBotScreenState.generalResponse;
        _liveTranscript = text;
        _generalResponseText = reply;
      });

      _ttsService.speak(reply);
    }
  }

  void _handleFeatureMatch({
    required String transcript,
    required String featureName,
    required String featureDesc,
    required String featureType,
    required String promptSpeech,
    required String confirmSpeech,
  }) {
    stopListening();
    setState(() {
      _screenState = AlloBotScreenState.featureMatched;
      _liveTranscript = transcript;
      _matchedFeatureName = featureName;
      _matchedFeatureDesc = featureDesc;
      _matchedFeatureType = featureType;
    });

    _ttsService.speak(
      promptSpeech,
      onComplete: () {
        if (mounted && _screenState == AlloBotScreenState.featureMatched) {
          _showOpenButtonForFeature(
            featureName,
            featureType,
            confirmSpeech,
          );
        }
      },
    );

    // Auto transition to button after short delay if TTS is skipped or finished
    _stateTransitionTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted && _screenState == AlloBotScreenState.featureMatched) {
        _showOpenButtonForFeature(
          featureName,
          featureType,
          confirmSpeech,
        );
      }
    });
  }

  void _showOpenButtonForFeature(String featureName, String featureType, String speechText) {
    setState(() {
      _screenState = AlloBotScreenState.showOpenButton;
      _matchedFeatureName = featureName;
      _matchedFeatureType = featureType;
    });
    _ttsService.speak(speechText);
  }

  void _navigateToMatchedFeature() {
    _ttsService.stop();
    Widget? targetPage;

    switch (_matchedFeatureType) {
      case 'kick':
        targetPage = const KickCounterPage();
        break;
      case 'cry':
        targetPage = const AlloCryPage();
        break;
      case 'report':
        targetPage = const ReportsPage();
        break;
      case 'health':
        targetPage = const MyHealthPage();
        break;
      case 'prescription':
        targetPage = const PrescriptionsPage();
        break;
      case 'anc':
        targetPage = const AncSchedulePage();
        break;
      case 'vaccine':
        targetPage = const VaccinationSchedulePage();
        break;
      case 'journey':
        targetPage = const PregnancyJourneyPage();
        break;
      case 'family':
        targetPage = const PeoplePage();
        break;
      case 'settings':
        targetPage = const SettingsPage();
        break;
      case 'feed':
        targetPage = const FeedingTrackerPage();
        break;
    }

    if (targetPage != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => targetPage!),
      );
    }
  }

  void _showSuggestionsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Voice Assistant Topics',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1E2024),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0F3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tap to speak',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF4E6A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _quickSuggestions.length,
                    itemBuilder: (context, index) {
                      final item = _quickSuggestions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(ctx);
                            _processVoiceQuery(item['query']!);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF5F7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFFD2DC)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item['title']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: const Color(0xFF1E2024),
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Color(0xFFFF8A9E),
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ─── TOP APP BAR ───
            _buildTopAppBar(),
            const SizedBox(height: 2),

            // ─── 1. TOP BABY HERO CARD (Standard 270px matching Home Page) ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _buildBabyHeroCard(),
            ),
            const SizedBox(height: 12),

            // ─── 2. IN-PLACE INTERACTIVE VOICE CONTAINER (Fills space to bottom) ───
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: _buildVoiceInteractiveCard(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── TOP APP BAR ───
  Widget _buildTopAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Row(
        children: [
          // Back Button
          GestureDetector(
            onTap: () {
              _ttsService.stop();
              Navigator.maybePop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Color(0xFFFF4E6A),
                size: 22,
              ),
            ),
          ),

          // Center Title & Subtitle
          Expanded(
            child: Column(
              children: [
                Text(
                  'AlloBot',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFFF4E6A),
                  ),
                ),
                Text(
                  'Your empathetic pregnancy companion',
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: const Color(0xFF8E95A5),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 40), // Balancer
        ],
      ),
    );
  }

  // ─── 1. TOP BABY HERO CARD (Standard 270px) ───
  Widget _buildBabyHeroCard() {
    return const BabyHeroBanner(
      speechText: "Good Morning, Amma ❤️",
      bubblePosition: SpeechBubblePosition.topCenter,
      height: 270,
    );
  }

  // ─── 2. IN-PLACE INTERACTIVE VOICE CONTAINER ───
  Widget _buildVoiceInteractiveCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // "How can I support you and your baby today?"
          Text(
            'How can I support you and your baby today?',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),

          // Dynamic Middle Content Area (Centered)
          Expanded(
            child: Center(
              child: _buildDynamicVoiceContent(),
            ),
          ),

          // In-Card Bottom Controls (Plus, Keyboard)
          _buildInCardBottomControls(),
        ],
      ),
    );
  }

  // ─── IN-CARD BOTTOM CONTROLS (+, Keyboard) ───
  Widget _buildInCardBottomControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 1. Left "+" Suggestions Button
        GestureDetector(
          onTap: _showSuggestionsModal,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0F3),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFFD2DC)),
            ),
            child: const Icon(
              Icons.add_rounded,
              color: Color(0xFFFF4E6A),
              size: 24,
            ),
          ),
        ),

        // 2. Right Keyboard Button (Type instead -> Open Chat Tab)
        GestureDetector(
          onTap: () {
            _ttsService.stop();
            widget.onOpenChat();
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.keyboard_alt_outlined,
              color: Color(0xFF374151),
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ─── DYNAMIC VOICE CONTENT (Listening -> Matched -> Open Button) ───
  Widget _buildDynamicVoiceContent() {
    switch (_screenState) {
      // 1. Matched State: "[Feature Name] can help you Amma ❤️"
      case AlloBotScreenState.featureMatched:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1E2024),
                  height: 1.25,
                ),
                children: [
                  TextSpan(
                    text: '$_matchedFeatureName ',
                    style: const TextStyle(color: Color(0xFFFF4E6A)),
                  ),
                  const TextSpan(text: 'can\nhelp you Amma ❤️'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _matchedFeatureDesc,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: const Color(0xFF8E95A5),
              ),
            ),
            const SizedBox(height: 12),
            if (_liveTranscript.isNotEmpty)
              Text(
                _liveTranscript,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFFFF8A9E),
                  fontStyle: FontStyle.italic,
                ),
              ),
          ],
        );

      // 2. Open Button State: "Open [Feature Name]"
      case AlloBotScreenState.showOpenButton:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: _navigateToMatchedFeature,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF4E6A),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF4E6A).withValues(alpha: 0.35),
                      blurRadius: 18,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  'Open $_matchedFeatureName',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        );

      // 3. General AI Response State
      case AlloBotScreenState.generalResponse:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _generalResponseText,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E2024),
                height: 1.45,
              ),
            ),
          ],
        );

      // 4. Default Listening State: Animated Waveform + Transcript
      case AlloBotScreenState.listening:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Smooth Animated Waveform Bars
            _buildAnimatedWaveform(),
            const SizedBox(height: 18),

            // Live recognized speech text: e.g. "My Baby is kicking"
            if (_liveTranscript.isNotEmpty)
              _buildHighlightedTranscript()
            else
              Text(
                _isListening ? 'Listening...' : 'Tap the mic to speak',
                style: GoogleFonts.poppins(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _isListening
                      ? const Color(0xFF6B7280)
                      : const Color(0xFF9CA3AF),
                ),
              ),
          ],
        );
    }
  }

  // Highlighted Transcript with active keyword styling
  Widget _buildHighlightedTranscript() {
    final words = _liveTranscript.trim().split(RegExp(r'\s+'));
    final lastWord = words.isNotEmpty ? words.last : '';
    final previousWords = words.length > 1
        ? words.sublist(0, words.length - 1).join(' ')
        : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0F3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD2DC)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: GoogleFonts.poppins(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF4B5563),
          ),
          children: [
            if (previousWords.isNotEmpty) TextSpan(text: '$previousWords '),
            TextSpan(
              text: lastWord,
              style: const TextStyle(
                color: Color(0xFFFF4E6A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Animated Waveform Bars
  Widget _buildAnimatedWaveform() {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        final val = _isListening ? _waveController.value : 0.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildSingleWaveBar(12 + (val * 14)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(18 + (val * 16)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(28 + (val * 18)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(38 + (val * 14)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(22 + (val * 20)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(32 + (val * 16)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(42 + (val * 12)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(26 + (val * 18)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(36 + (val * 14)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(20 + (val * 16)),
            const SizedBox(width: 4),
            _buildSingleWaveBar(14 + (val * 12)),
          ],
        );
      },
    );
  }

  Widget _buildSingleWaveBar(double height) {
    return Container(
      width: 5,
      height: _isListening ? height.clamp(8.0, 52.0) : 8.0,
      decoration: BoxDecoration(
        color: _isListening ? const Color(0xFFFF6584) : const Color(0xFFFFC0CE),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
