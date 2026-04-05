import 'package:flutter_test/flutter_test.dart';

import 'package:luxary_flash_drop/app.dart';

void main() {
  testWidgets('Flash Drop app shows product list', (WidgetTester tester) async {
    await tester.pumpWidget(const LuxFlashDropApp());
    await tester.pump();
    expect(find.textContaining('Luxuary Flash Drop'), findsOneWidget);
    expect(find.textContaining('Rolex Submariner'), findsOneWidget);
  });
}
