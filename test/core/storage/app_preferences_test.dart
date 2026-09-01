import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppPreferences', () {
    test('missing onboarding key returns false', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();

      final isCompleted = await preferences.isOnboardingCompleted();

      expect(isCompleted, isFalse);
    });

    test('saving completion causes the next read to return true', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();

      await preferences.setOnboardingCompleted();
      final isCompleted = await preferences.isOnboardingCompleted();

      expect(isCompleted, isTrue);
    });
  });
}
