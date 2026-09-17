// 설정 탭 — Tier1-2(연결 변경),Tier1-7(필터 프리셋), 가이드(용어 설명집).
// TODO: 각 세부 화면은 다음 단계에서 구현.

import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: const [
          ListTile(leading: Icon(Icons.wifi), title: Text('연결 주소 변경'), subtitle: Text('다음 단계에서 구현')),
          ListTile(leading: Icon(Icons.tune), title: Text('환경 프리셋 + 필터 조절'), subtitle: Text('다음 단계에서 구현')),
          ListTile(leading: Icon(Icons.menu_book), title: Text('가이드 (용어/옵션 설명집)'), subtitle: Text('다음 단계에서 구현')),
        ],
      ),
    );
  }
}
