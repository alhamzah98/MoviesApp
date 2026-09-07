import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class AppPreferences {
  AppPreferences({SharedPreferencesLoader? loader})
    : _loader = loader ?? SharedPreferences.getInstance;

  static const String _onboardingCompletedKey = 'onboarding_completed';
  static const String _appLanguageKey = 'app_language';

  final SharedPreferencesLoader _loader;
  bool _isSavingLanguage = false;

  Future<bool> isOnboardingCompleted() async {
    final preferences = await _loader();
    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final preferences = await _loader();
    await preferences.setBool(_onboardingCompletedKey, true);
  }

  Future<String?> getAppLanguage() async {
    try {
      final preferences = await _loader();
      return preferences.getString(_appLanguageKey);
    } catch (_) {
      return null;
    }
  }

  Future<bool> setAppLanguage(String languageCode) async {
    if (_isSavingLanguage) {
      return false;
    }
    _isSavingLanguage = true;
    try {
      final preferences = await _loader();
      return await preferences.setString(_appLanguageKey, languageCode);
    } catch (_) {
      return false;
    } finally {
      _isSavingLanguage = false;
    }
  }
}
