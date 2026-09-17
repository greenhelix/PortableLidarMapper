// 기본 스모크 테스트: 앱이 크래시 없이 뜨고, 연결 화면이 보이는지만 확인.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lidar_mapper_app/main.dart';

void main() {
  testWidgets('App boots and shows the connection screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LidarMapperApp()));

    expect(find.text('연결 설정'), findsOneWidget);
    expect(find.text('연결하기'), findsOneWidget);
  });
}
