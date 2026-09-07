import 'package:flutter/material.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/features/allobot/tabs/allobot_ask_ai_tab.dart';
import 'package:allomom/features/allobot/tabs/allobot_agents_tab.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/allobot/tabs/allobot_chat_tab.dart';
import 'package:allomom/features/allobot/tabs/allobot_settings_tab.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F7),
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
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Color(0xFF1E2024),
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _currentIndex == 1
                          ? 'Specialized Agents'
                          : 'AlloBot Settings',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E2024),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.wifi_rounded,
                            color: Color(0xFF059669),
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'HIGH BANDWIDTH',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF059669),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
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
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
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
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _isListeningNotifier,
        builder: (context, isListening, child) {
          return AlloBotMicButton(
            isListening: isListening,
            gradient: primaryGradient,
            color: primaryColor,
            onTap: () {
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
              color: isSelected ? primaryColor : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? primaryColor : Colors.grey,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
