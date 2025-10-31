import 'package:flutter_test/flutter_test.dart';
import 'package:Dharma/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify the app builds without errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
