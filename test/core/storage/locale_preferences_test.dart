import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Locale AppPreferences', () {
    test('missing app_language returns null without crashing', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();

      final language = await preferences.getAppLanguage();

      expect(language, isNull);
    });

    test('persisting valid language code returns that code', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();

      await preferences.setAppLanguage('ar');
      final language = await preferences.getAppLanguage();

      expect(language, equals('ar'));
    });

    test('persisting language code does not modify onboarding_completed', () async {
      SharedPreferences.setMockInitialValues({'onboarding_completed': true});
      final preferences = AppPreferences();

      await preferences.setAppLanguage('ar');

      expect(await preferences.getAppLanguage(), equals('ar'));
      expect(await preferences.isOnboardingCompleted(), isTrue);
    });

    test('unsupported or invalid language codes are rejected or ignored gracefully', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'fr_FR'});
      final preferences = AppPreferences();

      // Read returns raw value from storage, which caller/LocaleCubit maps to supported fallback
      final language = await preferences.getAppLanguage();
      expect(language, equals('fr_FR'));

      // Attempting to set an empty or invalid code should return false
      final success = await preferences.setAppLanguage('   ');
      expect(success, isFalse);
    });

    test('concurrent saves do not corrupt storage and complete successfully', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();

      final results = await Future.wait([
        preferences.setAppLanguage('en'),
        preferences.setAppLanguage('ar'),
      ]);

      expect(results, hasLength(2));
      final finalLanguage = await preferences.getAppLanguage();
      expect(finalLanguage, anyOf(equals('en'), equals('ar')));
    });
  });
}
