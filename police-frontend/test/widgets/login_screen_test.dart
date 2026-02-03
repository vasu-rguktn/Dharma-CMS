import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:Dharma/screens/CitizenAuth/citizen_login_screen.dart';

void main() {
  testWidgets('LoginScreen has email and password fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CitizenLoginScreen(),
      ),
    );

    // Verify email and password fields exist
    expect(find.byType(TextFormField), findsNWidgets(2));
    
    // Verify login button exists
    expect(find.text('Log In'), findsOneWidget);
    
    // Verify Google sign-in button exists
    expect(find.text('Google'), findsOneWidget);
  });
}
