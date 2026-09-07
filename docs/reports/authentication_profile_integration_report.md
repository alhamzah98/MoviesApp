# Authentication and Profile Integration Report

## 1. Exact Files Created and Modified

### Files Created:
* [auth_coordinator.dart](file:///f:/FlutterProjects/MoviesApp/lib/core/auth/auth_coordinator.dart)
  * Implements the central application-level owner for authentication lifecycle, Firebase bootstrap, session state, and router coordination.
  * Extends `ChangeNotifier` to serve as the single `refreshListenable` for `GoRouter`.
  * Manages `AuthBootstrapStatus` (`uninitialized`, `initializing`, `available`, `configurationUnavailable`, `failed`).
  * Safely handles missing platform configuration without throwing unhandled exceptions before or after `runApp`.
  * Instantiates `FirebaseAuth`, `FirebaseFirestore`, `GoogleSignIn`, `AuthFirebaseDataSource`, `AuthRepositoryImpl`, `AuthCubit`, `ProfileCubit`, and `PasswordResetCubit` once Firebase initializes.
  * Exposes `updateSharedUser(AppUser)` to propagate profile changes reactively across all listening screens without requiring app restart.
* [auth_cubit_test.dart](file:///f:/FlutterProjects/MoviesApp/test/features/auth/auth_cubit_test.dart)
  * Unit tests for `AuthCubit` validating `signInWithEmail`, `registerWithEmail`, `updateUser`, and `signOut` state progressions using an in-memory domain fake (`FakeAuthRepository`).
* [profile_cubit_test.dart](file:///f:/FlutterProjects/MoviesApp/test/features/auth/profile_cubit_test.dart)
  * Unit tests for `ProfileCubit` validating the explicit success contract (`updateProfile` returns `AppUser?` on success and `null` on failure) using `FakeProfileRepository`.
* [authentication_profile_integration_report.md](file:///f:/FlutterProjects/MoviesApp/docs/reports/authentication_profile_integration_report.md)
  * Comprehensive persistent integration and audit report.

### Files Modified:
* [auth_firebase_data_source.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/data/data_sources/auth_firebase_data_source.dart)
  * Added registration race protection using `_pendingRegistrationUids`. Synchronized `authStateChanges()` so intermediate Firebase Auth stream events during registration do not attempt to read or create a skeleton profile concurrently while `registerWithEmail` writes the real Firestore profile document.
* [auth_cubit.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/auth_cubit.dart)
  * Added `_isRegistering` guard in `startListening()` to suppress premature intermediate `AuthStatus.authenticated` emissions before registration and Firestore profile creation finish.
  * Added `updateUser(AppUser user)` to update the active session user in memory reactively.
* [profile_cubit.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/profile_cubit.dart)
  * Changed `updateProfile` return type from `Future<void>` to `Future<AppUser?>`, establishing an explicit, unambiguous success contract for callers (`null` on failure, non-null on success).
* [movies_primary_button.dart](file:///f:/FlutterProjects/MoviesApp/lib/shared/widgets/movies_primary_button.dart)
  * Added `text` constructor parameter alias for backwards compatibility with call sites using `text:` instead of `label:`.
  * Added `isLoading` property that renders a centered `CircularProgressIndicator` and automatically disables duplicate taps.
* [app_dependencies.dart](file:///f:/FlutterProjects/MoviesApp/lib/core/di/app_dependencies.dart)
  * Added `AuthCoordinator authCoordinator` property.
  * Kept `AppDependencies.create()` synchronous and safe.
  * Added injectable parameters (`authRepository`, `authCoordinator`) for domain fakes in tests without contacting Firebase.
* [app_router.dart](file:///f:/FlutterProjects/MoviesApp/lib/app/app_router.dart)
  * Connected `coordinator` as `refreshListenable`.
  * Implemented route guard `redirect` protecting `/home`, `/movie/:id`, and `/update-profile`.
  * Prevented redirect loops; redirected authenticated users away from unauthenticated entry routes (`/login`, `/register`).
  * Kept `/forgot-password` accessible to both unauthenticated and signed-in users (from `/update-profile`).
  * Passed `coordinator` down to destination screens.
* [splash_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/splash/presentation/screens/splash_screen.dart)
  * Connected `AuthCoordinator` to trigger `bootstrap()` asynchronously during the minimum 2-second splash screen display.
  * Guaranteed startup routing resolution: Onboarding if incomplete; Home if completed and authenticated; Login if completed and unauthenticated or configuration unavailable. Never allows premature Home navigation.
* [onboarding_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/onboarding/presentation/screens/onboarding_screen.dart)
  * Accepted `AuthCoordinator`.
  * Resolved destination upon onboarding completion from actual authentication state (`RouteConstants.home` if authenticated, `RouteConstants.login` otherwise) rather than hardcoding Login.
* [login_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/login_screen.dart)
  * Connected validated email/password submission to `AuthCubit.signInWithEmail`.
  * Connected Google Sign-In to `AuthCubit.signInWithGoogle`.
  * Handled Google user cancellation cleanly without showing an error.
  * Added pending/loading indicator to buttons and prevented duplicate submissions.
  * Added friendly error messaging via floating SnackBar.
  * Added non-intrusive `configurationUnavailable` notice banner when Firebase configuration is absent.
* [register_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/register_screen.dart)
  * Connected name, email, password, confirmPassword, phone, and selected avatar index to `AuthCubit.registerWithEmail`.
  * Mapped avatar index to genuine existing avatar IDs (`avatar_01`, `avatar_02`, `avatar_03`).
  * Verified password confirmation without sending confirmation password to backend.
  * Handled duplicate submissions and pending button state.
  * Added non-intrusive `configurationUnavailable` notice banner when Firebase configuration is absent.
* [forgot_password_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/forgot_password_screen.dart)
  * Connected validated email to `PasswordResetCubit.submit`.
  * Enforced neutral success wording: *"If an account exists with this email address, a password reset link has been sent."*
  * Kept screen accessible and pop-safe for signed-in users navigating from `/update-profile`.
* [profile_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/profile_screen.dart)
  * Connected real `AppUser` to header; replaced guest user presentation when signed in.
  * Added logout confirmation dialog and wired real sign-out.
  * Corrected unavailable library state: signed-in users are no longer told to sign in.
* [update_profile_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/update_profile_screen.dart)
  * Resolved current user from shared session state (`coordinator.currentUser`), falling back to route extra.
  * Enforced strict success contract: only displays success message and pops screen if `profileCubit.updateProfile` returns a non-null `AppUser`.
  * Published updated profile back to `coordinator.updateSharedUser`.
  * Disabled "Delete Account" button (`onPressed: null`) with explanatory notice regarding deferred library coordination, and removed deletion confirmation dialog.
  * Cleared stale text fields if authenticated UID changes or user signs out.
* [main_shell_screen.dart](file:///f:/FlutterProjects/MoviesApp/lib/features/main/presentation/screens/main_shell_screen.dart)
  * Wrapped `ProfileScreen` in `ListenableBuilder` observing `coordinator` so profile updates refresh immediately without application restart.
  * Wired `onEditProfile` and `onLogout`.

---

## 2. Real Configuration Found versus Missing

### Inspected Configuration Found:
* **Android Application ID & Namespace**:
  * Located in `android/app/build.gradle.kts`:
    * `namespace = "com.route.movies_app"`
    * `applicationId = "com.route.movies_app"`
* **Dependencies Declared in pubspec.yaml**:
  * `firebase_core: ^4.14.0`
  * `firebase_auth: ^6.6.1`
  * `cloud_firestore: ^6.9.0`
  * `google_sign_in: ^7.2.0`
* **Real Avatar Assets in Workspace**:
  * `assets/images/auth/avatar_01.png`
  * `assets/images/auth/avatar_02.png`
  * `assets/images/auth/avatar_03.png`

### Configuration Missing:
* **`android/app/google-services.json`**: Absent from the workspace.
* **Google Services Gradle Plugin**:
  * Root `android/build.gradle.kts` does not apply `com.google.gms.google-services`.
  * App `android/app/build.gradle.kts` does not apply plugin `id("com.google.gms.google-services")`.
* **`lib/firebase_options.dart`**: Absent from the workspace. Never imported or fabricated.
* **OAuth 2.0 Web Client ID / SHA-1 fingerprint**: Absent from Android build configuration for Google Sign-In.
* **Firestore Security Rules**: No `firestore.rules` file in the workspace.

---

## 3. Bootstrap, Dependency Ownership, Session Flow, and Route Protection

### Synchronous Composition & Asynchronous Bootstrap:
* `AppDependencies.create()` remains 100% synchronous. No unhandled futures are launched before `runApp`.
* `AuthCoordinator` is initialized synchronously with status `AuthBootstrapStatus.uninitialized`.
* When `SplashScreen` mounts, its owned startup resolution method triggers `coordinator.bootstrap()`.
* `bootstrap()` checks `Firebase.apps.isEmpty`. If initialization fails (e.g. because `google-services.json` is missing or platform channels are unavailable in tests), the exception is caught, setting `status = AuthBootstrapStatus.configurationUnavailable`.
* No dummy Firebase instances or fake authenticated sessions are created.

### Route Protection & Navigation Coordination:
* `GoRouter` uses `coordinator` as its single `refreshListenable`.
* The `redirect` handler enforces the following rules:
  1. **Splash & Onboarding**: Never intercepted by the redirect handler. They control their own transitions.
  2. **Unauthenticated-Only Routes (`/login`, `/register`)**: If `coordinator.isAuthenticated == true`, redirected to `/home`.
  3. **Forgot Password (`/forgot-password`)**: Permitted for both unauthenticated visitors and authenticated users navigating from `/update-profile`.
  4. **Protected Routes (`/home` and its tabs, `/movie/:id`, `/update-profile`)**: If `!coordinator.isAuthenticated`, redirected immediately to `/login`.
  5. **Sign-Out Security**: When `authCubit.signOut()` completes, `coordinator.notifyListeners()` triggers `redirect`. The user is immediately removed from `/home` to `/login`, and Back navigation cannot return to authenticated routes.
  6. **Zero Circular Redirects**: Every redirect either targets a static terminal route (`/home` or `/login`) or returns `null`.

---

## 4. Connected Actions and Behaviors

| Screen | Action | Trigger / Mechanism | Feedback & Outcome |
| :--- | :--- | :--- | :--- |
| **Login** | Email/Password Sign-In | `AuthCubit.signInWithEmail` | Validates email & password; disables button with spinner; displays friendly error SnackBar on failure; session resolution routes to Home on success. |
| **Login** | Google Sign-In | `AuthCubit.signInWithGoogle` | Uses `google_sign_in` 7.x `authenticate()`; cancellation does not show error; configuration failure shows friendly notice without disabling email login. |
| **Register** | Account Creation | `AuthCubit.registerWithEmail` | Validates all fields; suppresses intermediate auth stream event; rollbacks deletion on profile failure; routes to Home only upon verified Firestore profile completion. |
| **Forgot Password** | Reset Email Submission | `PasswordResetCubit.submit` | Validates email; disables button with spinner; shows neutral success wording on success; error SnackBar on failure. |
| **Profile** | Sign-Out | `AuthCubit.signOut` | Shows confirmation dialog; calls `signOut()`; router removes user to `/login` and guards history. |
| **Profile** | Edit Profile | `context.push('/update-profile')` | Opens Update Profile screen with current shared user. |
| **Update Profile** | Update Data | `ProfileCubit.updateProfile` | Validates inputs; awaits update; checks `updatedUser != null`; updates shared state; pops only on success; preserves session on failure. |
| **Update Profile** | Reset Password | `context.push('/forgot-password')` | Navigates to Forgot Password screen; back navigation pops safely back to Update Profile. |
| **Update Profile** | Delete Account | **Disabled** (`onPressed: null`) | Displays disabled styling with explicit notice that account deletion is deferred pending Watch List/History cleanup coordination. |

---

## 5. Registration/Session Race Protection

### Problem Identified:
When `FirebaseAuth.createUserWithEmailAndPassword` succeeds, Firebase Auth immediately emits a new user on `authStateChanges()`. If the app listens to this stream naively, `AuthCubit` emits `AuthStatus.authenticated`, and the router redirect navigates to `/home` *before* Firestore creates the user document (`users/{uid}`). If Firestore creation then fails, the user is deleted via `_bestEffortDeleteAuthUser`, creating a broken session and an unintended screen transition.

### Solution Implemented:
1. **`AuthCubit` Guard**: Added an `_isRegistering` boolean flag in `AuthCubit`. While active, `_observeAuthState().listen` ignores incoming user stream events. Only `registerWithEmail()` itself emits the final `AuthStatus.authenticated` state upon confirmed completion of both Auth user and Firestore document creation.
2. **`AuthFirebaseDataSource` Synchronization**: Added `_pendingRegistrationUids`. In `authStateChanges().asyncMap`, if a UID is currently in `_pendingRegistrationUids`, the mapping routine waits for registration to finish before attempting to load the profile, preventing race conditions or skeleton profile creation.
3. **Rollback Safety**: If Firestore document creation fails, `_bestEffortDeleteAuthUser` deletes the Auth user, `_isRegistering` is reset to false, and `AuthStatus.failure` is emitted with the exact error message, keeping the user securely on the registration screen.

---

## 6. Profile Update Success Contract and Shared-User Refresh

### Success Contract:
* Previously, Cubit methods catching errors returned `Future<void>` normally, causing callers awaiting the future to erroneously assume success even when the operation failed.
* `ProfileCubit.updateProfile` was updated to return `Future<AppUser?>`:
  * Returns the updated `AppUser` upon successful Firestore update.
  * Returns `null` and emits `ProfileStatus.failure` with `errorMessage` if an exception occurs.
* In `UpdateProfileScreen`:
  * The method inspects `if (updatedUser != null)`.
  * The success message and `Navigator.of(context).pop()` are **only** executed when `updatedUser != null`.
  * If `null`, an error SnackBar is displayed, and the screen remains open with user edits intact.
  * The user's authentication session is never lost due to a profile update failure.

### Shared User Refresh:
* Upon update success, `coordinator.updateSharedUser(updatedUser)` publishes the new entity to `AuthCubit.updateUser(updatedUser)` and notifies all coordinator listeners.
* In `MainShellScreen`, `ProfileScreen` is wrapped in a `ListenableBuilder` tied to `coordinator`. The header updates immediately with the new name, phone number, and avatar without restarting the app.

---

## 7. Missing-Handler Button Corrections

* **Delete Account Button**:
  * The button was previously clickable and opened a deletion confirmation dialog that had no operational backend handler.
  * It is now completely disabled (`onPressed: null`) with faded styling.
  * A clear informational notice is rendered beneath the button: *"Account deletion is currently unavailable pending Watch List and History cleanup coordination."*
  * No dialog or empty callback is triggered.
* **Watch List & History Unavailable Messages**:
  * When `watchlistMovies` or `historyMovies` is `null`:
    * If the user is signed in: displays *"Watch list sync is currently unavailable and will be integrated in an upcoming phase."*
    * If the user is a guest / unauthenticated: displays *"Sign in to sync and view your saved watch list."*
    * Signed-in users are no longer told to sign in again for deferred features.

---

## 8. Explicitly Deferred Features

1. **Account Deletion**:
   * Deletion requires cascading cleanup of Firestore collections (such as Watch List items and viewing history) to avoid orphaned user documents. Deletion is intentionally deferred until library integration.
2. **Watch List & History Synchronization**:
   * Remote library data sources and Firestore collection listeners remain deferred.
   * Counts continue to display `'-'` to denote unintegrated data rather than misleading `'0'` values.
3. **Password Change from within the App**:
   * Uses standard Firebase Password Reset email flow. In-app reauthentication and password change are deferred.
4. **Trailer Playback & Localization**:
   * Deferred to subsequent phases.

---

## 9. Source-Only Test Changes and Unverified Assumptions

* **Unit Tests Added**:
  * `test/features/auth/auth_cubit_test.dart`
  * `test/features/auth/profile_cubit_test.dart`
* **Smoke Test Compatibility**:
  * Verified `test/app_smoke_test.dart`. `AppDependencies.create()` remains synchronous and injectable.
* **Unverified Assumptions (Due to Strict Code-Only Mode)**:
  * No `flutter test`, `flutter analyze`, or build commands were executed.
  * All contracts were verified via static source inspection and architectural alignment.

---

## 10. MANUAL ACTION REQUIRED

The user must perform the following external setup in Firebase Console and Android Studio:

1. **Firebase Android Project Registration**:
   * Open the Firebase Console and register an Android app with Package Name / Application ID:
     `com.route.movies_app`
2. **Add `google-services.json`**:
   * Download `google-services.json` from Firebase Console.
   * Place it in `android/app/google-services.json`.
3. **Apply Google Services Gradle Plugin**:
   * In `android/build.gradle.kts`, ensure the Google Services classpath is added:
     ```kotlin
     buildscript {
         dependencies {
             classpath("com.google.gms:google-services:4.4.2")
         }
     }
     ```
   * In `android/app/build.gradle.kts`, apply the plugin in the `plugins` block:
     ```kotlin
     plugins {
         id("com.android.application")
         id("kotlin-android")
         id("dev.flutter.flutter-gradle-plugin")
         id("com.google.gms.google-services")
     }
     ```
4. **Enable Firebase Authentication Providers**:
   * In Firebase Console -> Authentication -> Sign-in method:
     * Enable **Email/Password**.
     * Enable **Google**.
5. **Google Sign-In SHA-1 Fingerprint**:
   * Generate your debug signing SHA-1 fingerprint (e.g., via `keytool -list -v -keystore ~/.android/debug.keystore`).
   * Add the SHA-1 fingerprint to the Android app settings in Firebase Console.
   * Re-download `google-services.json` if needed.
6. **Firestore Security Rules**:
   * Deploy owner-only security rules for the `users` collection in Firebase Console:
     ```javascript
     rules_version = '2';
     service cloud.firestore {
       match /databases/{database}/documents {
         match /users/{uid} {
           allow read, write: if request.auth != null && request.auth.uid == uid;
         }
       }
     }
     ```

---

## 11. MANUAL VALIDATION REQUIRED

The user can validate the integration in Android Studio using the following checklist:

1. **Static Validation**:
   * Run `flutter analyze` in Android Studio terminal to verify compile-time cleanliness.
   * Run `flutter test` to verify unit and smoke tests.
2. **Missing Configuration Validation**:
   * Run the app without `google-services.json`.
   * Verify the app opens on Splash, proceeds to Onboarding or Login, and displays the non-intrusive configuration-unavailable banner without crashing or showing an endless spinner.
3. **Registration Flow**:
   * Add `google-services.json` and enable Email/Password in Firebase.
   * Complete onboarding and tap "Create One" on Login.
   * Register a new account with a selected avatar.
   * Verify Firestore creates `users/{uid}` with `name`, `email`, `phoneNumber`, and `avatarId`.
   * Verify navigation takes you to Home without intermediate flickers.
4. **Profile & Edit Flow**:
   * Tap the Profile tab; verify the avatar, name, and email reflect the registered user.
   * Tap "Edit Profile".
   * Change name, phone number, and avatar. Tap "Update Data".
   * Verify success toast appears, screen pops, and the Profile tab immediately reflects the updated data.
5. **Sign-Out & Protection**:
   * On the Profile tab, tap "Logout".
   * Confirm the logout dialog.
   * Verify navigation redirects to Login and pressing Back does not return to Home or Profile.
6. **Forgot Password**:
   * On Login, tap "Forget Password ?".
   * Enter an email and tap "Verify Email".
   * Verify the neutral success message appears.

---

## 12. Confirmation of Strict Code-Only Execution

* **No terminal was opened or used.**
* **No command, script, task, or background process was executed.**
* **No Flutter, Dart, Git, Gradle, ADB, or test command ran.**
* **No emulator, simulator, or browser automation was launched.**
* **No external network or Firebase request was initiated.**
