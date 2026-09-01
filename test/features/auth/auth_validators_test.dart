import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';

void main() {
  group('AuthValidators', () {
    test('normalizes email addresses', () {
      expect(
        AuthValidators.normalizeEmail('  John.Doe@Example.COM '),
        'john.doe@example.com',
      );
    });

    test('rejects invalid email formats', () {
      expect(
        () => AuthValidators.validateEmail('not-an-email'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'invalid-email',
          ),
        ),
      );
    });

    test('requires a registration password length of at least 6', () {
      expect(
        () => AuthValidators.validateRegistrationPassword('123'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'weak-password',
          ),
        ),
      );
    });

    test('rejects password confirmation mismatches', () {
      expect(
        () => AuthValidators.validatePasswordConfirmation(
          password: 'secret1',
          confirmPassword: 'secret2',
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'password-mismatch',
          ),
        ),
      );
    });
  });
}
