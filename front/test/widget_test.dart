import 'package:flutter_test/flutter_test.dart';
import 'package:front/main.dart';

void main() {
  testWidgets('카메라 홈에 하단 메뉴가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const YogiApp());
    await tester.pump(); // post-frame 카메라 초기화 시작
    await tester.pump(const Duration(seconds: 4)); // timeout 타이머 소진

    expect(find.text('YOGI'), findsOneWidget);
    expect(find.text('주변'), findsOneWidget);
    expect(find.text('붙이기'), findsOneWidget);
    expect(find.text('내메모'), findsOneWidget);
  });
}
