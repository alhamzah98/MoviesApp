import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remoteDataSource);

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Stream<AppUser?> authStateChanges() => _remoteDataSource.authStateChanges();

  @override
  Future<AppUser?> getCurrentUser() {
    return _guard(() => _remoteDataSource.getCurrentUser());
  }

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) {
    return _guard(
      () => _remoteDataSource.signInWithEmail(
        email: email,
        password: password,
      ),
    );
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) {
    return _guard(
      () => _remoteDataSource.registerWithEmail(
        name: name,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
      ),
    );
  }

  @override
  Future<AppUser?> signInWithGoogle() {
    return _guard(() => _remoteDataSource.signInWithGoogle());
  }

  @override
  Future<void> sendPasswordResetEmail(String email) {
    return _guard(() => _remoteDataSource.sendPasswordResetEmail(email));
  }

  @override
  Future<void> signOut() {
    return _guard(() => _remoteDataSource.signOut());
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) {
    return _guard(
      () => _remoteDataSource.updateProfile(
        name: name,
        phoneNumber: phoneNumber,
        avatarId: avatarId,
      ),
    );
  }

  @override
  Future<void> deleteAccount() {
    return _guard(() => _remoteDataSource.deleteAccount());
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
        'Authentication failed. Please try again.',
        originalError: error,
      );
    }
  }
}
