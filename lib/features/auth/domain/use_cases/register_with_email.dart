import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class RegisterWithEmail {
  const RegisterWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
    required String phoneNumber,
    required String avatarId,
  }) {
    AuthValidators.validateName(name);
    AuthValidators.validateEmail(email);
    AuthValidators.validateRegistrationPassword(password);
    AuthValidators.validatePasswordConfirmation(
      password: password,
      confirmPassword: confirmPassword,
    );
    AuthValidators.validatePhoneNumber(phoneNumber);
    AuthValidators.validateAvatarId(avatarId);

    return _repository.registerWithEmail(
      name: AuthValidators.normalizeName(name),
      email: AuthValidators.normalizeEmail(email),
      password: password,
      phoneNumber: AuthValidators.normalizePhone(phoneNumber),
      avatarId: avatarId.trim(),
    );
  }
}
