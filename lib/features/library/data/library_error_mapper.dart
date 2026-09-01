import 'package:movies_app/core/errors/app_exception.dart';

class LibraryErrorMapper {
  LibraryErrorMapper._();

  static AppException fromCode(
    String? code, {
    Object? originalError,
    String? fallbackMessage,
  }) {
    final normalized = code?.trim().toLowerCase();
    final message = switch (normalized) {
      'permission-denied' =>
        'You do not have permission to update your library.',
      'unavailable' =>
        'The library service is temporarily unavailable. Please try again.',
      'unauthenticated' => 'Please sign in to use your watchlist and history.',
      'not-found' => 'This library item could not be found.',
      'deadline-exceeded' => 'The request timed out. Please try again.',
      'resource-exhausted' => 'Too many library requests. Please try again later.',
      'cancelled' => 'The library request was cancelled.',
      'unknown' =>
        fallbackMessage ?? 'Unable to update your library. Please try again.',
      _ => fallbackMessage ?? 'Unable to update your library. Please try again.',
    };

    return AppException(
      message,
      code: normalized,
      originalError: originalError,
    );
  }

  static AppException fromError(
    Object error, {
    String? fallbackMessage,
  }) {
    if (error is AppException) {
      return error;
    }

    final code = _codeFrom(error);
    return fromCode(
      code,
      originalError: error,
      fallbackMessage: fallbackMessage,
    );
  }

  static String? _codeFrom(Object error) {
    try {
      final dynamic dynamicError = error;
      final code = dynamicError.code;
      if (code is String && code.trim().isNotEmpty) {
        return code;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}
