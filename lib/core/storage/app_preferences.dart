import 'package:shared_preferences/shared_preferences.dart';

typedef SharedPreferencesLoader = Future<SharedPreferences> Function();

class AppPreferences {
  AppPreferences({SharedPreferencesLoader? loader})
      : _loader = loader ?? SharedPreferences.getInstance;

  static const String _onboardingCompletedKey = 'onboarding_completed';

  final SharedPreferencesLoader _loader;

  Future<bool> isOnboardingCompleted() async {
    final preferences = await _loader();
    return preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> setOnboardingCompleted() async {
    final preferences = await _loader();
    await preferences.setBool(_onboardingCompletedKey, true);
  }
}
