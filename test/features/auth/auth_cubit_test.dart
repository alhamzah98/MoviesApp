import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/auth/domain/use_cases/observe_auth_state.dart';
import 'package:movies_app/features/auth/domain/use_cases/register_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_google.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> authStreamController =
      StreamController<AppUser?>.broadcast();
  AppUser? currentUser;
  bool shouldFail = false;
  String failureMessage = 'Simulated failure';

  @override
  Stream<AppUser?> authStateChanges() => authStreamController.stream;

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
    final user = AppUser(
      uid: 'uid_1',
      email: email,
      name: 'Test User',
      avatarId: 'avatar_01',
    );
    currentUser = user;
    authStreamController.add(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
    final user = AppUser(
      uid: 'uid_registered',
      email: email,
      name: name,
      phoneNumber: phoneNumber,
      avatarId: avatarId,
    );
    currentUser = user;
    authStreamController.add(user);
    return user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
    final user = const AppUser(
      uid: 'google_uid',
      email: 'google@test.com',
      name: 'Google User',
    );
    currentUser = user;
    authStreamController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
    currentUser = null;
    authStreamController.add(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    if (shouldFail) {
      throw AppException(failureMessage);
    }
    final updated = AppUser(
      uid: currentUser?.uid ?? 'uid_1',
      email: currentUser?.email ?? 'test@test.com',
      name: name,
      phoneNumber: phoneNumber,
      avatarId: avatarId,
    );
    currentUser = updated;
    return updated;
  }

  @override
  Future<DeleteAccountResult> deleteAccount({
    String? password,
    bool useGoogle = false,
  }) async {
    if (shouldFail) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: failureMessage,
      );
    }
    currentUser = null;
    authStreamController.add(null);
    return DeleteAccountResult.success;
  }
}

void main() {
  late FakeAuthRepository fakeRepository;
  late AuthCubit authCubit;

  setUp(() {
    fakeRepository = FakeAuthRepository();
    authCubit = AuthCubit(
      observeAuthState: ObserveAuthState(fakeRepository),
      signInWithEmail: SignInWithEmail(fakeRepository),
      registerWithEmail: RegisterWithEmail(fakeRepository),
      signInWithGoogle: SignInWithGoogle(fakeRepository),
      signOut: SignOut(fakeRepository),
    );
  });

  tearDown(() async {
    await authCubit.close();
    await fakeRepository.authStreamController.close();
  });

  group('AuthCubit', () {
    test('initial state has unauthenticated or initial status', () {
      expect(authCubit.state.status, AuthStatus.initial);
      expect(authCubit.state.user, isNull);
    });

    test('signInWithEmail successfully emits submitting then authenticated', () async {
      final states = <AuthState>[];
      final sub = authCubit.stream.listen(states.add);

      await authCubit.signInWithEmail(
        email: 'user@example.com',
        password: 'Password123',
      );

      await sub.cancel();

      expect(states.length, 2);
      expect(states[0].status, AuthStatus.submitting);
      expect(states[1].status, AuthStatus.authenticated);
      expect(states[1].user?.email, 'user@example.com');
    });

    test('signInWithEmail failure emits submitting then failure', () async {
      fakeRepository.shouldFail = true;
      fakeRepository.failureMessage = 'Invalid credentials';

      final states = <AuthState>[];
      final sub = authCubit.stream.listen(states.add);

      await authCubit.signInWithEmail(
        email: 'user@example.com',
        password: 'wrong_password',
      );

      await sub.cancel();

      expect(states.length, 2);
      expect(states[0].status, AuthStatus.submitting);
      expect(states[1].status, AuthStatus.failure);
      expect(states[1].errorMessage, 'Invalid credentials');
    });

    test('updateUser updates the in-memory user without restarting session', () {
      const user = AppUser(
        uid: 'uid_1',
        email: 'user@example.com',
        name: 'Updated Name',
        avatarId: 'avatar_02',
      );

      authCubit.updateUser(user);

      expect(authCubit.state.status, AuthStatus.authenticated);
      expect(authCubit.state.user?.name, 'Updated Name');
      expect(authCubit.state.user?.avatarId, 'avatar_02');
    });

    test('signOut clears user and sets unauthenticated status', () async {
      authCubit.updateUser(const AppUser(uid: 'uid_1', email: 'u@test.com'));

      await authCubit.signOut();

      expect(authCubit.state.status, AuthStatus.unauthenticated);
      expect(authCubit.state.user, isNull);
    });
  });
}
