# Watch List and Viewing History Integration Report

**Date:** 2026-09-07  
**Project:** MoviesApp (Flutter)  
**Execution Mode:** STRICT CODE-ONLY (No terminal commands, build, test, analyzer, Git, emulator, or network execution)

---

## 1. Exact Files Created and Modified & Responsibilities

### Files Created
1. `firestore.rules`
   - Local Cloud Firestore security rules file at the project root.
   - Restricts read, write, and delete operations across `users/{uid}`, `users/{uid}/watchlist/{movieId}`, and `users/{uid}/history/{movieId}` strictly to the authenticated owner (`request.auth.uid == uid`).
   - Validates document schema consistency (`movieId` integer type and matching path string) while separating deletion rules from write-data schema validation.
   - Denies public access and global wildcards.
2. `test/features/library/library_session_scope_test.dart`
   - Focused unit regression tests verifying `AuthCoordinator` session scope lifecycle:
     - Visible library data is cleared and observation subscriptions cancelled on sign-out.
     - New UID sign-in restarts observation without reusing previous user data.
     - Ordinary profile updates for the same UID do not tear down or restart subscriptions.
3. `test/features/library/watchlist_cubit_test.dart`
   - Focused regression tests for `WatchlistCubit`:
     - Preserves loaded library movie data on `addMovie` and `removeMovie` mutation failures.
     - Recovers cleanly from stream observation errors via `retry()` without zombie subscription retention.
4. `test/features/library/history_cubit_test.dart`
   - Focused regression tests for `HistoryCubit`:
     - Recovers from failed viewing history observation upon `retry()`.
     - `reset()` clears in-memory history data and restores initial state.
     - Failure during view recording does not clear previously loaded movies.
5. `test/features/library/movie_details_history_dispatch_test.dart`
   - Focused widget regression test for `MovieDetailsScreen`:
     - Verifies viewing history records exactly once after movie details load succeeds.
     - Confirms duplicate-dispatch protection prevents re-recording on suggestions completion, suggestions retry, and screen rebuilds.
6. `docs/reports/watchlist_history_integration_report.md`
   - This comprehensive documentation report detailing architecture, lifecycle safety, rules, tests, and manual verification checklists.

### Files Modified
1. `lib/features/auth/data/data_sources/auth_firebase_data_source.dart`
   - Removed the 5-second `Future.delayed` polling retry loop in `authStateChanges()`.
   - Introduced `_PendingRegistration` coordination tracking instantiated *before* `createUserWithEmailAndPassword()` is dispatched.
   - Ensures intermediate stream events wait on the atomic registration completer, preventing race conditions that create skeleton profiles or authenticate rolled-back users if profile persistence fails.
2. `lib/features/auth/presentation/cubit/auth_cubit.dart`
   - Added `_sessionGeneration` tracking and `isClosed` checks to `signInWithEmail`, `registerWithEmail`, `signInWithGoogle`, and `signOut`.
   - Prevents stale asynchronous network responses from restoring a signed-out user or overwriting a newer session.
3. `lib/features/auth/presentation/cubit/profile_cubit.dart`
   - Added `_sessionGeneration`, `_expectedUid` validation, and a `reset()` method.
   - Prevents delayed profile fetches or updates from overriding a different user's session or resurrecting cleared profile state.
4. `lib/app/app_router.dart`
   - Guarded `state.extra` in the `/update-profile` route: requires `coordinator.currentUser != null && extraUser.uid == coordinator.currentUser.uid`.
   - Prevented route-extra user objects from overriding confirmed signed-out state or different active UIDs.
   - Injected `coordinator.watchlistCubit`, `coordinator.historyCubit`, and `coordinator` into `MovieDetailsScreen`.
5. `lib/features/profile/presentation/screens/update_profile_screen.dart`
   - Updated `_currentUser` getter to enforce `coordinator.currentUser` authority (returns `null` if signed out).
   - Added unauthenticated guard to `_handleUpdate` preventing submission without an active session.
6. `lib/core/auth/auth_coordinator.dart`
   - Composed genuine `LibraryFirestoreDataSource`, `LibraryRepositoryImpl`, and use cases upon successful Firebase bootstrap.
   - Instantiated and owned `WatchlistCubit` and `HistoryCubit`.
   - Added `_activeSessionUid` tracking: starts observation on authenticated UID; ignores ordinary profile updates for the same UID; resets cubits and cancels subscriptions immediately on sign-out or UID change.
   - Differentiated missing Firebase configuration (`AuthBootstrapStatus.configurationUnavailable`) from unexpected runtime failures (`AuthBootstrapStatus.failed`) with retry capability.
   - Disposed `_watchlistCubit` and `_historyCubit` in `dispose()`.
7. `lib/core/di/app_dependencies.dart`
   - Added `dispose()` method forwarding to `authCoordinator.dispose()`.
8. `lib/app/app.dart`
   - Converted `MoviesApp` to a `StatefulWidget` with an unmount lifecycle hook invoking `widget.dependencies.dispose()`.
9. `lib/features/library/presentation/cubit/watchlist_cubit.dart`
   - Added `retry()` and `reset()` methods.
   - Cleaned up subscription handle upon stream `onError` so subsequent `startObserving()` or `retry()` calls are not blocked by zombie subscriptions.
10. `lib/features/library/presentation/cubit/history_cubit.dart`
    - Added `retry()` and `reset()` methods.
    - Cleaned up subscription handle upon stream `onError` to enable clean recovery.
11. `lib/features/movie_details/presentation/widgets/hero_header.dart`
    - Added optional `bookmarkAction` widget positioned symmetrically at `topPadding + 8, right: 16`.
12. `lib/features/movie_details/presentation/screens/movie_details_screen.dart`
    - Integrated the bookmark control button on `HeroHeader` with confirmed membership state, pending indicator, accessible tooltips, mutation disabling during loading/pending/unauthenticated, and non-intrusive snackbar error reporting.
    - Implemented viewing history frontend duplicate-dispatch guard triggering once per visit when movie details load succeeds.
13. `lib/features/profile/presentation/screens/profile_screen.dart`
    - Wired real `WatchlistCubit` and `HistoryCubit` states.
    - Preserved unknown counts as `'-'` during initial/loading states without fabricated zeroes.
    - Handled Watch List and History loading, failures, and empty states independently.
    - Enabled per-item removal from the Watch List with per-card pending indicators.
    - Provided retry buttons for recoverable observation errors while preserving loaded data.
14. `lib/features/main/presentation/screens/main_shell_screen.dart`
    - Passed `coordinator.watchlistCubit` and `coordinator.historyCubit` to `ProfileScreen`.

---

## 2. Authentication Safety Findings and Corrections

| Area | Finding in Source | Correction Applied |
|---|---|---|
| **Registration Race & Polling** | `AuthFirebaseDataSource` contained a `while (_pendingRegistrationUids.contains(...) && retries < 50)` polling loop with 100ms delays. If registration failed and deleted the user, delayed stream listeners could still race and query/create profiles for rolled-back users. | Replaced the polling loop with atomic `_PendingRegistration` coordination. Coordination is registered *before* `createUserWithEmailAndPassword` is called. Completes with the created `AppUser` on success, or `null` on failure. `authStateChanges` awaits the future and emits `null` if registration rolled back, preventing skeleton creation or authenticating dead sessions. |
| **Delayed Auth/Profile Results** | In `AuthCubit` and `ProfileCubit`, asynchronous network calls (`signIn`, `register`, `signOut`, `loadCurrentUser`, `updateProfile`) could finish after a user signed out or switched sessions, resurrecting old sessions or overwriting profile states. | Introduced `_sessionGeneration` counters in both cubits. Incremented at operation start and on `signOut`/`reset`. After awaiting async calls, emissions are dropped if the generation changed or cubit is closed. In `ProfileCubit`, `_expectedUid` ensures data belonging to another UID is ignored. |
| **Route Extra Override** | In `AppRouter`, `updateProfile` took `state.extra as AppUser` without checking if the coordinator was signed out or if the extra user belonged to a different session UID. | Added an explicit guard: `extraUser` is only used if `coordinator.currentUser != null && extraUser.uid == coordinator.currentUser.uid`. In `UpdateProfileScreen`, `_currentUser` treats `coordinator.currentUser` as authoritative. |
| **Bootstrap Error Classification** | `AuthCoordinator` caught all exceptions in bootstrap and marked `_status = AuthBootstrapStatus.configurationUnavailable`. | Differentiated genuine missing configuration (e.g. `core/no-app`, missing options/google-services) from runtime failures (network, internal errors). Runtime errors set `AuthBootstrapStatus.failed` with retry capability via `retryBootstrap()`. |
| **Lifecycle & Disposal** | `AppDependencies` and `MoviesApp` lacked disposal hooks, leaving `AuthCoordinator` subscriptions and cubits undisposed on application unmount. | Added `dispose()` to `AppDependencies` and converted `MoviesApp` into a `StatefulWidget` calling `dependencies.dispose()` on unmount. |

---

## 3. Dependency & Subscription Ownership and UID-Change Handling

- **Scope Composition Root:** `AuthCoordinator` owns the authenticated library scope. Once Firebase initializes, it instantiates `LibraryFirestoreDataSource(firebaseAuth, firebaseFirestore)` and `LibraryRepositoryImpl`.
- **Cubit Ownership:** `WatchlistCubit` and `HistoryCubit` are owned by `AuthCoordinator` and exposed via getters to `AppRouter`, `MovieDetailsScreen`, and `ProfileScreen`.
- **UID-Change & Sign-Out Handling:**
  - `_activeSessionUid` tracks the authenticated user's UID.
  - When `_authCubit` emits an authenticated state with a new UID:
    1. `_activeSessionUid = user.uid;`
    2. `_watchlistCubit.reset()` and `_historyCubit.reset()` are called, immediately cancelling previous stream subscriptions and clearing visible library lists.
    3. `_watchlistCubit.startObserving()` and `_historyCubit.startObserving()` are invoked for the new session.
  - When ordinary profile updates occur for the *same* UID (`user.uid == _activeSessionUid`), subscriptions are preserved without recreation.
  - When the user signs out (`user == null`):
    1. `_activeSessionUid = null;`
    2. `_watchlistCubit.reset()` and `_historyCubit.reset()` immediately cancel subscriptions and clear data.
  - On coordinator disposal, both cubits and auth subscriptions are cleanly closed.

---

## 4. Bookmark Add/Remove, Pending, and Error Behavior

- **Location:** In `HeroHeader`, positioned symmetrically opposite to the Back button (`top: topPadding + 8, right: 16`).
- **Visual Presentation:**
  - 40x40 circular translucent container matching the Back button styling (`Colors.black54` with subtle white border).
  - Unsaved: `Icons.bookmark_border_rounded` with `AppColors.onBackground`.
  - Saved: `Icons.bookmark_rounded` with `AppColors.primary` (Gold/Yellow).
  - Loading/Unresolved Membership: 18x18 `CircularProgressIndicator` with `AppColors.primary`.
  - Pending Mutation: 18x18 `CircularProgressIndicator` with `AppColors.primary`.
- **Mutation Rules:**
  - Mutation is disabled while membership is loading, while the item is in `pendingMovieIds`, or when the user is unauthenticated.
  - Tapping when unauthenticated presents a floating SnackBar prompt: *"Please sign in to save movies to your watch list."* without initiating any Firestore write.
  - When enabled, tapping invokes `watchlistCubit.toggleMovie(LibraryMovie.fromMovie(movie))` using the existing domain entity snapshot.
  - Membership is authoritative from the Firestore snapshot stream; local optimistic falsehoods are avoided.
  - Mutation failures emit `WatchlistStatus.failure` with an error message displayed as a floating SnackBar, leaving Movie Details fully visible and intact.

---

## 5. Viewing History Trigger & Duplicate-Dispatch Protection

- **Trigger:** Dispatched strictly after the main movie details load succeeds (`state.movie != null && state.movie.id == widget.movieId`) for an authenticated session.
- **Frontend Duplicate-Dispatch Guard:**
  - `_recordedHistoryMovieId` in `_MovieDetailsScreenState` tracks the recorded ID for the current visit.
  - Dispatched once per screen visit.
  - Rebuilds, bookmark toggle mutations, suggestions completion, and suggestion retry errors do not trigger another history record dispatch.
  - If a user navigates to a different movie (via similar suggestions), `didUpdateWidget` resets `_recordedHistoryMovieId = null`, allowing the new movie to be recorded once after its details load.
  - A separate later visit to the same movie creates a new `MovieDetailsScreen` instance, which records once for that new visit.
  - A history write failure in `HistoryCubit` emits `HistoryStatus.failure` inside the cubit and does not fail or crash `MovieDetailsScreen`.

---

## 6. Profile Lists, Counts, Independent Errors, and Retries

- **Real State Binding:** `ProfileScreen` is directly bound to `WatchlistCubit` and `HistoryCubit` through `BlocBuilder`.
- **Count Presentation:**
  - Ready/loaded state displays the real item count (`watchlistState.movies.length` / `historyState.movies.length`).
  - Loading, initial, or unauthenticated states display `'-'` via `_StatsSummaryRow`. No fabricated zero counts are shown during loading.
- **Independent Tab Content:**
  - Failure or loading in the Watch List does not affect or hide the History tab, and vice versa.
  - When a collection is confirmed empty (`ready` with 0 items), `_EmptyListView` is rendered.
  - When an error occurs while the list is empty, an error message and a *"Try Again"* retry button are displayed.
  - Previously loaded data is preserved during recoverable errors (e.g. mutation errors).
- **Working Retry:**
  - `WatchlistCubit.retry()` and `HistoryCubit.retry()` force-cancel any stale subscription and re-subscribe cleanly.
  - Stream `onError` releases the internal subscription handle so subsequent calls to `startObserving()` or `retry()` are not blocked by zombie subscriptions.
- **Watch List Item Removal:**
  - Each item in the Watch List grid includes a remove bookmark icon button (`Icons.bookmark_remove_rounded`) on the card.
  - Per-item pending feedback displays a 14x14 circular spinner on that specific card while deletion is in-flight.
  - Tapping the movie card continues through the existing movie details route helper.
  - History entries do not display delete controls (bulk destructive actions and automatic history deletion remain disabled).

---

## 7. Firestore Paths and Local Rules Added

The local `firestore.rules` file was created with the following rules:

```rules
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isAuthenticated() {
      return request.auth != null;
    }

    function isOwner(uid) {
      return isAuthenticated() && request.auth.uid == uid;
    }

    // User profile document: users/{uid}
    match /users/{uid} {
      allow read: if isOwner(uid);
      allow create, update: if isOwner(uid)
        && (request.resource.data.uid == uid || !('uid' in request.resource.data));
      allow delete: if isOwner(uid);

      // User watchlist subcollection: users/{uid}/watchlist/{movieId}
      match /watchlist/{movieId} {
        allow read: if isOwner(uid);
        allow create, update: if isOwner(uid)
          && request.resource.data.movieId is int
          && string(request.resource.data.movieId) == movieId;
        allow delete: if isOwner(uid);
      }

      // User viewing history subcollection: users/{uid}/history/{movieId}
      match /history/{movieId} {
        allow read: if isOwner(uid);
        allow create, update: if isOwner(uid)
          && request.resource.data.movieId is int
          && string(request.resource.data.movieId) == movieId;
        allow delete: if isOwner(uid);
      }
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

- Explicitly covers:
  - `users/{uid}`
  - `users/{uid}/watchlist/{movieId}`
  - `users/{uid}/history/{movieId}`
- Enforces owner authentication (`request.auth.uid == uid`).
- Enforces `movieId` integer validation matching the document ID string on writes.
- Separates delete operations from write-data validation.
- Denies all other collections.
- **MANUAL ACTION REQUIRED:** The user must review and publish these rules in the Firebase Console or via Firebase CLI before runtime verification.

---

## 8. Tests Written (Explicitly Not Executed)

Under strict code-only guidelines, no test runner or command was executed. The following test files were created with domain fakes and test widgets:

1. `test/features/library/library_session_scope_test.dart`
   - `resets and clears library data on sign-out so old-session data does not persist`
   - `restarts observation for new UID on session change without reusing previous user ready state`
   - `ordinary profile updates for the same UID do not recreate subscriptions`
2. `test/features/library/watchlist_cubit_test.dart`
   - `preserves existing watchlist movies when addMovie mutation fails`
   - `preserves existing watchlist movies when removeMovie mutation fails`
   - `recovers from failed observation without zombie subscription blocking retry`
3. `test/features/library/history_cubit_test.dart`
   - `recovers from failed history observation upon retry()`
   - `reset() clears movies and resets to initial status`
   - `record failure does not lose previously loaded movies`
4. `test/features/library/movie_details_history_dispatch_test.dart`
   - `records history once on movie details load and does NOT dispatch again on suggestions completion or rebuild`

---

## 9. Missing Firebase Setup & Manual Validation Checklist

### Android Gradle Configuration Locations (Read from actual source)
- `android/settings.gradle.kts` (Kotlin DSL):
  - Plugin declaration block is located at lines 20-24 (`plugins { ... }`).
  - Google Services plugin should be declared as:
    ```kotlin
    id("com.google.gms.google-services") version "4.4.2" apply false
    ```
- `android/app/build.gradle.kts` (Kotlin DSL):
  - Plugin application block is located at lines 1-6 (`plugins { ... }`).
  - Google Services plugin should be applied as:
    ```kotlin
    id("com.google.gms.google-services")
    ```
- `android/app/google-services.json`:
  - Missing from workspace. Must be obtained from the Firebase Console project settings and placed in `android/app/`.

### Manual Validation Checklist
1. **MANUAL ACTION REQUIRED: Google Services File**:
   - Download `google-services.json` from the Firebase Console.
   - Place in `android/app/google-services.json`.
2. **MANUAL ACTION REQUIRED: Gradle Plugins**:
   - Add `id("com.google.gms.google-services") version "4.4.2" apply false` to `android/settings.gradle.kts`.
   - Add `id("com.google.gms.google-services")` to `android/app/build.gradle.kts`.
3. **MANUAL ACTION REQUIRED: Firestore Rules**:
   - Copy the contents of `firestore.rules` into Firebase Console -> Firestore Database -> Rules tab, and click **Publish**.
4. **MANUAL VALIDATION REQUIRED: Watch List & Details**:
   - Launch app, sign in with email or Google.
   - Open any movie in Home, Search, or Browse.
   - Verify the bookmark icon in the hero header displays saved/unsaved status accurately.
   - Tap the bookmark button; verify it indicates pending feedback and toggles state.
   - Return to Profile tab; verify the movie appears under the Watch List tab with count updated.
   - Tap the remove button on the movie card in Profile; verify it shows pending feedback and removes the movie.
5. **MANUAL VALIDATION REQUIRED: Viewing History**:
   - Open a movie details screen.
   - Return to Profile and switch to History tab; verify the movie appears with count updated.
   - Reopen the same movie and observe that duplicate entries are not created (existing document updated with incremented `viewCount`).
6. **MANUAL VALIDATION REQUIRED: Session Safety**:
   - Log out from Profile; verify Watch List and History lists immediately clear.
   - Log in with another account; verify old user's movies are not displayed.

---

## 10. Outstanding Unfinished Actions

As specified in project scope:
- **Account Deletion:** UI and domain methods exist, but full multi-collection deletion workflows and re-authentication prompts remain deferred.
- **Trailer Playback:** The play indicator on Movie Details is an aesthetic control; video player integration remains deferred.
- **Localization:** Multi-language string tables remain deferred.

---

## 11. Strict Code-Only Compliance Confirmation

I confirm that during this task:
- No command, terminal, or script was executed.
- No Flutter or Dart tools were run (`run`, `test`, `analyze`, `format`, `pub get`, `build`, `doctor`, `devices`).
- No emulator, device, Android Studio automation, Gradle, or ADB task was started.
- No network requests, API calls, or Firebase Console interactions were performed.
- No packages or SDK dependencies were modified or downloaded.
- No Git commands, commits, pushes, or repository changes were made outside workspace file edits.
- All code, security rules, and tests were produced purely via workspace file authoring tools.
