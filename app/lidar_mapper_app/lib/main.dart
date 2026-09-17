import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/connection/connection_screen.dart';

void main() {
  // ProviderScope: 앱 전체에서 Riverpod provider들을 사용할 수 있게 감싸는 루트 위젯.
  runApp(const ProviderScope(child: LidarMapperApp()));
}

class LidarMapperApp extends StatelessWidget {
  const LidarMapperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LiDAR Mapper',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange)),
      home: const ConnectionScreen(),
    );
  }
}
