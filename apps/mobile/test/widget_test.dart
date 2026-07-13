import 'package:flutter_test/flutter_test.dart';
import 'package:otask_mobile/main.dart';

void main() {
  testWidgets('bootstrap screen renders', (tester) async {
    await tester.pumpWidget(const OTaskApp());
    expect(find.text('OTask mobile bootstrap'), findsOneWidget);
  });
}
