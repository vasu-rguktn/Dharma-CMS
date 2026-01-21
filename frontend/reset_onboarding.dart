import 'package:shared_preferences/shared_preferences.dart';

/// Quick script to reset onboarding for testing
/// 
/// Run this in Dart DevTools console or create a temporary button in the app:
/// 
/// ```dart
/// await resetOnboardingForTesting();
/// ```

Future<void> resetOnboardingForTesting() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('onboarding_completed', false);
  await prefs.remove('onboarding_version');
  print('✅ Onboarding reset! Restart the app to see onboarding again.');
}

void main() async {
  await resetOnboardingForTesting();
}
