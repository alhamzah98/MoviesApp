import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/localization/app_localizations.dart';

void main() {
  group('AppLocalizations Translation Completeness', () {
    const enLocale = Locale('en');
    const arLocale = Locale('ar');
    final en = AppLocalizations(enLocale);
    final ar = AppLocalizations(arLocale);

    test('isSupported correctly reports supported locales', () {
      expect(AppLocalizations.isSupported('en'), isTrue);
      expect(AppLocalizations.isSupported('ar'), isTrue);
      expect(AppLocalizations.isSupported('fr'), isFalse);
      expect(AppLocalizations.isSupported('de'), isFalse);
      expect(AppLocalizations.supportedLocales, containsAll([enLocale, arLocale]));
    });

    test('isArabic flag reflects current locale', () {
      expect(en.isArabic, isFalse);
      expect(ar.isArabic, isTrue);
    });

    test('navigation and tabs have non-empty translations in both locales', () {
      expect(en.homeTab.trim(), isNotEmpty);
      expect(ar.homeTab.trim(), isNotEmpty);
      expect(en.searchTab.trim(), isNotEmpty);
      expect(ar.searchTab.trim(), isNotEmpty);
      expect(en.browseTab.trim(), isNotEmpty);
      expect(ar.browseTab.trim(), isNotEmpty);
      expect(en.profileTab.trim(), isNotEmpty);
      expect(ar.profileTab.trim(), isNotEmpty);
      expect(en.homeTab, isNot(equals(ar.homeTab)));
    });

    test('auth copy has complete, distinct English and Arabic strings', () {
      final getters = <String, String Function(AppLocalizations)>{
        'login': (l) => l.login,
        'register': (l) => l.register,
        'createAccount': (l) => l.createAccount,
        'email': (l) => l.email,
        'password': (l) => l.password,
        'confirmPassword': (l) => l.confirmPassword,
        'name': (l) => l.name,
        'phoneNumber': (l) => l.phoneNumber,
        'forgotPasswordPrompt': (l) => l.forgotPasswordPrompt,
        'forgotPasswordTitle': (l) => l.forgotPasswordTitle,
        'forgotPasswordInstruction': (l) => l.forgotPasswordInstruction,
        'sendCode': (l) => l.sendCode,
        'verifyEmail': (l) => l.verifyEmail,
        'dontHaveAccount': (l) => l.dontHaveAccount,
        'createOne': (l) => l.createOne,
        'alreadyHaveAccount': (l) => l.alreadyHaveAccount,
        'orDivider': (l) => l.orDivider,
        'loginWithGoogle': (l) => l.loginWithGoogle,
        'resetPasswordSuccess': (l) => l.resetPasswordSuccess,
        'resetPasswordFailure': (l) => l.resetPasswordFailure,
        'authServiceUnavailable': (l) => l.authServiceUnavailable,
        'authFailed': (l) => l.authFailed,
        'registrationFailed': (l) => l.registrationFailed,
        'firebaseConfigMissing': (l) => l.firebaseConfigMissing,
      };

      for (final entry in getters.entries) {
        final enVal = entry.value(en).trim();
        final arVal = entry.value(ar).trim();
        expect(enVal, isNotEmpty, reason: '${entry.key} in EN should not be empty');
        expect(arVal, isNotEmpty, reason: '${entry.key} in AR should not be empty');
        expect(enVal, isNot(equals(arVal)), reason: '${entry.key} should differ in AR');
      }
    });

    test('movie details and trailer copy are complete in both locales', () {
      expect(en.watchTrailer, equals('Watch Trailer'));
      expect(ar.watchTrailer, equals('مشاهدة الإعلان'));
      expect(en.trailerUnavailable.trim(), isNotEmpty);
      expect(ar.trailerUnavailable.trim(), isNotEmpty);
      expect(en.trailerLaunchFailed.trim(), isNotEmpty);
      expect(ar.trailerLaunchFailed.trim(), isNotEmpty);
      expect(en.invalidTrailerId.trim(), isNotEmpty);
      expect(ar.invalidTrailerId.trim(), isNotEmpty);
      expect(en.summary, equals('Summary'));
      expect(ar.summary, equals('القصة'));
      expect(en.cast, equals('Cast'));
      expect(ar.cast, equals('طاقم العمل'));
      expect(en.genres, equals('Genres'));
      expect(ar.genres, equals('التصنيفات'));
    });

    test('profile, dialogs, and language selectors are complete in both locales', () {
      expect(en.language, equals('Language'));
      expect(ar.language, equals('اللغة'));
      expect(en.english, equals('English'));
      expect(ar.english, equals('الإنجليزية'));
      expect(en.arabic, equals('Arabic'));
      expect(ar.arabic, equals('العربية'));
      expect(en.logout, equals('Logout'));
      expect(ar.logout, equals('تسجيل الخروج'));
      expect(en.deleteAccount, equals('Delete Account'));
      expect(ar.deleteAccount, equals('حذف الحساب'));
    });

    test('translateGenre returns Arabic for known genres and English as fallback', () {
      expect(en.translateGenre('Action'), equals('Action'));
      expect(ar.translateGenre('Action'), equals('حركة'));
      expect(ar.translateGenre('Comedy'), equals('كوميديا'));
      expect(ar.translateGenre('Drama'), equals('دراما'));
      expect(ar.translateGenre('Sci-Fi'), equals('خيال علمي'));
      expect(ar.translateGenre('UnknownGenreXYZ'), equals('UnknownGenreXYZ'));
    });

    test('translateError maps stable error codes correctly in both locales', () {
      final codes = [
        'user-not-found',
        'email-already-in-use',
        'network-request-failed',
        'too-many-requests',
        'invalid-email',
        'weak-password',
        'password-mismatch',
        'invalid-name',
        'invalid-phone',
        'invalid-avatar',
      ];

      for (final code in codes) {
        final enMsg = en.translateError(errorCode: code);
        final arMsg = ar.translateError(errorCode: code);
        expect(enMsg.trim(), isNotEmpty);
        expect(arMsg.trim(), isNotEmpty);
        expect(enMsg, isNot(equals(arMsg)));
      }

      // Fallback behavior
      expect(en.translateError(fallback: 'Custom fallback'), equals('Custom fallback'));
      expect(ar.translateError(fallback: 'Custom fallback'), equals('Custom fallback'));
      expect(en.translateError(), contains('unexpected error'));
      expect(ar.translateError(), contains('حدث خطأ غير متوقع'));
    });
  });
}
