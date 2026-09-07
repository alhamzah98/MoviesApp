# Account Deletion Implementation Report

This report documents the client-side implementation of account deletion for the MoviesApp student project, including user identity reauthentication, competing write coordination, bounded subcollection cleanup, Firebase Authentication account deletion, explicit result contracts, and session lifecycle guards.

---

## 1. Exact Files Created/Modified and Responsibilities

### Created Files
1. [`lib/features/auth/domain/entities/delete_account_result.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/domain/entities/delete_account_result.dart):
   - Defines the `DeleteAccountResult` domain entity and `DeleteAccountStatus` enum (`success`, `cancelled`, `failedPreCleanup`, `partialFailure`).
   - Encapsulates outcome statuses, localized error messages, and operational details without leaking Firebase types into the domain layer.
2. [`test/features/auth/account_deletion_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/account_deletion_test.dart):
   - Source-only test suite using test doubles to verify reauthentication cancellation, cleanup failure isolation, empty collection idempotence, UID session switching guards, partial failure reporting, and preference preservation.
3. [`docs/reports/account_deletion_implementation_report.md`](file:///f:/FlutterProjects/MoviesApp/docs/reports/account_deletion_implementation_report.md):
   - This comprehensive implementation report.

### Modified Files
1. [`lib/features/auth/domain/entities/app_user.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/domain/entities/app_user.dart):
   - Added `providerIds` list property (`const []` default) and helper getters `hasPasswordProvider` and `hasGoogleProvider`.
   - Allows presentation and domain layers to verify supported reauthentication providers directly without importing Firebase.
2. [`lib/features/auth/data/models/app_user_model.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/models/app_user_model.dart):
   - Populated `providerIds` from Firebase `user.providerData` in `fromFirebaseUser`.
   - Updated `fromAuthUser`, `fromMap`, and `toEntity` to map provider identifiers.
3. [`lib/features/auth/domain/repositories/auth_repository.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/domain/repositories/auth_repository.dart):
   - Updated `deleteAccount({String? password, bool useGoogle = false})` to return `Future<DeleteAccountResult>`.
4. [`lib/features/auth/domain/use_cases/delete_account.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/domain/use_cases/delete_account.dart):
   - Updated `call({String? password, bool useGoogle = false})` to return `Future<DeleteAccountResult>` and forward reauthentication arguments.
5. [`lib/features/auth/data/data_sources/auth_remote_data_source.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/auth_remote_data_source.dart):
   - Updated `deleteAccount` interface contract to return `Future<DeleteAccountResult>`.
6. [`lib/features/auth/data/repositories/auth_repository_impl.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/repositories/auth_repository_impl.dart):
   - Implemented `deleteAccount` delegating to remote data source and guarded by `_guard`.
7. [`lib/features/library/data/data_sources/library_firestore_data_source.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/library/data/data_sources/library_firestore_data_source.dart):
   - Added `_suspendedUids` set and `_inFlightWrites` tracking.
   - Added `suspendWritesFor(String uid)`, `resumeWritesFor(String uid)`, and `awaitInFlightWrites({Duration timeout})`.
   - Guarded `_run` against executing new writes for suspended UIDs while tracking active operations.
8. [`lib/features/auth/data/data_sources/auth_firebase_data_source.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/auth_firebase_data_source.dart):
   - Accepted constructor-injected `onPauseCompetingWrites` callback.
   - Implemented `_suspendedUids` and `_inFlightProfileWrites` to suspend profile upserts and pause competing mutations.
   - Implemented `_deleteCollectionInBatches` with bounded 100-document batches, `Source.server` queries, and a finite budget of 50 batches.
   - Implemented the complete 8-step client-side deletion sequence in `deleteAccount`, including email/password and Google reauthentication, UID verification, subcollection cleanup, user document removal, and Auth account deletion.
   - Prevented `_loadOrCreateProfileForAuthUser` and `_mergeGoogleProfile` from recreating Firestore documents for suspended UIDs.
9. [`lib/core/auth/auth_coordinator.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/auth/auth_coordinator.dart):
   - Wired `onPauseCompetingWrites` in `_runBootstrap` to suspend library writes on `libraryDataSource` and await in-flight writes before account data deletion begins.
10. [`lib/features/auth/presentation/cubit/profile_state.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/profile_state.dart):
    - Added `ProfileStatus.partialFailure`.
    - Added `lastDeleteResult` property and `isPartialFailure` / `isDeleted` getters.
11. [`lib/features/auth/presentation/cubit/profile_cubit.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/profile_cubit.dart):
    - Updated `deleteAccount({String? password, bool useGoogle = false})` to return `Future<DeleteAccountResult>`.
    - Captured session generation and verified session validity before emitting states.
    - Emitted `ProfileStatus.deleted` on success, `ProfileStatus.ready` on cancellation, `ProfileStatus.partialFailure` on partial cleanup failure, and `ProfileStatus.failure` on pre-cleanup failure.
12. [`lib/core/localization/app_localizations.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/app_localizations.dart):
    - Added typed getters in English and Arabic for delete confirmation, password prompts, deletion progress, partial failure alerts, retry actions, and user mismatch errors.
    - Added mappings for `requires-recent-login`, `user-mismatch`, `provider-not-supported`, `cleanup-budget-exceeded`, `operation-in-progress`, and `session-invalid` in `translateError`.
13. [`lib/features/profile/presentation/screens/update_profile_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/update_profile_screen.dart):
    - Replaced the disabled / under development button with the active deletion flow.
    - Gated activation on genuine authenticated user, available coordinator, and no competing operations.
    - Added explicit localized confirmation dialog.
    - Added secure password prompt dialog for password users (memory-only controller cleared and disposed immediately).
    - Added partial failure modal alert with an explicit retry action.
14. [`test/features/library/movie_details_history_dispatch_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/library/movie_details_history_dispatch_test.dart):
    - Updated `_FakeAuthRepo.deleteAccount` to return `Future<DeleteAccountResult>`.
15. [`test/features/library/library_session_scope_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/library/library_session_scope_test.dart):
    - Updated `_FakeAuthRepository.deleteAccount` to return `Future<DeleteAccountResult>`.
16. [`test/features/auth/profile_cubit_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/profile_cubit_test.dart):
    - Updated `FakeProfileRepository.deleteAccount` to return `Future<DeleteAccountResult>`.
17. [`test/features/auth/auth_cubit_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/auth_cubit_test.dart):
    - Updated `FakeAuthRepository.deleteAccount` to return `Future<DeleteAccountResult>`.

---

## 2. Reauthentication Methods Supported and Unsupported

### Supported Methods
1. **Email and Password (`password`)**:
   - Detected via `user.providerData` containing `'password'`.
   - Presentation displays a dedicated, secure dialog requesting the current password.
   - Reauthenticates using `EmailAuthProvider.credential(email: user.email!, password: password)`.
   - Memory management: Password controller is allocated on-demand, obscured in UI, trimmed into short-lived local variable, and immediately cleared and disposed in a `finally` block. Passwords are never logged or stored.
2. **Google Sign-In (`google.com`)**:
   - Detected via `user.providerData` containing `'google.com'`.
   - Reuses initialized `GoogleSignIn.instance.authenticate()`.
   - Obtains `idToken` and creates `GoogleAuthProvider.credential(idToken: idToken)`.
   - Validates that the Google account selected matches the authenticated Firebase user email (preventing account mismatch).
   - Reauthenticates using `user.reauthenticateWithCredential(credential)`.
   - Cancellation (`GoogleSignInExceptionCode.canceled`) is cleanly returned as `DeleteAccountResult.cancelled` with zero data mutations.

### Unsupported Providers
- Any account provider not matching `'password'` or `'google.com'` (e.g. Phone, Apple, Twitter, anonymous credentials) returns `DeleteAccountResult.failedPreCleanup` with a localized message (`l10n.unsupportedReauthProvider`), preventing unauthorized or unhandled execution before any data deletion starts.

---

## 3. Exact Deletion Order and Firestore Paths

Client-side cleanup executes in strict linear order:

1. **User Confirmation**: Explicit user confirmation obtained via dialog.
2. **User Reauthentication**: Current authenticated user reauthenticated via credential before touching any database data.
3. **Competing Write Coordination**:
   - `onPauseCompetingWrites` callback invoked to suspend library writes on `LibraryFirestoreDataSource`.
   - In-flight library and profile writes awaited (flushed).
   - `_suspendedUids` updated on both data sources to reject new mutations and prevent profile auto-recreation.
4. **Watchlist Cleanup**:
   - Path: `users/{uid}/watchlist/{movieId}`
   - Deleted document-by-document in bounded batches of 100 documents.
   - Read directly using `Source.server` without `orderBy` or `where` clauses to catch all documents (even malformed ones).
5. **History Cleanup**:
   - Path: `users/{uid}/history/{movieId}`
   - Deleted document-by-document in bounded batches of 100 documents using `Source.server`.
6. **User Document Cleanup**:
   - Path: `users/{uid}`
   - Single document deletion: `await _users.doc(targetUid).delete()`.
7. **Firebase Authentication Account Deletion**:
   - Invoked only after all Firestore documents have been confirmed deleted: `await user.delete()`.
   - If this phase fails (e.g. recent login expired or network error), the operation reports `DeleteAccountResult.partialFailure`.
8. **Best-Effort Google Sign-Out**:
   - `await _googleSignIn.signOut()`. Errors are safely caught so they do not invalidate completed account deletion.
9. **In-Memory State Reset & Router Resolution**:
   - Auth stream receives null user, resetting `AuthCubit`, `ProfileCubit`, `WatchlistCubit`, and `HistoryCubit`.
   - Router automatically resolves and redirects to `RouteConstants.login`.

---

## 4. Session/UID Guards and Competing-Write Coordination

- **Target UID Capture**: The authenticated UID is captured once at the beginning of the deletion operation (`targetUid = user.uid`). Every deletion batch and document target explicitly references only this captured UID.
- **Pre-Phase Verification**: Before each phase (after reauth, before Firestore batching, and before Auth deletion), the active user is re-verified: `if (_firebaseAuth.currentUser?.uid != targetUid) abort`.
- **Auto-Recreation Suspension**: When a user document is deleted, background `authStateChanges` events normally call `_loadOrCreateProfileForAuthUser`. If `targetUid` is in `_suspendedUids`, this upsert/creation is completely bypassed, preventing deleted documents from being recreated.
- **Competing Mutations Rejection**: Calls to `addToWatchlist`, `removeFromWatchlist`, `recordHistory`, or `updateProfile` for a suspended UID throw `AppException('operation-in-progress')`.
- **In-Flight Write Flush**: `awaitInFlightWrites` and `_awaitInFlightProfileWrites` track active completers and await their completion before destructive batch deletion begins. Timeouts are bounded and not treated as write cancellations.
- **Session Replacement Guard**: `ProfileCubit` increments `_sessionGeneration` for every operation and checks `if (isClosed || generation != _sessionGeneration) return;`, ensuring stale asynchronous callbacks from previous sessions are discarded.

---

## 5. Success, Cancellation, Failure, Partial-Failure, and Retry Behavior

| Outcome | Trigger | State Emitted | Data Mutations | UI Feedback |
| :--- | :--- | :--- | :--- | :--- |
| **Success** | All Firestore data deleted + Auth account deleted | `ProfileStatus.deleted` | All Watchlist, History, User doc, and Auth user deleted | Success snackbar; Router resolves to Login |
| **Cancellation** | User dismisses dialog or cancels Google sign-in | `ProfileStatus.ready` | None (0 deletions) | Dialog closes; profile view remains interactive |
| **Pre-Cleanup Failure** | Wrong password, user mismatch, or unsupported provider | `ProfileStatus.failure` | None (0 deletions) | Localized error message; account remains intact |
| **Partial Failure** | Firestore cleanup succeeds, but Auth deletion fails | `ProfileStatus.partialFailure` | Firestore subcollections/doc deleted; Auth user remains | Modal dialog explaining incomplete deletion; explicit **Try Again** action |

### Retry Behavior
- Partial failure leaves `targetUid` in the suspended set.
- When the user taps **Try Again** in the partial failure dialog, the deletion flow is invoked again for the same account.
- Already deleted collections return empty snapshots and are safely skipped.
- Deleting an already-deleted Firestore document is an idempotent no-op.
- Auth user deletion is re-attempted.
- The app does not automatically loop or retry indefinitely.

---

## 6. Interaction with Auth-Stream Resets and Router Navigation

- When `user.delete()` completes, Firebase Authentication emits `null` on `authStateChanges()`.
- `AuthCoordinator` listens to `_authCubit`, detects unauthenticated status, clears `_activeSessionUid`, and calls `_watchlistCubit?.reset()` and `_historyCubit?.reset()`.
- `AppRouter` listens to `coordinator` via `refreshListenable`. When `!coordinator.isAuthenticated` on protected route `/update-profile`, it redirects to `RouteConstants.login`.
- `ProfileCubit` checks `isClosed` and session generation to avoid emitting into closed cubits or emitting state transitions after the session has ended.
- A null auth event alone is never interpreted as proof of deletion; `DeleteAccountResult.success` is explicitly required to report success.

---

## 7. English/Arabic UI Additions

All added strings are typed getters in `AppLocalizations`:

| Key | English | Arabic |
| :--- | :--- | :--- |
| `deleteAccount` | Delete Account | حذف الحساب |
| `deleteAccountConfirmTitle` | Delete Account | حذف الحساب |
| `deleteAccountConfirmMessage` | This will permanently delete your MoviesApp account, profile, Watch List, and History. This action cannot be undone. | سيؤدي هذا إلى حذف حسابك في تطبيق الأفلام، وملفك الشخصي، وقائمة المشاهدة، وسجل المشاهدة نهائياً. لا يمكن التراجع عن هذا الإجراء. |
| `deleteAccountConfirmAction` | Delete Account Permanently | حذف الحساب نهائياً |
| `deleteAccountWarning` | Deleting your account will permanently remove all your saved data and watch lists. | سيؤدي حذف الحساب إلى إزالة جميع بياناتك المحفوظة وقوائم المشاهدة بشكل نهائي. |
| `reauthenticateTitle` | Confirm Identity | تأكيد الهوية |
| `reauthenticatePasswordPrompt` | Please enter your current password to confirm account deletion. | يرجى إدخال كلمة المرور الحالية لتأكيد حذف الحساب. |
| `reauthenticateWithGoogle` | Reauthenticate with Google | إعادة المصادقة بواسطة جوجل |
| `reauthenticateFailed` | Reauthentication failed. Please verify your credentials and try again. | فشلت إعادة المصادقة. يرجى التحقق من بياناتك والمحاولة مرة أخرى. |
| `accountDeletedSuccess` | Account deleted successfully. | تم حذف الحساب بنجاح. |
| `accountDeletionFailed` | Failed to delete account. Please try again. | فشل حذف الحساب. يرجى المحاولة مرة أخرى. |
| `accountDeletionPartialFailureTitle` | Incomplete Account Deletion | حذف غير مكتمل للحساب |
| `accountDeletionPartialFailure` | Some application data was removed, but account deletion could not be completed. You can retry to finish deleting remaining data. | تم حذف بعض بيانات التطبيق، ولكن تعذر إكمال حذف الحساب بالكامل. يمكنك إعادة المحاولة لتنظيف باقي البيانات. |
| `unsupportedReauthProvider` | The sign-in method for this account is not supported for account deletion. | طريقة تسجيل الدخول لهذا الحساب غير مدعومة لحذف الحساب. |
| `userMismatchError` | The authenticated account does not match the current user. | حساب المصادقة لا يطابق المستخدم الحالي. |
| `deletingAccount` | Deleting account... | جارٍ حذف الحساب... |

---

## 8. Tests Written but Not Executed

Placed in [`test/features/auth/account_deletion_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/auth/account_deletion_test.dart):
1. `Cancelled or failed reauthentication causes zero Firestore and Auth deletions`:
   - Validates that cancellation or bad credentials abort the flow before calling watchlist, history, user doc, or auth deletion.
2. `Cleanup failure prevents Auth deletion`:
   - Validates that an error in Firestore cleanup prevents `user.delete()` from being invoked, ensuring permissions are not revoked prematurely.
3. `Empty or missing library documents allow retry to complete successfully`:
   - Validates that retrying a previously failed cleanup handles empty subcollections gracefully and completes Auth deletion.
4. `Session changes prevent destructive writes to another UID`:
   - Validates that if the current session UID switches, the operation aborts with `failedPreCleanup` and does not touch data belonging to another UID.
5. `Partial failure never reports complete success`:
   - Validates that if Firestore data is deleted but Auth deletion fails, `isSuccess` is false, `isPartialFailure` is true, and the cubit state is `ProfileStatus.partialFailure`.
6. `Successful deletion clears user state while strictly preserving locale and onboarding preferences`:
   - Validates that `app_language` ('ar') and `onboarding_completed` (true) are preserved in `SharedPreferences` after account deletion.

---

## 9. Client-Side Limitations

1. **Lack of Cross-Service Atomicity**:
   - Firestore and Firebase Authentication do not support a single atomic multi-resource transaction from the Flutter client.
   - If the app process is terminated (e.g. force quit, battery death, crash) after subcollection deletion but before `user.delete()`, the user's data is gone while the Auth user remains. The implementation surfaces this as partial failure on retry.
2. **Multi-Device Concurrency**:
   - Client-side write suspension affects only the active local application instance. If the user is simultaneously modifying their watchlist on another device, writes from that other device might race with batch deletion.
3. **Client Network Outages**:
   - A network disconnection after Firestore cleanup may leave the Auth user active until connectivity is restored and re-attempted.

---

## 10. MANUAL VALIDATION REQUIRED

> [!WARNING]
> **DO NOT USE PRODUCTION ACCOUNTS FOR TESTING ACCOUNT DELETION.**  
> Create and use a disposable test account only.

Follow these steps to validate in Android Studio after Firebase is initialized:

1. **Resolve dependencies (if needed)**:
   ```bash
   flutter pub get
   ```
2. **Launch Application**:
   Run `lib/main.dart` on an emulator or physical test device.
3. **Register / Sign In with Disposable Account**:
   - Create a test user (e.g. `delete_test_01@example.com` / `Password123`).
   - Add 2 movies to Watch List.
   - View 2 movies so Viewing History is populated.
4. **Test Cancellation**:
   - Navigate to Profile -> Update Profile.
   - Tap **Delete Account**.
   - In the confirmation dialog, tap **Cancel**.
   - Verify no dialogs appear and data remains intact.
5. **Test Wrong Password Reauthentication**:
   - Tap **Delete Account** -> Confirm.
   - Enter an incorrect password -> Tap Delete.
   - Verify an error snackbar appears, and Watch List / History still exist.
6. **Test Confirmed Account Deletion (Email/Password)**:
   - Tap **Delete Account** -> Confirm.
   - Enter correct password (`Password123`).
   - Observe loading indicator on button ("Deleting account...").
   - Verify success message appears and router redirects to Login screen.
   - In Firebase Console, verify `users/{uid}/watchlist`, `users/{uid}/history`, `users/{uid}`, and Firebase Auth user are deleted.
   - Restart the app and verify language preference and onboarding state are preserved.
7. **Test Confirmed Account Deletion (Google Sign-In)**:
   - Sign in with a disposable Google test account.
   - Navigate to Update Profile -> Tap **Delete Account** -> Confirm.
   - Select the same Google account in the Google account picker.
   - Verify successful deletion and redirection to Login.

---

## 11. Unfinished Functionality or Configuration

- None within the scope of this client-side student project.
- Production multi-region guarantees or automated cascade deletion across app crashes require backend Firebase Cloud Functions (specifically `functions.auth.user().onDelete`), which were explicitly prohibited for this student-tier client task.

---

## 12. Strict Code-Only Execution Confirmation

I confirm that:
- NO terminal was opened.
- NO command, script, task, or background process was executed.
- NO Flutter, Dart, Git, Gradle, or ADB commands were run (`run`, `test`, `analyze`, `format`, `pub get`, `build`).
- NO emulators or devices were launched, inspected, or controlled.
- NO Firebase network requests, authentication flows, or real deletions were initiated.
- NO packages were installed and no remote repositories accessed.
- All implementations were created strictly through workspace editor tools.
