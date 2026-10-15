import 'package:flutter_test/flutter_test.dart';
import 'package:front/main.dart';

void main() {
  testWidgets('카메라 홈에 하단 메뉴가 보인다', (WidgetTester tester) async {
    await tester.pumpWidget(const YogiApp(cameras: []));
    await tester.pump(); // 카메라 초기화 Future 한 프레임

    expect(find.text('YOGI'), findsOneWidget);
    expect(find.text('주변'), findsOneWidget);
    expect(find.text('붙이기'), findsOneWidget);
    expect(find.text('내메모'), findsOneWidget);
  });
}
