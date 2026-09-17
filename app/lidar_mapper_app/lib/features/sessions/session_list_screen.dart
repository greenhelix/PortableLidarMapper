// 목록 탭 — Tier2-7,8. 저장된 세션 목록(세션명/완성도%/좌표) + 상단 저장공간 표시.
// TODO: DB 서비스(get_sessions) 연동 후 실제 목록으로 채울 예정.

import 'package:flutter/material.dart';

class SessionListScreen extends StatelessWidget {
  const SessionListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('목록')),
      body: const Center(child: Text('저장된 세션 목록 (다음 단계에서 구현)')),
    );
  }
}
