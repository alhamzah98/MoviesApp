import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.deleteAccount();
}
