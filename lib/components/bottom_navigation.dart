import 'package:flutter/material.dart';
import 'package:allomom/config/colors.dart';

class CustomBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
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
                  activeIcon: Icons.home,
                  inactiveIcon: Icons.home_outlined,
                  label: 'Home',
                ),
                _buildNavItem(
                  index: 1,
                  activeIcon: Icons.feed,
                  inactiveIcon: Icons.feed_outlined,
                  label: 'Feeds',
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
                  activeIcon: Icons.people,
                  inactiveIcon: Icons.people_outline,
                  label: 'People',
                ),
                _buildNavItem(
                  index: 3,
                  activeIcon: Icons.settings_rounded,
                  inactiveIcon: Icons.settings_outlined,
                  label: 'Settings',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData activeIcon,
    required IconData inactiveIcon,
    required String label,
  }) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: MaterialButton(
        padding: EdgeInsets.zero,
        minWidth: 40,
        onPressed: () => onTap(index),
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
