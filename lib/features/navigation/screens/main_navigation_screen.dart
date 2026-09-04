import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../alerts/screens/alerts_screen.dart';
import '../../analytics/screens/analytics_screen.dart';
import '../../devices/screens/devices_screen.dart';
import '../../govt/screens/govt_water_quality_map_screen.dart';
import '../../home/screens/home_screen.dart';
import '../../profile/screens/profile_screen.dart';

import '../../../providers/auth_provider.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class MainNavigationScreen extends ConsumerWidget {
  const MainNavigationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isGovtAuthority = user?.isGovtAuthority ?? false;
    final rawIndex = ref.watch(selectedTabProvider);

    final List<Widget> screens = [
      const HomeScreen(),
      if (isGovtAuthority) const GovtWaterQualityMapScreen(),
      const AnalyticsScreen(),
      const AlertsScreen(),
      const DevicesScreen(),
      const ProfileScreen(),
    ];

    final currentIndex = rawIndex >= screens.length ? 0 : rawIndex;

    final List<BottomNavigationBarItem> navItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Home',
      ),
      if (isGovtAuthority)
        const BottomNavigationBarItem(
          icon: Icon(Icons.map_outlined),
          activeIcon: Icon(Icons.map_rounded),
          label: 'Govt Map 🏛️',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart_outlined),
        activeIcon: Icon(Icons.bar_chart),
        label: 'Analytics',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.notifications_outlined),
        activeIcon: Icon(Icons.notifications),
        label: 'Alerts',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.developer_board_outlined),
        activeIcon: Icon(Icons.developer_board),
        label: 'Devices',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          ref.read(selectedTabProvider.notifier).state = index;
        },
        type: BottomNavigationBarType.fixed,
        items: navItems,
      ),
    );
  }
}
