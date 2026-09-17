// 연결 성공 후 진입하는 메인 화면 뼈대 — 하단 탭 4개(홈/트래킹/목록/설정).
// go_router의 StatefulShellRoute가 각 탭의 화면 상태를 탭 전환 후에도
// 유지해준다(예: 목록 탭에서 스크롤하다 다른 탭 갔다 와도 위치 유지).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _tabs = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: '홈'),
    (icon: Icons.radar_outlined, selectedIcon: Icons.radar, label: '트래킹'),
    (icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, label: '목록'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: '설정'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // 같은 탭을 다시 누르면 그 탭의 첫 화면으로 리셋
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}
