import 'dart:async';

import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/auth/domain/entities/delete_account_result.dart';

/// Production orchestrator for account deletion.
///
/// Implements the exact 8-step client-side deletion workflow:
/// 1. Verifies caller identity and captures target session UID.
/// 2. Performs reauthentication through injected handler.
/// 3. Coordinates write safety barriers across profile and library data sources.
/// 4. Drains Watch List documents in bounded batches without query filtering.
/// 5. Drains History documents in bounded batches without query filtering.
/// 6. Deletes user profile document.
/// 7. Deletes Firebase Authentication account.
/// 8. Executes best-effort third-party credential cleanup.
class AccountDeletionOrchestrator {
  AccountDeletionOrchestrator({
    required this.getCurrentUid,
    required this.reauthenticate,
    required this.deleteWatchlistBatch,
    required this.deleteHistoryBatch,
    required this.deleteUserProfile,
    required this.deleteAuthUser,
    this.signOutGoogle,
    this.onPauseCompetingWrites,
    this.onResumeCompetingWrites,
    this.batchSize = 100,
    this.maxBatches = 50,
  });

  final String? Function() getCurrentUid;
  final Future<void> Function({String? password, bool useGoogle}) reauthenticate;
  final Future<int> Function({
    required int batchSize,
    void Function()? onDestructiveSubmitting,
  }) deleteWatchlistBatch;
  final Future<int> Function({
    required int batchSize,
    void Function()? onDestructiveSubmitting,
  }) deleteHistoryBatch;
  final Future<void> Function() deleteUserProfile;
  final Future<void> Function() deleteAuthUser;
  final Future<void> Function()? signOutGoogle;
  final Future<void> Function(String uid)? onPauseCompetingWrites;
  final void Function(String uid)? onResumeCompetingWrites;
  final int batchSize;
  final int maxBatches;

  final Set<String> _activeDeletionUids = <String>{};
  final Set<String> _incompleteDeletionUids = <String>{};
  final Set<String> _suspendedUids = <String>{};

  bool isUidSuspended(String uid) => _suspendedUids.contains(uid);
  bool isDeletionActive(String uid) => _activeDeletionUids.contains(uid);
  bool hasIncompleteDeletion(String uid) =>
      _incompleteDeletionUids.contains(uid);

  Future<DeleteAccountResult> execute({
    String? password,
    bool useGoogle = false,
  }) async {
    final targetUid = getCurrentUid();
    if (targetUid == null || targetUid.isEmpty) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Please sign in again before deleting your account.',
      );
    }

    if (_activeDeletionUids.contains(targetUid)) {
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'An account deletion operation is already in progress.',
      );
    }

    _activeDeletionUids.add(targetUid);

    // 1 & 2. Reauthenticate captured current user before any data mutations.
    try {
      await reauthenticate(password: password, useGoogle: useGoogle);
    } catch (error) {
      _activeDeletionUids.remove(targetUid);
      if (!_incompleteDeletionUids.contains(targetUid)) {
        _suspendedUids.remove(targetUid);
        onResumeCompetingWrites?.call(targetUid);
      }
      if (error is AppException && error.code == 'cancelled') {
        return DeleteAccountResult.cancelled;
      }
      final msg = error is AppException
          ? error.message
          : 'Reauthentication failed. Please check your credentials and try again.';
      if (_incompleteDeletionUids.contains(targetUid)) {
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed. Reauthentication failed: $msg',
        );
      }
      return DeleteAccountResult.failedPreCleanup(errorMessage: msg);
    }

    // Verify session remained unchanged after reauthentication
    if (getCurrentUid() != targetUid) {
      _activeDeletionUids.remove(targetUid);
      if (!_incompleteDeletionUids.contains(targetUid)) {
        _suspendedUids.remove(targetUid);
        onResumeCompetingWrites?.call(targetUid);
      }
      if (_incompleteDeletionUids.contains(targetUid)) {
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed, but session changed during reauthentication.',
        );
      }
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'User session changed during reauthentication.',
      );
    }

    // 3. Coordinate write-safety barriers
    try {
      if (onPauseCompetingWrites != null) {
        await onPauseCompetingWrites!(targetUid);
      }
    } catch (_) {
      _activeDeletionUids.remove(targetUid);
      if (!_incompleteDeletionUids.contains(targetUid)) {
        _suspendedUids.remove(targetUid);
        onResumeCompetingWrites?.call(targetUid);
      }
      if (_incompleteDeletionUids.contains(targetUid)) {
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed, but unable to coordinate write safety.',
        );
      }
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'Unable to coordinate write safety. Please try again.',
      );
    }

    _suspendedUids.add(targetUid);

    // Verify session before destructive phase begins
    if (getCurrentUid() != targetUid) {
      _activeDeletionUids.remove(targetUid);
      if (!_incompleteDeletionUids.contains(targetUid)) {
        _suspendedUids.remove(targetUid);
        onResumeCompetingWrites?.call(targetUid);
      }
      if (_incompleteDeletionUids.contains(targetUid)) {
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed, but session changed before data cleanup began.',
        );
      }
      return DeleteAccountResult.failedPreCleanup(
        errorMessage: 'User session changed before data cleanup began.',
      );
    }

    bool hasDestructiveRequestBegun = false;

    try {
      // 4. Delete Watch List subcollection in bounded batches
      await _drainCollectionInBatches(
        drainBatch: deleteWatchlistBatch,
        markDestructiveBegun: () => hasDestructiveRequestBegun = true,
      );

      // Verify session after Watch List
      if (getCurrentUid() != targetUid) {
        _incompleteDeletionUids.add(targetUid);
        _activeDeletionUids.remove(targetUid);
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed, but session changed before history cleanup.',
        );
      }

      // 5. Delete History subcollection in bounded batches
      await _drainCollectionInBatches(
        drainBatch: deleteHistoryBatch,
        markDestructiveBegun: () => hasDestructiveRequestBegun = true,
      );

      // Verify session after History
      if (getCurrentUid() != targetUid) {
        _incompleteDeletionUids.add(targetUid);
        _activeDeletionUids.remove(targetUid);
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Some data may have been removed, but session changed before profile document cleanup.',
        );
      }

      // 6. Delete User Profile document
      hasDestructiveRequestBegun = true;
      await deleteUserProfile();

      // Verify session before Auth account deletion
      if (getCurrentUid() != targetUid) {
        _incompleteDeletionUids.add(targetUid);
        _activeDeletionUids.remove(targetUid);
        return DeleteAccountResult.partialFailure(
          errorMessage:
              'Account data was deleted, but session changed before authentication account removal.',
        );
      }

      // 7. Delete Firebase Authentication user
      await deleteAuthUser();

      // 8. Best-effort Google sign-out
      try {
        if (signOutGoogle != null) {
          await signOutGoogle!();
        }
      } catch (_) {
        // Ignored by design
      }

      // Cleanup completed successfully
      _incompleteDeletionUids.remove(targetUid);
      _activeDeletionUids.remove(targetUid);
      _suspendedUids.remove(targetUid);

      return DeleteAccountResult.success;
    } catch (error) {
      _activeDeletionUids.remove(targetUid);

      if (hasDestructiveRequestBegun ||
          _incompleteDeletionUids.contains(targetUid)) {
        _incompleteDeletionUids.add(targetUid);
        _suspendedUids.add(targetUid);

        String msg =
            'Some account data may have been removed. Account deletion is incomplete. Please retry.';
        if (error is AppException) {
          msg = error.message;
        }
        return DeleteAccountResult.partialFailure(errorMessage: msg);
      } else {
        if (!_incompleteDeletionUids.contains(targetUid)) {
          _suspendedUids.remove(targetUid);
          onResumeCompetingWrites?.call(targetUid);
        }
        String msg = 'Unable to delete your account. Please try again.';
        if (error is AppException) {
          msg = error.message;
        }
        return DeleteAccountResult.failedPreCleanup(errorMessage: msg);
      }
    }
  }

  Future<void> _drainCollectionInBatches({
    required Future<int> Function({
      required int batchSize,
      void Function()? onDestructiveSubmitting,
    }) drainBatch,
    required void Function() markDestructiveBegun,
  }) async {
    int batchesProcessed = 0;
    while (batchesProcessed < maxBatches) {
      final docsDeleted = await drainBatch(
        batchSize: batchSize,
        onDestructiveSubmitting: markDestructiveBegun,
      );
      if (docsDeleted == 0) {
        return;
      }
      markDestructiveBegun();
      batchesProcessed++;
      if (docsDeleted < batchSize) {
        return;
      }
    }
    if (batchesProcessed >= maxBatches) {
      throw const AppException(
        'Account data cleanup exceeded maximum batch budget.',
        code: 'cleanup-budget-exceeded',
      );
    }
  }
}
