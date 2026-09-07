# Account Deletion Implementation Corrections and Source Review Report

## 1. Executive Summary & Verification Mode Confirmation

This focused correction and source review resolves credential alteration, cleanup progress tracking, write suspension/resumption lifecycles, authoritative provider tracking, and test fidelity in the MoviesApp account deletion implementation.

**Strict Code-Only Compliance Confirmation:**
No terminal, command, script, Flutter or Dart tool, package resolution, analysis, formatting, automated test execution, build, application launch, emulator, device, browser automation, network request, Firebase console/API operation, installation, deployment, or Git operation occurred during this task. All findings and corrections were identified and implemented strictly via editor and workspace tools.

---

## 2. Confirmed Source Findings vs. Already-Handled Concerns

| Area / Concern | Source Inspection Finding | Action Taken |
|---|---|---|
| **Password Trimming** | Confirmed: `update_profile_screen.dart` was calling `passwordController.text.trim()`, stripping valid leading and trailing spaces. `login_screen.dart` and `register_screen.dart` were inspected and verified to NOT alter or trim passwords (`_passwordController.text` is used directly). | Removed `.trim()` in `update_profile_screen.dart`. Added regression test verifying exact password preservation to the reauth boundary. |
| **Cleanup Progress Tracking** | Confirmed: Incomplete failure classification occurred if Firestore cleanup failed after partial batch commits or user document deletion. | Refined `AccountDeletionOrchestrator` to mark destructive operations prior to awaiting network write commits (`onDestructiveSubmitting`) and track batch progress. Any failure after destructive submission classifies as `partialFailure`. |
| **Write Suspension & Resumption** | Confirmed: Write pause callback (`onPauseCompetingWrites`) existed in `AuthCoordinator`, but `onResumeCompetingWrites` was not wired, meaning an aborted deletion before cleanup would permanently suspend writes. | Added `onResumeCompetingWrites` parameter to `AuthFirebaseDataSource` and `AccountDeletionOrchestrator`. Wired in `AuthCoordinator` to `libraryDataSource.resumeWritesFor(uid)`. |
| **Retry & Incomplete Deletion Ownership** | Confirmed: Single in-progress flags could conflate active deletion calls with incomplete deletion state, blocking retries or prematurely releasing safeguards. | Separated `_activeDeletionUids` (running call) from `_incompleteDeletionUids` (partially deleted account) and `_suspendedUids` (safeguarded writes). Retries for the same UID are allowed, and cancelling a retry retains incomplete status. |
| **Authoritative Provider Identity** | Confirmed: `_readUserProfile` loaded from Firestore, which does not store authoritative `providerData`, causing `AppUser.providerIds` to become empty on profile load or update. | Updated `_readUserProfile` to source `providerIds` directly from `FirebaseAuth.currentUser.providerData` whenever loading or updating a profile. |
| **Result Survival Across Auth Resets** | Confirmed: `ProfileCubit.deleteAccount` suppresses UI state emissions on session generation changes, but must always return the non-null `DeleteAccountResult` to the caller. | Verified and guarded all code paths in `ProfileCubit` to return `result` directly without bare returns or dropping successful results. |
| **Production Test Coverage** | Confirmed: `account_deletion_test.dart` previously relied on a fake repository hardcoded to return `partialFailure`, rather than executing the actual production orchestration. | Updated `account_deletion_test.dart` to directly test `AccountDeletionOrchestrator` with injected operation boundaries for all 6 required production behaviors. |

---

## 3. Exact Files Changed

1. [`lib/features/profile/presentation/screens/update_profile_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/update_profile_screen.dart):
   - Removed `.trim()` from reauthentication password retrieval (`passwordController.text`).
   - Added `_hasIncompleteDeletion` state tracking.
   - Updated UI to display persistent incomplete deletion warning banner and retry button upon partial failure or cancelled retry.
2. [`lib/core/localization/app_localizations.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/app_localizations.dart):
   - Added typed localized getters for `retryAccountDeletion` and `accountDeletionUncertain` in English and Arabic.
3. [`lib/features/auth/data/data_sources/account_deletion_orchestrator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/account_deletion_orchestrator.dart):
   - Added destructive submit notification (`onDestructiveSubmitting`) into batch draining.
   - Guarded error branches to verify `_incompleteDeletionUids` before emitting `failedPreCleanup`.
   - Separated active deletion flags from incomplete deletion persistence.
   - Implemented safe write resumption on pre-cleanup aborts.
4. [`lib/features/auth/data/data_sources/auth_firebase_data_source.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/auth_firebase_data_source.dart):
   - Delegated `deleteAccount` to `AccountDeletionOrchestrator`.
   - Accepted and wired `onResumeCompetingWrites`.
   - Updated `_readUserProfile` to populate `providerIds` from `FirebaseAuth.currentUser.providerData`.
   - Sourced write suspension checks (`_isSuspended`) from the orchestrator.
5. [`lib/core/auth/auth_coordinator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/auth/auth_coordinator.dart):
   - Injected `onResumeCompetingWrites: (uid) => libraryDataSource.resumeWritesFor(uid)` into `AuthFirebaseDataSource`.
6. [`test/features/auth/account_deletion_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/account_deletion_test.dart):
   - Added unit tests exercising `AccountDeletionOrchestrator` directly for all 6 required production behaviors.
7. [`docs/reports/account_deletion_corrections_report.md`](file:///f:/FlutterProjects/MoviesApp/docs/reports/account_deletion_corrections_report.md):
   - Comprehensive correction report and source analysis.

---

## 4. Detailed Component Reviews & Source Excerpts

### 4.1 Password Handling Correction
In `UpdateProfileScreen`, the reauthentication password field controller is allocated locally within `_showPasswordReauthDialog`, cleared, and disposed inside a `finally` block. Password creation validation rules are not applied to existing passwords during reauthentication. The `.trim()` call was removed, ensuring that passwords with leading, trailing, or internal spaces reach Firebase Authentication unaltered.

#### Exact Source Excerpt: Reading and Forwarding the Password
*From [`lib/features/profile/presentation/screens/update_profile_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/update_profile_screen.dart#L481-L487):*
```dart
onPressed: () {
  final text = passwordController.text;
  if (text.isNotEmpty) {
    Navigator.of(dialogContext).pop(text);
  }
},
```

*Forwarded directly in [`lib/features/auth/data/data_sources/auth_firebase_data_source.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/auth_firebase_data_source.dart#L425-L430):*
```dart
// Pass password EXACTLY as entered - do not trim, lowercase, or alter.
final credential = EmailAuthProvider.credential(
  email: user.email!,
  password: password,
);
await user.reauthenticateWithCredential(credential);
```

---

### 4.2 Cleanup Progress Classification & Ambiguous-Result Behavior
A partial failure is not limited to Auth deletion failing after Firestore cleanup. The deletion sequence consists of:
1. Reauthentication & write pause.
2. Watch List collection draining in bounded batches (100 docs/batch, max 50 batches).
3. History collection draining in bounded batches.
4. User profile document deletion.
5. Firebase Auth user deletion.
6. Best-effort Google sign-out.

Before awaiting any batch commit or destructive write, `onDestructiveSubmitting()` is invoked. If an exception, timeout, session change, or batch exhaustion occurs after destructive work has begun, the operation is classified as `DeleteAccountResult.partialFailure`. `failedPreCleanup` is only returned when zero destructive mutations were submitted.

#### Exact Source Excerpt: Cleanup-Start/Progress Tracking and Failure Classification
*From [`lib/features/auth/data/data_sources/account_deletion_orchestrator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/account_deletion_orchestrator.dart#L135-L215):*
```dart
    try {
      // 4. Delete Watch List subcollection in bounded batches
      await _drainCollectionInBatches(
        drainBatch: deleteWatchlistBatch,
        markDestructiveBegun: () => hasDestructiveRequestBegun = true,
      );
      ...
    } catch (error) {
      _activeDeletionUids.remove(targetUid);

      if (hasDestructiveRequestBegun ||
          _incompleteDeletionUids.contains(targetUid)) {
        _incompleteDeletionUids.add(targetUid);
        _suspendedUids.add(targetUid);

        String msg =
            'Some account data was deleted, but account deletion could not be completed. You can retry to finish deleting remaining data.';
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
```

---

### 4.3 Pause, Resume, and Partial-Retry Wiring
- **Write Suspension**: Pauses profile and library writes during deletion.
- **Safe Resumption**: When an operation aborts before destructive cleanup (e.g. wrong password, cancellation, pre-check failure), `onResumeCompetingWrites` is called, restoring library writes via `LibraryFirestoreDataSource.resumeWritesFor(uid)` and clearing `_suspendedUids`.
- **Incomplete Deletion Retention**: If destructive cleanup began, `targetUid` is placed in `_incompleteDeletionUids` and `_suspendedUids`. Ordinary writes remain blocked so application logic cannot recreate partial data.
- **Explicit Same-UID Retry**: `_activeDeletionUids` is cleared when a call terminates, allowing an explicit retry for the same UID.
- **Cancelled Retry**: If the user cancels the reauthentication dialog on retry, `_incompleteDeletionUids` and `_suspendedUids` are retained; safeguards are not released.

#### Exact Source Excerpt: Pause/Resume and Partial-Retry Wiring
*Wiring in [`lib/core/auth/auth_coordinator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/auth/auth_coordinator.dart#L218-L228):*
```dart
      final remoteDataSource = AuthFirebaseDataSource(
        firebaseAuth: firebaseAuth,
        firebaseFirestore: firebaseFirestore,
        googleSignIn: googleSignIn,
        onPauseCompetingWrites: (uid) async {
          libraryDataSource.suspendWritesFor(uid);
          await libraryDataSource.awaitInFlightWrites();
        },
        onResumeCompetingWrites: (uid) {
          libraryDataSource.resumeWritesFor(uid);
        },
      );
```

*Safe Resumption on Abort in [`lib/features/auth/data/data_sources/account_deletion_orchestrator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/account_deletion_orchestrator.dart#L75-L81):*
```dart
    try {
      await reauthenticate(password: password, useGoogle: useGoogle);
    } catch (error) {
      _activeDeletionUids.remove(targetUid);
      if (!_incompleteDeletionUids.contains(targetUid)) {
        _suspendedUids.remove(targetUid);
        onResumeCompetingWrites?.call(targetUid);
      }
...
```

---

### 4.4 Authoritative Provider Mapping Findings
In Firebase Authentication, provider identity lives in `User.providerData`. The Firestore user document at `users/{uid}` does not store `providerData`. When `AppUserModel.fromMap` previously reconstructed an entity from Firestore, `providerIds` was defaulted to `[]`, wiping out provider identity on subsequent profile loads or updates.

`_readUserProfile` now dynamically binds `providerIds` from `FirebaseAuth.currentUser.providerData` whenever reading or updating the active user's profile:
```dart
      final currentAuth = authUser ??
          ((_firebaseAuth.currentUser?.uid == uid)
              ? _firebaseAuth.currentUser
              : null);

      if (currentAuth != null) {
        final authoritativeProviders = currentAuth.providerData
            .map((info) => info.providerId)
            .where((id) => id.isNotEmpty)
            .toList(growable: false);
        if (authoritativeProviders.isNotEmpty) {
          userEntity = userEntity.copyWith(providerIds: authoritativeProviders);
        }
      }
```
For Google reauthentication, `user.reauthenticateWithCredential(credential)` performs cryptographic reauthentication against Firebase Auth for the captured user; email comparison is retained only as an early mismatch guard.

---

### 4.5 Returning Deletion Results Across Session Resets
When Firebase Authentication deletes an account, `authStateChanges` immediately emits a `null` user event. If `ProfileCubit` or an auth coordinator increments a session generation during this transition, the deletion result must not be lost. Stale UI emissions are suppressed while the genuine `Future<DeleteAccountResult>` is returned to the caller.

#### Exact Source Excerpt: Returning Deletion Results After Session Reset
*From [`lib/features/auth/presentation/cubit/profile_cubit.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/profile_cubit.dart#L158-L170):*
```dart
      final result = await _deleteAccount(
        password: password,
        useGoogle: useGoogle,
      );

      if (isClosed) {
        return result;
      }

      // If session generation changed (e.g. authStateChanges reset the cubit),
      // we must NOT emit state for an old/reset session, BUT we MUST return the genuine result!
      if (generation != _sessionGeneration) {
        return result;
      }
```

---

## 5. Production Classes Exercised by New Unit Tests

In [`test/features/auth/account_deletion_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/account_deletion_test.dart), the following production classes and behaviors are exercised:

1. **`AccountDeletionOrchestrator`**:
   - Test 1: Exact password preservation (`'  Pass Word 123! \t '` forwarded untrimmed to reauth boundary).
   - Test 2: Later Watch List batch failing after earlier batches succeeded (proves `partialFailure` classification and incomplete-deletion tracking).
   - Test 3: Failure before cleanup releasing write suspension safely (`onResumeCompetingWrites` called; account usable).
   - Test 4: Partial failure permitting an explicit same-user retry (second call proceeds without "already in progress" rejection; succeeds).
   - Test 5: Cancelling a retry retaining incomplete-deletion status (returns `cancelled`, but preserves `hasIncompleteDeletion` and write suspension).
2. **`ProfileCubit`**:
   - Test 6: Successful deletion returning `DeleteAccountResult.success` even when an intervening `ProfileCubit.reset()` occurs during execution.

---

## 6. Client-Side Limitations & Outstanding Verification

### Client-Side Architectural Limits
1. **Application Termination During Cleanup**: Because cleanup is client-driven, terminating the application or losing power in the middle of a batch leaves documents in Firestore. On next launch, client in-memory state is reset; however, the user document and remaining subcollections will be cleaned up if the user initiates deletion again. (A backend Cloud Function trigger would be required for guaranteed server-side tombstoning).
2. **Batch Quota / Budget**: Cleanup is capped at 50 batches (up to 5,000 documents per subcollection). Accounts with larger datasets will halt with `cleanup-budget-exceeded` partial failure and prompt retry.
3. **Offline Timeout**: Firestore operations that time out locally cannot guarantee whether the server committed the write; the client treats all timeouts during destructive phases as uncertain partial failures.

### Outstanding Manual Validation (`MANUAL VALIDATION REQUIRED`)
Because this task operates under a STRICT CODE-ONLY policy without process execution:
- **Dependency Resolution & Compilation**: Run `flutter pub get` and `flutter analyze` in a developer environment to verify project-wide compilation.
- **Unit Test Execution**: Run `flutter test test/features/auth/account_deletion_test.dart` to execute the production orchestrator test suite.
- **End-to-End Firebase Testing**:
  - Test password reauthentication with a password containing leading and trailing whitespace.
  - Test Google reauthentication on physical Android/iOS devices.
  - Test partial failure recovery by disconnecting network mid-cleanup, verifying the incomplete deletion banner and retry button, and reconnecting to complete deletion.
