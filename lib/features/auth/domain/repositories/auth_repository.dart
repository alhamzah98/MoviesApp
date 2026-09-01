import 'package:movies_app/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> authStateChanges();

  Future<AppUser?> getCurrentUser();

  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  });

  Future<AppUser?> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);

  Future<void> signOut();

  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  });

  Future<void> deleteAccount();
}
