import 'package:movies_app/core/errors/app_exception.dart';

class AuthValidators {
  AuthValidators._();

  static final RegExp _emailPattern = RegExp(
    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
  );

  static String normalizeEmail(String email) {
    return email.trim().toLowerCase();
  }

  static String normalizeName(String name) {
    return name.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String normalizePhone(String phoneNumber) {
    return phoneNumber.trim();
  }

  static void validateEmail(String email) {
    final normalized = normalizeEmail(email);
    if (normalized.isEmpty) {
      throw const AppException(
        'Please enter your email address.',
        code: 'invalid-email',
      );
    }
    if (!_emailPattern.hasMatch(normalized)) {
      throw const AppException(
        'Please enter a valid email address.',
        code: 'invalid-email',
      );
    }
  }

  static void validatePassword(String password) {
    if (password.isEmpty) {
      throw const AppException(
        'Please enter your password.',
        code: 'weak-password',
      );
    }
  }

  static void validateRegistrationPassword(String password) {
    validatePassword(password);
    if (password.length < 6) {
      throw const AppException(
        'Password must be at least 6 characters long.',
        code: 'weak-password',
      );
    }
  }

  static void validatePasswordConfirmation({
    required String password,
    required String confirmPassword,
  }) {
    if (confirmPassword.isEmpty) {
      throw const AppException(
        'Please confirm your password.',
        code: 'password-mismatch',
      );
    }
    if (password != confirmPassword) {
      throw const AppException(
        'Passwords do not match.',
        code: 'password-mismatch',
      );
    }
  }

  static void validateName(String name) {
    if (normalizeName(name).isEmpty) {
      throw const AppException(
        'Please enter your name.',
        code: 'invalid-name',
      );
    }
  }

  static void validatePhoneNumber(String phoneNumber) {
    if (normalizePhone(phoneNumber).isEmpty) {
      throw const AppException(
        'Please enter your phone number.',
        code: 'invalid-phone',
      );
    }
  }

  static void validateAvatarId(String avatarId) {
    if (avatarId.trim().isEmpty) {
      throw const AppException(
        'Please select an avatar.',
        code: 'invalid-avatar',
      );
    }
  }
}
