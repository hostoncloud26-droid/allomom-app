import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/tabs/allobot_ask_ai_tab.dart';
import 'package:allomom/features/allobot/tabs/allobot_agents_tab.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/allobot/tabs/allobot_chat_tab.dart';
import 'package:allomom/features/allobot/tabs/allobot_settings_tab.dart';
import 'package:allomom/features/offline_chatbot/controller/offline_chatbot_controller.dart';
import 'package:allomom/features/offline_chatbot/speech/allobot_speech_controller.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';

class AlloBotPage extends StatefulWidget {
  final int initialTab;
  final bool autoStartListening;

  const AlloBotPage({
    super.key,
    this.initialTab = 0,
    this.autoStartListening = false,
  });

  @override
  State<AlloBotPage> createState() => _AlloBotPageState();
}

class _AlloBotPageState extends State<AlloBotPage> {
  late int _currentIndex;
  final GlobalKey<AlloBotAskAiTabState> _askAiKey =
      GlobalKey<AlloBotAskAiTabState>();
  final ValueNotifier<bool> _isListeningNotifier = ValueNotifier<bool>(false);

  /// The conversation the whole page shares, so the mic can show when the baby
  /// is talking without the Ask Allo tab having to tell it.
  final OfflineChatbotController _chatbot = OfflineChatbotController.instance;

  /// The on-device voice model, so the mic can say when it is not ready yet.
  final AlloBotSpeechController _speech = AlloBotSpeechController.instance;

  /// What the docked mic wears while a reply is being read out.
  static const Color _speakingColor = Color(0xFF10B981);
  static const LinearGradient _speakingGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF059669)],
  );

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;

    if (widget.autoStartListening) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openListeningPopup();
      });
    }
  }

  @override
  void dispose() {
    _isListeningNotifier.dispose();
    super.dispose();
  }

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _openListeningPopup() {
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _askAiKey.currentState?.startListening();
    });
  }

  @override
  Widget build(BuildContext context) {
    // The docked mic and the nav bar both step aside for the keyboard, the way
    // AlloKonnect's shell does, so the composer is the only thing at the
    // bottom of the screen while she is typing.
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.pick(const Color(0xFFFAF6F7), p.scaffoldSoft),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top App Bar for tabs 1 and 3 (Tab 0 and 2 have their own tailored headers)
            if (_currentIndex == 1 || _currentIndex == 3)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _onTabSelected(0),
                      child: Container(
                        width: 35,
                        height: 35,
                        decoration: BoxDecoration(
                          color: p.card,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: p.pick(Colors.black12, p.shadow),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentIndex == 1
                          ? 'Specialized Agents'
                          : 'AlloBot Settings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: p.pick(const Color(0xFF1E2024), p.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

            // Active Tab View
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Tab 0: Ask AI / Ask Allo
                  AlloBotAskAiTab(
                    key: _askAiKey,
                    initialListening: widget.autoStartListening,
                    onListeningChanged: (isListening) {
                      _isListeningNotifier.value = isListening;
                    },
                    onOpenChat: () => _onTabSelected(2),
                  ),

                  // Tab 1: Agents
                  AlloBotAgentsTab(onAskTap: _openListeningPopup),

                  // Tab 2: Chat
                  AlloBotChatTab(onBack: () => _onTabSelected(0)),

                  // Tab 3: Settings
                  const AlloBotSettingsTab(),
                ],
              ),
            ),
          ],
        ),
      ),

      // ─── EXACT SAME NOTCHED BOTTOM BAR AS HOME PAGE ───
      bottomNavigationBar: isKeyboardOpen
          ? null
          : BottomAppBar(
              color: p.card,
              surfaceTintColor: Colors.transparent,
              elevation: 8,
              shape: const CircularNotchedRectangle(),
              notchMargin: 6,
              height: 70,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Row(
                      children: [
                        _buildNavItem(
                          index: 0,
                          activeIcon: Icons.auto_awesome,
                          inactiveIcon: Icons.auto_awesome_outlined,
                          label: 'Ask Allo',
                        ),
                        _buildNavItem(
                          index: 1,
                          activeIcon: Icons.smart_toy,
                          inactiveIcon: Icons.smart_toy_outlined,
                          label: 'Agents',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 80),
                  Expanded(
                    child: Row(
                      children: [
                        _buildNavItem(
                          index: 2,
                          activeIcon: Icons.chat_bubble,
                          inactiveIcon: Icons.chat_bubble_outline,
                          label: 'Chat',
                        ),
                        _buildNavItem(
                          index: 3,
                          activeIcon: Icons.settings,
                          inactiveIcon: Icons.settings_outlined,
                          label: 'Settings',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

      // ─── EXACT SAME FLOATING DOCKED CENTER MIC BUTTON AS HOME PAGE ───
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // The listening animation lives on the mic itself — see
      // [AlloBotMicButton]. A bare FloatingActionButton would clip the pulse
      // rings to its own bounds, so the button is hosted directly.
      //
      // Hidden while the keyboard is up, with the nav bar: the composer is
      // already at the bottom of the screen, and a docked mic over it would sit
      // on the send button.
      floatingActionButton: isKeyboardOpen
          ? null
          : ValueListenableBuilder<bool>(
              valueListenable: _isListeningNotifier,
              builder: (context, isListening, child) {
                return Obx(() {
                  // Speaking turns the mic green, so the control that stops her is
                  // also what shows she is talking.
                  final isSpeaking = _chatbot.isSpeaking.value;
                  // Greyed out while the voice model is still arriving: tapping it
                  // then can only fail, and the ring shows how far along it is.
                  final isFetchingVoice = _speech.isDownloading.value;

                  return AlloBotMicButton(
                    isListening: isListening || isSpeaking,
                    isSpeaking: isSpeaking,
                    gradient: isSpeaking ? _speakingGradient : primaryGradient,
                    color: isSpeaking ? _speakingColor : primaryColor,
                    enabled: !isFetchingVoice,
                    progress: isFetchingVoice
                        ? _speech.downloadProgress.value
                        : null,
                    onTap: () {
                      if (isSpeaking) {
                        // Cuts the line short without throwing the turn away:
                        // a flow waiting on this narration moves on to its
                        // next step, which is what tapping "stop talking"
                        // should do mid-flow. The sheet's own stop button is
                        // still the way to abandon the reply outright.
                        _chatbot.skipNarration();
                        return;
                      }
                      if (_currentIndex != 0) {
                        setState(() {
                          _currentIndex = 0;
                        });
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _askAiKey.currentState?.startListening();
                        });
                      } else {
                        _askAiKey.currentState?.toggleListening();
                      }
                    },
                  );
                });
              },
            ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: MaterialButton(
        padding: EdgeInsets.zero,
        minWidth: 40,
        onPressed: () => _onTabSelected(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? primaryColor : context.palette.navInactive,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? primaryColor : context.palette.navInactive,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
