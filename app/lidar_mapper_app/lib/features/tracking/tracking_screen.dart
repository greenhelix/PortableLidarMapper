// 트래킹 탭 — Tier1-3(시작/정지) + Tier1-6(레이더+지도 뷰어).
// TODO: scan_monitor_preview.html 데모의 CustomPainter 버전을 다음 단계에서 구현.

import 'package:flutter/material.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('트래킹')),
      body: const Center(child: Text('스캔 레이더 + 누적지도 (다음 단계에서 구현)')),
    );
  }
}
