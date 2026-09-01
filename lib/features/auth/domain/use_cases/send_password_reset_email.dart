import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class SendPasswordResetEmail {
  const SendPasswordResetEmail(this._repository);

  final AuthRepository _repository;

  Future<void> call(String email) {
    AuthValidators.validateEmail(email);
    return _repository.sendPasswordResetEmail(
      AuthValidators.normalizeEmail(email),
    );
  }
}
