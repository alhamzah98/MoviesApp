import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/auth/domain/use_cases/delete_account.dart';
import 'package:movies_app/features/auth/domain/use_cases/get_current_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/update_profile.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_state.dart';

class FakeProfileRepository implements AuthRepository {
  AppUser? user = const AppUser(
    uid: 'uid_1',
    email: 'user@test.com',
    name: 'Original Name',
    phoneNumber: '1234567890',
    avatarId: 'avatar_01',
  );
  bool shouldFail = false;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(user);

  @override
  Future<AppUser?> getCurrentUser() async => user;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async => user!;

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async => user!;

  @override
  Future<AppUser?> signInWithGoogle() async => user;

  @override
  Future<void> signOut() async {
    user = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (shouldFail) {
      throw const AppException('Profile update failed');
    }
    final updated = AppUser(
      uid: user?.uid ?? 'uid_1',
      email: user?.email ?? 'user@test.com',
      name: name,
      phoneNumber: phoneNumber,
      avatarId: avatarId,
    );
    user = updated;
    return updated;
  }

  @override
  Future<DeleteAccountResult> deleteAccount({
    String? password,
    bool useGoogle = false,
  }) async {
    if (shouldFail) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Account deletion failed',
      );
    }
    user = null;
    return DeleteAccountResult.success;
  }
}

void main() {
  late FakeProfileRepository fakeRepository;
  late ProfileCubit profileCubit;

  setUp(() {
    fakeRepository = FakeProfileRepository();
    profileCubit = ProfileCubit(
      getCurrentUser: GetCurrentUser(fakeRepository),
      updateProfile: UpdateProfile(fakeRepository),
      deleteAccount: DeleteAccount(fakeRepository),
    );
  });

  tearDown(() async {
    await profileCubit.close();
  });

  group('ProfileCubit', () {
    test('updateProfile returns AppUser on success and sets ready status', () async {
      final updatedUser = await profileCubit.updateProfile(
        name: 'New Name',
        phoneNumber: '0987654321',
        avatarId: 'avatar_02',
      );

      expect(updatedUser, isNotNull);
      expect(updatedUser?.name, 'New Name');
      expect(updatedUser?.phoneNumber, '0987654321');
      expect(updatedUser?.avatarId, 'avatar_02');
      expect(profileCubit.state.status, ProfileStatus.ready);
      expect(profileCubit.state.user?.name, 'New Name');
    });

    test('updateProfile returns null on failure and sets failure status', () async {
      fakeRepository.shouldFail = true;

      final updatedUser = await profileCubit.updateProfile(
        name: 'New Name',
        phoneNumber: '0987654321',
        avatarId: 'avatar_02',
      );

      expect(updatedUser, isNull);
      expect(profileCubit.state.status, ProfileStatus.failure);
      expect(profileCubit.state.errorMessage, 'Profile update failed');
    });
  });
}
