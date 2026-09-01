import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class UpdateProfile {
  const UpdateProfile(this._repository);

  final AuthRepository _repository;

  Future<AppUser> call({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) {
    AuthValidators.validateName(name);
    AuthValidators.validatePhoneNumber(phoneNumber);
    AuthValidators.validateAvatarId(avatarId);

    return _repository.updateProfile(
      name: AuthValidators.normalizeName(name),
      phoneNumber: AuthValidators.normalizePhone(phoneNumber),
      avatarId: avatarId.trim(),
    );
  }
}
