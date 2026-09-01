import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String email,
    required String password,
  }) {
    AuthValidators.validateEmail(email);
    AuthValidators.validatePassword(password);

    return _repository.signInWithEmail(
      email: AuthValidators.normalizeEmail(email),
      password: password,
    );
  }
}
