import 'package:flutter_test/flutter_test.dart';
import 'package:nirmaya_cms/main.dart';

void main() {
  testWidgets('Nirmaya app renders', (tester) async {
    await tester.pumpWidget(const NirmayaApp());
    expect(find.byType(NirmayaApp), findsOneWidget);
  });
}
