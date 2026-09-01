import 'package:movies_app/core/errors/app_exception.dart';

class AuthErrorMapper {
  AuthErrorMapper._();

  static AppException fromCode(
    String? code, {
    Object? originalError,
    String? fallbackMessage,
  }) {
    final normalized = code?.trim().toLowerCase();
    final message = switch (normalized) {
      'invalid-email' => 'Please enter a valid email address.',
      'invalid-credential' => 'Invalid email or password.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'user-not-found' => 'No account was found for this email.',
      'user-disabled' => 'This account has been disabled.',
      'email-already-in-use' => 'An account already exists for this email.',
      'weak-password' => 'Password must be at least 6 characters long.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled. Please contact support.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' =>
        'Network error. Check your internet connection and try again.',
      'requires-recent-login' =>
        'Please sign in again before continuing this action.',
      'permission-denied' =>
        'You do not have permission to complete this action.',
      'unavailable' => 'The service is temporarily unavailable. Please try again.',
      'google-canceled' => 'Google sign-in was cancelled.',
      'google-config' =>
        'Google Sign-In is not configured correctly on this device.',
      'password-mismatch' => 'Passwords do not match.',
      _ => fallbackMessage ?? 'Authentication failed. Please try again.',
    };

    return AppException(
      message,
      code: normalized,
      originalError: originalError,
    );
  }
}
