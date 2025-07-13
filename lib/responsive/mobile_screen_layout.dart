import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:instagram_clone/utils/colors.dart';
import 'package:instagram_clone/utils/global_variable.dart';

class MobileScreenLayout extends StatefulWidget {
  const MobileScreenLayout({super.key});

  @override
  State<MobileScreenLayout> createState() => _MobileScreenLayoutState();
}

class _MobileScreenLayoutState extends State<MobileScreenLayout> {
  int _currentPageIndex = 0;
  late final PageController _pageController;

  // Navigation items configuration
  static const List<_NavItem> _navigationItems = [
    _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
    _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, label: 'Search'),
    _NavItem(icon: Icons.add_circle_outline, activeIcon: Icons.add_circle, label: 'Create'),
    _NavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int pageIndex) {
    if (_currentPageIndex != pageIndex) {
      setState(() {
        _currentPageIndex = pageIndex;
      });
    }
  }

  void _onNavigationTapped(int pageIndex) {
    if (_currentPageIndex != pageIndex) {
      _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        physics: const BouncingScrollPhysics(),
        children: homeScreenItems,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final backgroundColor = getBackgroundColor(context);
    final primaryColor = getPrimaryColor(context);
    final secondaryColor = getSecondaryColor(context);

    return CupertinoTabBar(
      backgroundColor: backgroundColor,
      currentIndex: _currentPageIndex,
      onTap: _onNavigationTapped,
      activeColor: primaryColor,
      inactiveColor: secondaryColor,
      iconSize: 24.0,
      height: 60.0,
      items: _navigationItems.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isActive = _currentPageIndex == index;

        return BottomNavigationBarItem(
          icon: Icon(
            isActive ? item.activeIcon : item.icon,
            color: isActive ? primaryColor : secondaryColor,
          ),
          label: '',
          tooltip: item.label,
        );
      }).toList(),
    );
  }
}

// Private class for navigation item configuration
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}