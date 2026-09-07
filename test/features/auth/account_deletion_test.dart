import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:movies_app/features/auth/data/data_sources/account_deletion_orchestrator.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/auth/domain/use_cases/delete_account.dart';
import 'package:movies_app/features/auth/domain/use_cases/get_current_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/update_profile.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeOrchestratingAuthRepository implements AuthRepository {
  _FakeOrchestratingAuthRepository({
    this.currentUser,
    this.onDeleteAccount,
  });

  AppUser? currentUser;
  final Future<DeleteAccountResult> Function()? onDeleteAccount;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      currentUser!;

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async =>
      currentUser!;

  @override
  Future<AppUser?> signInWithGoogle() async => currentUser;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async =>
      currentUser!;

  @override
  Future<DeleteAccountResult> deleteAccount({
    String? password,
    bool useGoogle = false,
  }) async {
    if (onDeleteAccount != null) {
      return onDeleteAccount!();
    }
    return DeleteAccountResult.success;
  }
}

/// Test double for AuthRepository tracking all deletion calls.
class DeletionTrackingAuthRepository implements AuthRepository {
  DeletionTrackingAuthRepository({this.currentUser});

  AppUser? currentUser;
  int reauthCalls = 0;
  int watchlistDeleteCalls = 0;
  int historyDeleteCalls = 0;
  int userDocDeleteCalls = 0;
  int authUserDeleteCalls = 0;

  bool shouldCancelReauth = false;
  bool shouldFailReauth = false;
  bool shouldFailWatchlistCleanup = false;
  bool shouldFailAuthUserDelete = false;
  String? expectedSessionUid;

  @override
  Stream<AppUser?> authStateChanges() => Stream.value(currentUser);

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      currentUser!;

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async =>
      currentUser!;

  @override
  Future<AppUser?> signInWithGoogle() async => currentUser;

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> signOut() async {
    currentUser = null;
  }

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async =>
      currentUser!;

  @override
  Future<DeleteAccountResult> deleteAccount({
    String? password,
    bool useGoogle = false,
  }) async {
    final activeUser = currentUser;
    if (activeUser == null) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Unauthenticated',
      );
    }

    if (expectedSessionUid != null && activeUser.uid != expectedSessionUid) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Session UID mismatch',
      );
    }

    reauthCalls++;

    // 1. Reauthentication phase
    if (shouldCancelReauth) {
      return DeleteAccountResult.cancelled;
    }

    if (shouldFailReauth) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Invalid credentials',
      );
    }

    // 2. Data cleanup phase
    if (shouldFailWatchlistCleanup) {
      watchlistDeleteCalls++;
      return DeleteAccountResult.partialFailure(
        errorMessage: 'Watchlist cleanup failed',
      );
    }

    watchlistDeleteCalls++;
    historyDeleteCalls++;
    userDocDeleteCalls++;

    // 3. Auth user deletion phase
    if (shouldFailAuthUserDelete) {
      return DeleteAccountResult.partialFailure(
        errorMessage: 'Recent login required to delete authentication user',
      );
    }

    authUserDeleteCalls++;
    currentUser = null;
    return DeleteAccountResult.success;
  }
}

void main() {
  group('Production AccountDeletionOrchestrator Operation & Classification', () {
    test(
      '1. Exact password preservation passes untrimmed password to reauth boundary',
      () async {
        String? capturedPassword;
        final orchestrator = AccountDeletionOrchestrator(
          getCurrentUid: () => 'target_uid_123',
          reauthenticate: ({String? password, bool useGoogle = false}) async {
            capturedPassword = password;
          },
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteUserProfile: () async {},
          deleteAuthUser: () async {},
        );

        const untrimmedPassword = '  Pass Word 123! \t ';
        final result = await orchestrator.execute(password: untrimmedPassword);

        expect(result.isSuccess, isTrue);
        expect(capturedPassword, equals(untrimmedPassword));
        expect(capturedPassword, '  Pass Word 123! \t ');
      },
    );

    test(
      '2. A later Watch List batch failing after earlier batches succeeded classifies as partialFailure',
      () async {
        int batchCalls = 0;
        final orchestrator = AccountDeletionOrchestrator(
          getCurrentUid: () => 'target_uid_123',
          reauthenticate: ({String? password, bool useGoogle = false}) async {},
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async {
            batchCalls++;
            if (batchCalls == 1) {
              onDestructiveSubmitting?.call();
              return 100; // Batch 1 successfully deletes 100 items
            }
            onDestructiveSubmitting?.call();
            throw const AppException(
              'Firestore connection interrupted during batch 2 commit',
              code: 'unavailable',
            );
          },
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteUserProfile: () async {},
          deleteAuthUser: () async {},
        );

        final result = await orchestrator.execute(password: 'correct_pw');

        expect(result.isPartialFailure, isTrue);
        expect(result.isFailedPreCleanup, isFalse);
        expect(result.isSuccess, isFalse);
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isTrue);
        expect(orchestrator.isUidSuspended('target_uid_123'), isTrue);
      },
    );

    test(
      '3. Failure before cleanup releases write suspension safely',
      () async {
        bool resumeCalled = false;
        String? resumedUid;

        final orchestrator = AccountDeletionOrchestrator(
          getCurrentUid: () => 'target_uid_123',
          reauthenticate: ({String? password, bool useGoogle = false}) async {
            throw const AppException(
              'Incorrect password',
              code: 'wrong-password',
            );
          },
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteUserProfile: () async {},
          deleteAuthUser: () async {},
          onPauseCompetingWrites: (uid) async {},
          onResumeCompetingWrites: (uid) {
            resumeCalled = true;
            resumedUid = uid;
          },
        );

        final result = await orchestrator.execute(password: 'bad_pw');

        expect(result.isFailedPreCleanup, isTrue);
        expect(result.isPartialFailure, isFalse);
        expect(resumeCalled, isTrue);
        expect(resumedUid, 'target_uid_123');
        expect(orchestrator.isUidSuspended('target_uid_123'), isFalse);
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isFalse);
      },
    );

    test(
      '4. Partial failure permits an explicit same-user retry through the orchestrator',
      () async {
        bool failBatch = true;
        int authUserDeleteCalls = 0;

        final orchestrator = AccountDeletionOrchestrator(
          getCurrentUid: () => 'target_uid_123',
          reauthenticate: ({String? password, bool useGoogle = false}) async {},
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async {
            if (failBatch) {
              onDestructiveSubmitting?.call();
              throw const AppException(
                'Simulated transient timeout',
                code: 'deadline-exceeded',
              );
            }
            return 0; // On retry, nothing left or succeeds cleanly
          },
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteUserProfile: () async {},
          deleteAuthUser: () async {
            authUserDeleteCalls++;
          },
        );

        // First attempt: partial failure
        final firstResult = await orchestrator.execute(password: 'valid_pw');
        expect(firstResult.isPartialFailure, isTrue);
        expect(orchestrator.isDeletionActive('target_uid_123'), isFalse);
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isTrue);
        expect(authUserDeleteCalls, 0);

        // Second attempt (explicit retry for same UID): must NOT be blocked
        failBatch = false;
        final retryResult = await orchestrator.execute(password: 'valid_pw');
        expect(retryResult.isSuccess, isTrue);
        expect(authUserDeleteCalls, 1);
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isFalse);
        expect(orchestrator.isUidSuspended('target_uid_123'), isFalse);
      },
    );

    test(
      '5. Cancelling a retry retains incomplete-deletion status and write suspension',
      () async {
        bool failBatch = true;
        bool cancelReauth = false;
        bool resumeCalled = false;

        final orchestrator = AccountDeletionOrchestrator(
          getCurrentUid: () => 'target_uid_123',
          reauthenticate: ({String? password, bool useGoogle = false}) async {
            if (cancelReauth) {
              throw const AppException(
                'User cancelled reauthentication',
                code: 'cancelled',
              );
            }
          },
          deleteWatchlistBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async {
            if (failBatch) {
              onDestructiveSubmitting?.call();
              throw const AppException('Batch failure', code: 'unavailable');
            }
            return 0;
          },
          deleteHistoryBatch: ({
            required int batchSize,
            void Function()? onDestructiveSubmitting,
          }) async => 0,
          deleteUserProfile: () async {},
          deleteAuthUser: () async {},
          onResumeCompetingWrites: (uid) {
            resumeCalled = true;
          },
        );

        // Attempt 1: partial failure
        final firstResult = await orchestrator.execute(password: 'valid_pw');
        expect(firstResult.isPartialFailure, isTrue);
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isTrue);
        expect(orchestrator.isUidSuspended('target_uid_123'), isTrue);

        // Attempt 2: user cancels the reauth dialog
        cancelReauth = true;
        resumeCalled = false;
        final cancelResult = await orchestrator.execute(password: 'valid_pw');

        expect(cancelResult.isCancelled, isTrue);
        // Crucial: Must NOT erase incomplete deletion status or release write suspension!
        expect(orchestrator.hasIncompleteDeletion('target_uid_123'), isTrue);
        expect(orchestrator.isUidSuspended('target_uid_123'), isTrue);
        expect(resumeCalled, isFalse);
      },
    );
  });

  group('ProfileCubit Account Deletion Lifecycle & State Guarding', () {
    late DeletionTrackingAuthRepository repository;
    late ProfileCubit profileCubit;

    const testUser = AppUser(
      uid: 'target_uid_123',
      email: 'student@moviesapp.test',
      name: 'Test Student',
      providerIds: ['password'],
    );

    setUp(() {
      repository = DeletionTrackingAuthRepository(currentUser: testUser);
      profileCubit = ProfileCubit(
        getCurrentUser: GetCurrentUser(repository),
        updateProfile: UpdateProfile(repository),
        deleteAccount: DeleteAccount(repository),
      );
    });

    tearDown(() async {
      await profileCubit.close();
    });

    test(
      '6. Successful deletion returns success result even if ProfileCubit undergoes intervening reset',
      () async {
        final orchestratingRepo = _FakeOrchestratingAuthRepository(
          currentUser: testUser,
          onDeleteAccount: () async => DeleteAccountResult.success,
        );

        final cubit = ProfileCubit(
          getCurrentUser: GetCurrentUser(orchestratingRepo),
          updateProfile: UpdateProfile(orchestratingRepo),
          deleteAccount: DeleteAccount(orchestratingRepo),
        );

        // Initiate deletion
        final deleteFuture = cubit.deleteAccount(password: 'valid_password');

        // Intervene with cubit reset (simulating authStateChanges null event triggering reset)
        cubit.reset();

        final result = await deleteFuture;

        // Caller must receive the genuine success result despite the intervening session reset
        expect(result.isSuccess, isTrue);
        expect(result.status, DeleteAccountStatus.success);

        await cubit.close();
      },
    );

    test(
      'Cancelled or failed reauthentication causes zero Firestore and Auth deletions',
      () async {
        repository.shouldCancelReauth = true;

        final cancelResult = await profileCubit.deleteAccount(
          password: 'wrong_password',
        );

        expect(cancelResult.isCancelled, isTrue);
        expect(cancelResult.isSuccess, isFalse);
        expect(profileCubit.state.status, ProfileStatus.ready);
        expect(repository.watchlistDeleteCalls, 0);
        expect(repository.historyDeleteCalls, 0);
        expect(repository.userDocDeleteCalls, 0);
        expect(repository.authUserDeleteCalls, 0);
        expect(repository.currentUser, isNotNull);

        repository.shouldCancelReauth = false;
        repository.shouldFailReauth = true;

        final failResult = await profileCubit.deleteAccount(
          password: 'incorrect_password',
        );

        expect(failResult.isFailedPreCleanup, isTrue);
        expect(profileCubit.state.status, ProfileStatus.failure);
        expect(repository.watchlistDeleteCalls, 0);
        expect(repository.historyDeleteCalls, 0);
        expect(repository.userDocDeleteCalls, 0);
        expect(repository.authUserDeleteCalls, 0);
        expect(repository.currentUser, isNotNull);
      },
    );

    test('Cleanup failure prevents Auth deletion', () async {
      repository.shouldFailWatchlistCleanup = true;

      final result = await profileCubit.deleteAccount(
        password: 'valid_password',
      );

      expect(repository.watchlistDeleteCalls, 1);
      expect(repository.authUserDeleteCalls, 0);
      expect(result.isPartialFailure, isTrue);
      expect(result.isSuccess, isFalse);
      expect(profileCubit.state.status, ProfileStatus.partialFailure);
      expect(
        profileCubit.state.errorMessage,
        contains('Watchlist cleanup failed'),
      );
      expect(repository.currentUser, isNotNull);
    });

    test('Session changes prevent destructive writes to another UID', () async {
      repository.expectedSessionUid = 'target_uid_123';

      repository.currentUser = const AppUser(
        uid: 'switched_user_456',
        email: 'other@moviesapp.test',
      );

      final result = await profileCubit.deleteAccount(
        password: 'any_password',
      );

      expect(result.isFailedPreCleanup, isTrue);
      expect(result.isSuccess, isFalse);
      expect(repository.watchlistDeleteCalls, 0);
      expect(repository.historyDeleteCalls, 0);
      expect(repository.userDocDeleteCalls, 0);
      expect(repository.authUserDeleteCalls, 0);
      expect(repository.currentUser?.uid, 'switched_user_456');
    });

    test('Partial failure never reports complete success', () async {
      repository.shouldFailAuthUserDelete = true;

      final result = await profileCubit.deleteAccount(
        password: 'valid_password',
      );

      expect(result.isSuccess, isFalse);
      expect(result.isPartialFailure, isTrue);
      expect(profileCubit.state.status, ProfileStatus.partialFailure);
      expect(profileCubit.state.isDeleted, isFalse);
      expect(
        profileCubit.state.errorMessage,
        contains('Recent login required'),
      );
    });

    test(
      'Successful deletion clears user state while strictly preserving locale and onboarding preferences',
      () async {
        SharedPreferences.setMockInitialValues({
          'app_language': 'ar',
          'onboarding_completed': true,
        });

        final preferences = AppPreferences();
        expect(await preferences.getAppLanguage(), 'ar');
        expect(await preferences.isOnboardingCompleted(), isTrue);

        final result = await profileCubit.deleteAccount(
          password: 'valid_password',
        );

        expect(result.isSuccess, isTrue);
        expect(profileCubit.state.status, ProfileStatus.deleted);
        expect(profileCubit.state.user, isNull);

        // Locale and onboarding preferences must remain completely intact
        expect(await preferences.getAppLanguage(), 'ar');
        expect(await preferences.isOnboardingCompleted(), isTrue);
      },
    );
  });
}
