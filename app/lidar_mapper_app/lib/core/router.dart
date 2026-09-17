// 앱 전체 네비게이션 정의. 게이트(연결) 화면 → 연결 성공 시 4탭 메인 셸.

import 'package:go_router/go_router.dart';

import '../features/connection/connection_screen.dart';
import '../features/diagnostics/diagnostics_screen.dart';
import '../features/sessions/session_list_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/tracking/tracking_screen.dart';
import 'app_shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ConnectionScreen()),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(routes: [
          GoRoute(path: '/home', builder: (context, state) => const DiagnosticsScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/tracking', builder: (context, state) => const TrackingScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/sessions', builder: (context, state) => const SessionListScreen()),
        ]),
        StatefulShellBranch(routes: [
          GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
        ]),
      ],
    ),
  ],
);
