import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class ObserveAuthState {
  const ObserveAuthState(this._repository);

  final AuthRepository _repository;

  Stream<AppUser?> call() => _repository.authStateChanges();
}
