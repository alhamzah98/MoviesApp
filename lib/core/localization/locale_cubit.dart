import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/storage/app_preferences.dart';

/// Cubit managing the application's active [Locale] and persisting selection.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({
    required AppPreferences preferences,
    String defaultLanguageCode = 'en',
  })  : _preferences = preferences,
        super(Locale(defaultLanguageCode)) {
    loadSavedLocale();
  }

  final AppPreferences _preferences;

  /// Loads the persisted language preference without blocking startup.
  Future<void> loadSavedLocale() async {
    try {
      final savedCode = await _preferences.getAppLanguage();
      if (savedCode != null && AppLocalizations.isSupported(savedCode)) {
        if (!isClosed) {
          emit(Locale(savedCode));
        }
      }
    } catch (_) {
      // Startup must not crash if preference read fails.
    }
  }

  /// Sets the application locale and persists it.
  ///
  /// Returns `true` if the locale is supported and successfully applied/saved.
  /// Returns `false` if saving fails or if another save operation is in flight.
  Future<bool> setLocale(String languageCode) async {
    if (!AppLocalizations.isSupported(languageCode)) {
      return false;
    }

    if (state.languageCode == languageCode) {
      return true;
    }

    final newLocale = Locale(languageCode);
    emit(newLocale);

    try {
      final saved = await _preferences.setAppLanguage(languageCode);
      return saved;
    } catch (_) {
      return false;
    }
  }

  /// Toggles between English ('en') and Arabic ('ar').
  Future<bool> toggleLocale() {
    final nextCode = state.languageCode == 'ar' ? 'en' : 'ar';
    return setLocale(nextCode);
  }
}
