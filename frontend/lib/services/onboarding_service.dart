import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingKey = 'onboarding_completed';
  static const String _onboardingVersionKey = 'onboarding_version';
  static const int currentVersion = 1;

  /// Check if onboarding has been completed
  static Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingKey) ?? false;
    } catch (e) {
      print('Error checking onboarding status: $e');
      return false;
    }
  }

  /// Mark onboarding as completed
  static Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, true);
      await prefs.setInt(_onboardingVersionKey, currentVersion);
    } catch (e) {
      print('Error completing onboarding: $e');
    }
  }

  /// Reset onboarding (for testing or showing tutorial again)
  static Future<void> resetOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingKey, false);
      await prefs.remove(_onboardingVersionKey);
    } catch (e) {
      print('Error resetting onboarding: $e');
    }
  }

  /// Check if onboarding needs to be shown again (version changed)
  static Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload(); // Ensure fresh data
      final completed = prefs.getBool(_onboardingKey) ?? false;
      final version = prefs.getInt(_onboardingVersionKey) ?? 0;

      // Show onboarding if not completed
      // Removed version check to prevent showing again on updates unless forced
      return !completed;
    } catch (e) {
      print('Error checking onboarding version: $e');
      return true; // Show onboarding on error to be safe
    }
  }
}
