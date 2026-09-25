import 'package:flutter/material.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/components/bottom_navigation.dart';
import 'package:allomom/components/custom_app_bar.dart';
import 'package:allomom/features/home/home_page.dart';
import 'package:allomom/features/allobot/allobot_page.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/settings/settings_page.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:get/get.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/services/speech_activity.dart';
import 'package:allomom/services/tts_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const FeedsPage(),
    const PeoplePage(),
    const SettingsPage(),
  ];

  /// What the shell's app bar says on each tab: the product name on Home,
  /// the tab's own name everywhere else.
  static const _titles = ['Allomom', 'Feeds', 'People', 'Settings'];

  Worker? _offlineWatcher;

  @override
  void initState() {
    super.initState();
    // The promise made during sign-up — "just for this step we need internet"
    // — kept the first time she actually loses it. Once per session, from the
    // shell rather than a page, since the drop can happen on any tab.
    _offlineWatcher = ever<bool>(
      ConnectionController.instance.isInternetAvailableRx,
      (online) {
        if (!online) speak(NarrationKeys.onbOfflineNote);
      },
    );
  }

  @override
  void dispose() {
    _offlineWatcher?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: context.palette.background,
      // One app bar for the whole shell: the tabs underneath keep their own
      // scroll views, but the title and her three shortcuts stay put. The tabs
      // do not repeat the title themselves.
      appBar: CustomAppBar(title: _titles[_currentIndex]),
      body: _pages[_currentIndex],
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // The mic doubles as the baby's off switch: while anything is being said
      // it pulses and shows stop, and a tap silences her instead of opening
      // Ask Allo. Hosted directly rather than in a FloatingActionButton, which
      // would clip the pulse rings to its own bounds.
      floatingActionButton: ListenableBuilder(
        listenable: Listenable.merge([
          _tts.isSpeakingNotifier,
          _tts.isGeneratingNotifier,
        ]),
        builder: (context, _) {
          if (!BackgroundAudioController.isReady) return _micButton(context);
          // Read here so Obx tracks the clip player as well as the voice.
          return Obx(() {
            BackgroundAudioController.to.isPlaying.value;
            return _micButton(context);
          });
        },
      ),
    );
  }

  final TtsService _tts = TtsService();

  Widget _micButton(BuildContext context) {
    final speaking = SpeechActivity.instance.isActive;
    return AlloBotMicButton(
      isListening: speaking,
      isSpeaking: speaking,
      gradient: primaryGradient,
      color: primaryColor,
      onTap: () {
        if (SpeechActivity.instance.isActive) {
          SpeechActivity.instance.stopAll();
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AlloBotPage(autoStartListening: false),
          ),
        );
      },
    );
  }
}
