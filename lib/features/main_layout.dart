import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:allomom/config/app_theme.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/components/app_backdrop.dart';
import 'package:allomom/components/bottom_navigation.dart';
import 'package:allomom/components/custom_app_bar.dart';
import 'package:allomom/features/home/home_page.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/settings/settings_page.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/allowear/allowear_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:get/get.dart';
import 'package:allomom/features/allobot/widgets/allobot_mic_button.dart';
import 'package:allomom/features/background_audio/controller/background_audio_controller.dart';
import 'package:allomom/services/allobot/allobaby_live_session.dart';
import 'package:allomom/services/speech_activity.dart';
import 'package:allomom/services/tts_service.dart';
import 'package:allomom/services/part_of_day.dart';
import 'package:allomom/controllers/theme_controller.dart';

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
    // Touching `allowear` registers the controller for the app's lifetime,
    // which reconnects to the remembered band and syncs it — AlloConnect
    // starts it from its main layout the same way.
    allowear;

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
    // The pastel backdrop is Home's alone; the other tabs keep their own.
    // Back never leaves the app by accident: from another tab it goes Home,
    // and from Home it asks first.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return;
        }
        _confirmExit();
      },
      child: AppBackdrop(
        enabled: _currentIndex == 0,
        // Builder, so the shell reads the backdrop from beneath it.
        child: Builder(builder: _buildShell),
      ),
    );
  }

  bool _exitSheetOpen = false;

  Future<void> _confirmExit() async {
    if (_exitSheetOpen) return;
    _exitSheetOpen = true;
    final exit = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ExitSheet(),
    );
    _exitSheetOpen = false;
    if (exit != true) return;
    // Whatever the baby was saying should not carry on after the app closes.
    await SpeechActivity.instance.stopAll();
    await SystemNavigator.pop();
  }

  /// Home's app bar is frosted glass over the time-of-day scene. Over the
  /// dark evening and night rooms the glass is smoked and the title, icons
  /// and status bar go light; by day it is milky with dark text.
  Widget _homeAppBar(BuildContext context, PartOfDay part) {
    final dark = part.isDark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: ThemeController.overlayFor(dark ? Brightness.dark : Brightness.light),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: dark
                    ? [
                        Colors.black.withValues(alpha: 0.38),
                        Colors.black.withValues(alpha: 0.22),
                      ]
                    : [
                        Colors.white.withValues(alpha: 0.55),
                        Colors.white.withValues(alpha: 0.35),
                      ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha: dark ? 0.18 : 0.6),
                  width: 0.8,
                ),
              ),
            ),
            child: Theme(
              data: dark ? AppTheme.dark : AppTheme.light,
              child: CustomAppBar(title: _titles[0]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShell(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // On Home the backdrop behind the shell shows through the bar and page.
      backgroundColor: AppBackdrop.scaffoldColor(
        context,
        context.palette.background,
      ),
      // One app bar for the whole shell: the tabs underneath keep their own
      // scroll views, but the title and her three shortcuts stay put. The tabs
      // do not repeat the title themselves.
      appBar: _currentIndex == 0
          ? PreferredSize(
              preferredSize: const CustomAppBar().preferredSize,
              child: ValueListenableBuilder<PartOfDay>(
                valueListenable: PartOfDayClock.instance,
                builder: (context, part, _) => _homeAppBar(context, part),
              ),
            )
          : CustomAppBar(title: _titles[_currentIndex]),
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
          AlloBabyLiveSession.instance,
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
        // Asked from Home, answered in the AlloBaby card there — Ask Allo
        // itself is a Quick Action.
        if (_currentIndex == 0) {
          HomePage.listen();
          return;
        }
        setState(() => _currentIndex = 0);
        WidgetsBinding.instance.addPostFrameCallback((_) => HomePage.listen());
      },
    );
  }
}

/// "Are you sure?" before Back closes the app from Home.
class _ExitSheet extends StatelessWidget {
  const _ExitSheet();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: p.pick(const Color(0xFFFFF0F3), p.accentSoft),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: primaryColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Exit Allomom?',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: p.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Are you sure you want to exit the app?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(fontSize: 13, color: p.textMuted),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: p.textPrimary,
                      side: BorderSide(color: p.border),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Stay',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Exit',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
