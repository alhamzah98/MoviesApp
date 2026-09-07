import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class DeleteAccount {
  const DeleteAccount(this._repository);

  final AuthRepository _repository;

  Future<DeleteAccountResult> call({
    String? password,
    bool useGoogle = false,
  }) =>
      _repository.deleteAccount(password: password, useGoogle: useGoogle);
}
