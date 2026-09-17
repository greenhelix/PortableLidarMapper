// 홈(진단) 탭 — Tier1-4. 라이다/IMU/Orange Pi/배터리 상태를 한눈에 보여준다.
// TODO: 다음 단계에서 실제 상태 표시 위젯으로 채울 예정 (지금은 뼈대만).

import 'package:flutter/material.dart';

class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('홈 · 기기 진단')),
      body: const Center(child: Text('라이다 / IMU / Orange Pi / 배터리 상태 (다음 단계에서 구현)')),
    );
  }
}
