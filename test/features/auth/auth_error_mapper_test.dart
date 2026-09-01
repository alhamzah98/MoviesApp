import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/features/auth/data/auth_error_mapper.dart';

void main() {
  group('AuthErrorMapper', () {
    test('maps known Firebase codes to friendly messages', () {
      final exception = AuthErrorMapper.fromCode('email-already-in-use');

      expect(
        exception.message,
        'An account already exists for this email.',
      );
      expect(exception.code, 'email-already-in-use');
    });

    test('maps network failures to a connection message', () {
      final exception = AuthErrorMapper.fromCode('network-request-failed');

      expect(
        exception.message,
        'Network error. Check your internet connection and try again.',
      );
    });

    test('uses fallback message for unknown codes', () {
      final exception = AuthErrorMapper.fromCode(
        'something-unknown',
        fallbackMessage: 'Custom fallback',
      );

      expect(exception.message, 'Custom fallback');
      expect(exception.code, 'something-unknown');
    });
  });
}
