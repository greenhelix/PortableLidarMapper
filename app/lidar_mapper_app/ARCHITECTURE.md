# Flutter 앱 구조 문서

> 코딩은 Claude가 진행하고, 이 문서는 매 단계마다 갱신됩니다. 코드를 직접
> 안 치셔도 이 문서만 보면 전체 구조/흐름을 파악할 수 있게 유지합니다.
>
> 시각화 버전(Artifact): https://claude.ai/code/artifact/432e945f-9964-4c5c-a6dd-c3f4a149b147

## 전체 흐름 (게이트 → 4탭 메인 셸)

```mermaid
flowchart TD
    START([앱 시작]) --> GATE[연결 화면\nConnectionScreen]
    GATE -- rosbridge 연결 성공 --> SHELL[메인 셸\nBottomNavigationBar]
    SHELL --> HOME[홈(진단)\n라이다/IMU/OP/배터리 상태]
    SHELL --> TRACK[트래킹\n스캔 레이더+지도, 시작/정지]
    SHELL --> LIST[목록\n저장된 세션, 완성도%, 좌표]
    SHELL --> SETTINGS[설정\n연결변경, 필터프리셋, 가이드]
```

## 레이어 구조 (기능마다 반복되는 4단 패턴)

```mermaid
flowchart LR
    V[View\n위젯] --> VM[ViewModel\nRiverpod StateNotifier]
    VM --> R[Repository\n도메인 API]
    R --> S["core/ros_bridge_client\n(rosbridge 통신 창구, 공용)"]
```

- **View**: 화면(위젯), 상태를 표시하고 사용자 입력을 ViewModel에 전달만 함
- **ViewModel**: 상태 보관 + 비즈니스 로직, View는 이걸 통해서만 화면을 그림
- **Repository**: "세션 목록 가져오기" 같은 도메인 용어로 서비스 호출을 감쌈
- **core/ros_bridge_client**: 실제 WebSocket 통신 — 앱 전체에서 이거 하나만 씀

## 파일 트리 (진행 상황 표시: ✅완료 / 🚧진행중 / ⬜예정)

```
lib/
├── main.dart                              ✅ 앱 진입점, ProviderScope+GoRouter 연결
├── core/
│   ├── ros_bridge_client.dart             ✅ rosbridge WebSocket 통신 (connect/send/disconnect)
│   ├── router.dart                        ✅ 게이트→4탭 셸 라우팅 정의(go_router)
│   └── app_shell.dart                     ✅ 하단 탭 4개 네비게이션 셸(NavigationBar)
├── features/
│   ├── connection/                        ✅ 게이트 화면(Tier1-2), 연결 성공 시 /home 이동
│   │   ├── connection_screen.dart
│   │   └── connection_viewmodel.dart
│   ├── diagnostics/                       🚧 홈(진단) 탭 — Tier1-4 (지금은 빈 뼈대)
│   │   └── diagnostics_screen.dart
│   ├── tracking/                          🚧 트래킹 탭 — Tier1-3,6 (지금은 빈 뼈대)
│   │   └── tracking_screen.dart           (다음: 레이더+지도 CustomPainter)
│   ├── sessions/                          🚧 목록 탭 — Tier2-7,8 (지금은 빈 뼈대)
│   │   └── session_list_screen.dart
│   └── settings/                          🚧 설정 탭 — Tier1-2,7 + 가이드 (지금은 빈 뼈대)
│       └── settings_screen.dart
└── demo/                                   (참고용 HTML 데모, 코드 아님)
```

## 변경 로그
- 2026-09-17: 문서 최초 작성, 연결 화면까지 완료 상태 반영
- 2026-09-17: 게이트→4탭 셸 네비게이션 뼈대 완성(`router.dart`, `app_shell.dart`,
  4개 탭 placeholder 화면). `flutter analyze`/`flutter test` 통과 확인.
  다음 단계: 각 탭 placeholder를 실제 기능으로 하나씩 교체(홈/진단부터).
- 2026-09-17: 구조 문서를 Claude Artifact로도 게시(위 링크). 이후 이 문서를
  수정할 때마다 Artifact도 같이 갱신.
