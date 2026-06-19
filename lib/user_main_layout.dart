import 'dart:ui';
import 'package:flutter/material.dart';
import 'user_home_page.dart';
import 'dashboard_page.dart';
import 'leaderboard_page.dart';
import 'app_theme.dart';

class UserMainLayout extends StatefulWidget {
  const UserMainLayout({super.key});

  @override
  State<UserMainLayout> createState() => _UserMainLayoutState();
}

class _UserMainLayoutState extends State<UserMainLayout>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _navController;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _pages = [
      UserHomePage(onTabChange: _onTabTapped),
      const DashboardPage(),
      const LeaderboardPage(),
    ];
  }

  @override
  void dispose() {
    _navController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    _navController.reset();
    _navController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withAlpha(160)
                  : Colors.white.withAlpha(210),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withAlpha(20)
                      : Colors.black.withAlpha(15),
                ),
              ),
            ),
            child: NavigationBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              indicatorColor: AppColors.purple.withAlpha(50),
              destinations: [
                _navItem(Icons.home_outlined, Icons.home_rounded, 'Home', 0),
                _navItem(Icons.grid_view_outlined, Icons.grid_view_rounded,
                    'Quiz', 1),
                _navItem(Icons.leaderboard_outlined,
                    Icons.leaderboard_rounded, 'Ranks', 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _navItem(
      IconData outline, IconData filled, String label, int index) {
    final isSelected = _currentIndex == index;
    return NavigationDestination(
      icon: Icon(outline,
          color: isSelected ? AppColors.purple : Colors.grey, size: 24),
      selectedIcon: Icon(filled, color: AppColors.purple, size: 26),
      label: label,
    );
  }
}
