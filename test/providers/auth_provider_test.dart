import 'package:flutter_test/flutter_test.dart';
import 'package:nyay_setu_flutter/providers/auth_provider.dart';

void main() {
  group('AuthProvider Tests', () {
    test('AuthProvider initializes correctly', () {
      final authProvider = AuthProvider();
      expect(authProvider.isLoading, isTrue);
      expect(authProvider.user, isNull);
      expect(authProvider.userProfile, isNull);
    });

    test('AuthProvider isAuthenticated returns false when user is null', () {
      final authProvider = AuthProvider();
      expect(authProvider.isAuthenticated, isFalse);
    });
  });
}
