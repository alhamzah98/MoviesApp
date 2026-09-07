import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/localization/locale_cubit.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleCubit State & Preservation', () {
    test('defaults to English locale when no preference exists', () {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      expect(cubit.state, equals(const Locale('en')));
      expect(cubit.state.languageCode, equals('en'));

      cubit.close();
    });

    test('loads saved Arabic locale on startup asynchronously', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'ar'});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      await cubit.loadSavedLocale();

      expect(cubit.state, equals(const Locale('ar')));
      expect(cubit.state.languageCode, equals('ar'));

      cubit.close();
    });

    test('ignores unsupported language in storage and remains English', () async {
      SharedPreferences.setMockInitialValues({'app_language': 'es'});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      await cubit.loadSavedLocale();

      expect(cubit.state, equals(const Locale('en')));

      cubit.close();
    });

    test('setLocale switches locale and persists to storage', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      final success = await cubit.setLocale('ar');

      expect(success, isTrue);
      expect(cubit.state, equals(const Locale('ar')));
      expect(await preferences.getAppLanguage(), equals('ar'));

      cubit.close();
    });

    test('toggleLocale alternates between English and Arabic', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      await cubit.toggleLocale();
      expect(cubit.state.languageCode, equals('ar'));

      await cubit.toggleLocale();
      expect(cubit.state.languageCode, equals('en'));

      cubit.close();
    });

    test('re-selecting current locale returns true without re-emitting duplicate state', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = AppPreferences();
      final cubit = LocaleCubit(preferences: preferences);

      final states = <Locale>[];
      final sub = cubit.stream.listen(states.add);

      final success = await cubit.setLocale('en');

      expect(success, isTrue);
      expect(states, isEmpty);

      await sub.cancel();
      cubit.close();
    });
  });
}
