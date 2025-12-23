import 'package:flutter/material.dart';
import 'user_home_page.dart';
import 'dashboard_page.dart'; 
import 'leaderboard_page.dart';

class UserMainLayout extends StatefulWidget {
  const UserMainLayout({super.key});

  @override
  State<UserMainLayout> createState() => _UserMainLayoutState();
}

class _UserMainLayoutState extends State<UserMainLayout> {
  int _currentIndex = 0;

  // Define pages as a late variable to ensure they are created when needed
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      UserHomePage(onTabChange: _onTabTapped), // Tab 0
      const DashboardPage(),                   // Tab 1
      const LeaderboardPage(),                 // Tab 2
    ];
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Use IndexedStack to keep the state of pages (like quiz progress) alive
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view),
            label: 'Quiz',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
        ],
      ),
    );
  }
}