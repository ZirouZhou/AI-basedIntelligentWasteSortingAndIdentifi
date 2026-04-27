// ------------------------------------------------------------------------------------------------
// EcoSort AI Flutter App — Bottom-Navigation Shell
// ------------------------------------------------------------------------------------------------
//
// [AppShell] is the main scaffold that hosts the six top-level pages of the
// EcoSort AI app. It provides a [NavigationBar] at the bottom and uses an
// [IndexedStack] to preserve the state of each page when the user switches
// between tabs.
//
// Pages registered:
//   0. HomePage       – dashboard with green score and sorting guide
//   1. ClassifyPage   – AI-based waste classification
//   2. RewardsPage    – eco actions and reward store
//   3. CommunityPage  – community forum
//   4. MessagesPage   – in-app message inbox
//   5. ProfilePage    – user profile and settings
// ------------------------------------------------------------------------------------------------

import 'package:flutter/material.dart';

import '../features/classify/classify_page.dart';
import '../features/community/community_page.dart';
import '../features/home/home_page.dart';
import '../features/messages/messages_page.dart';
import '../features/profile/profile_page.dart';
import '../features/rewards/rewards_page.dart';

/// The persistent shell that holds the bottom navigation bar and the six
/// top-level feature pages.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.userId,
  });

  final String userId;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  /// Index of the currently selected navigation destination.
  int _selectedIndex = 0;
  final ValueNotifier<int> _profileDataRefreshSignal =
      ValueNotifier<int>(0);

  @override
  void dispose() {
    _profileDataRefreshSignal.dispose();
    super.dispose();
  }

  void _notifyProfileDataRefresh() {
    _profileDataRefreshSignal.value++;
  }

  void _selectTab(int index) {
    if (index < 0 || index > 5) {
      return;
    }
    setState(() => _selectedIndex = index);
  }

  /// The six top-level pages, built once and kept alive by [IndexedStack].
  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomePage(
        userId: widget.userId,
        onNavigateToTab: _selectTab,
        profileDataRefreshSignal: _profileDataRefreshSignal,
      ),
      ClassifyPage(
        userId: widget.userId,
        onClassificationSuccess: _notifyProfileDataRefresh,
      ),
      RewardsPage(
        userId: widget.userId,
        onPointsUpdated: _notifyProfileDataRefresh,
      ),
      CommunityPage(userId: widget.userId),
      MessagesPage(userId: widget.userId),
      ProfilePage(
        userId: widget.userId,
        profileDataRefreshSignal: _profileDataRefreshSignal,
      ),
    ];

    return Scaffold(
      // Body: display only the selected page, but keep all pages alive.
      body: SafeArea(
        child: IndexedStack(
          index: _selectedIndex,
          children: pages,
        ),
      ),
      // Material 3 bottom navigation bar.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Classify',
          ),
          NavigationDestination(
            icon: Icon(Icons.emoji_events_outlined),
            selectedIcon: Icon(Icons.emoji_events),
            label: 'Rewards',
          ),
          NavigationDestination(
            icon: Icon(Icons.forum_outlined),
            selectedIcon: Icon(Icons.forum),
            label: 'Forum',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Messages',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
