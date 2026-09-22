import 'package:flutter/material.dart';
import 'package:allomom/config/colors.dart';
import 'package:allomom/components/bottom_navigation.dart';
import 'package:allomom/features/home/home_page.dart';
import 'package:allomom/features/allobot/allobot_page.dart';
import 'package:allomom/features/feeds/feeds_page.dart';
import 'package:allomom/features/people/people_page.dart';
import 'package:allomom/features/settings/settings_page.dart';
import 'package:allomom/controllers/connection_controller.dart';
import 'package:allomom/features/background_audio/data/narration_keys.dart';
import 'package:allomom/features/background_audio/widgets/baby_narration.dart';
import 'package:get/get.dart';

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.transparent,
        elevation: 0,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AlloBotPage(autoStartListening: false),
            ),
          );
        },
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: primaryGradient,
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}
