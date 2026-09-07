# Profile and Update Profile UI Implementation Report

## 1. Exact Files Created and Modified

### Exact Files Created:
* `lib/features/profile/presentation/constants/avatar_constants.dart`
* `docs/reports/profile_update_profile_implementation_report.md`

### Exact Files Modified:
* `lib/features/profile/presentation/screens/profile_screen.dart`
* `lib/features/profile/presentation/screens/update_profile_screen.dart`
* `lib/features/movies/presentation/cubit/movie_details_cubit.dart`
* `lib/features/movie_details/presentation/screens/movie_details_screen.dart`
* `lib/app/app_router.dart`

---

## 2. Movie Details Safety Findings and Corrections

### Findings:
1. **Screen State Reuse on Route ID Change**:
   In `MovieDetailsScreen`, state initialization occurred solely in `initState()`. If Flutter reused the existing `State` instance when navigating between movies (such as via suggestions or route parameters), the new movie ID would not trigger a new load.
2. **Missing Async Request Versioning**:
   `MovieDetailsCubit` did not have request generation/token versioning on `load(movieId)` or `retrySuggestions(movieId)`. If multiple requests were initiated concurrently or in quick succession, an earlier, slower HTTP response could overwrite the state of a newer movie.
3. **Suggestion Retry Movie Target**:
   `retrySuggestions` did not explicitly verify that it targeted the currently loaded movie entity (`state.movie?.id`).

### Corrections Applied:
* Added `key: ValueKey('movie_details_${movieId ?? -1}')` to `MovieDetailsScreen` in `app_router.dart`.
* Added `didUpdateWidget` in `_MovieDetailsScreenState` to dispose the active cubit and initialize a fresh cubit/load whenever `oldWidget.movieId != widget.movieId`.
* Added an incrementing `_activeLoadRequestId` to `MovieDetailsCubit`. Every async return in `load()` and `retrySuggestions()` verifies `if (isClosed || requestId != _activeLoadRequestId) return;`.
* Updated `retrySuggestions` to target `state.movie?.id ?? movieId` and ensure existing movie details are preserved during suggestion reloading.

---

## 3. Profile and Update Profile Components and Behavior

### Profile Screen (`profile_screen.dart`):
* **Header**: Displays user avatar (`ProfileAvatars.assetPathFor(user?.avatarId)`), user display name (defaults to `"Guest User"` if no session is provided), and email.
* **Header Actions**:
  * **Edit Profile**: Gold button that invokes `onEditProfile` callback or navigates to `RouteConstants.updateProfile` with `user` as route extra.
  * **Logout**: Visually distinct button with red outline and logout icon. When tapped without a provided handler, displays a floating SnackBar: `"Authentication integration will be enabled in the upcoming phase."`.
* **Statistics Summary**: Two stat cards showing Watch List and History counts.
  * If a list is `null` (not connected/not provided), displays `'-'`.
  * If a list is provided, displays the exact integer count (`list.length`).
* **Local Tabs**: Toggle between `"Watch List"` and `"History"`. Active tab highlighted in gold (`#F6BD00`) with dark text; inactive tab in dark input fill (`#282A28`).
* **Content View**:
  * **Loading**: Centered gold progress indicator.
  * **Error**: Clean error view.
  * **Unavailable State**: Displayed when list data is `null` (`"Watch List Unavailable"` / `"History Unavailable"`), prompting the user to sign in to sync.
  * **Genuinely Empty State**: Displayed only when the list is non-null and empty (`"Your Watch List is Empty"` / `"No History Recorded"`).
  * **Movie Grid**: Two-column grid using `HomeMovieCard` with `childAspectRatio: 0.68`. Tapping a movie navigates to Movie Details via `RouteConstants.movieDetailsPath(movieId)`.
  * **Bottom Reserve**: Bottom padding accounts for the floating bottom navigation bar (`61 + 18 + MediaQuery.paddingOf(context).bottom`).

### Update Profile Screen (`update_profile_screen.dart`):
* **App Bar**: Centered title `"Update Profile"`, back navigation button using `Navigator.of(context).canPop() ? Navigator.of(context).pop() : context.go(RouteConstants.home)`.
* **Unavailable State**: If `user == null`, displays a `"Profile Unavailable"` screen with a `"Sign In"` action directing to `RouteConstants.login`. Account mutations are completely disabled.
* **Avatar Picker**:
  * Displays circular avatar with an edit badge.
  * Tapping avatar or `"Change Avatar"` text opens a modal bottom sheet displaying the 3 genuine existing avatars (`avatar_01`, `avatar_02`, `avatar_03`).
  * Selected avatar shows a gold highlight ring.
* **Editable Fields**:
  * Name field with person icon (`AuthTextField`).
  * Phone Number field with phone icon (`AuthTextField`, `TextInputType.phone`).
  * Pre-populated with `user.name` and `user.phoneNumber`.
  * Preserves unsaved edits across widget rebuilds; controllers disposed in `dispose()`.
* **Reset Password Action**:
  * Direct action link with key icon navigating to `RouteConstants.forgotPassword`.
* **Update Data Button**:
  * Validates name using `AuthValidators.validateName`.
  * Validates phone number using `AuthValidators.validatePhoneNumber`.
  * Validates avatar ID using `AuthValidators.validateAvatarId`.
  * If validation fails, displays `AppException.message` via floating SnackBar.
  * If no `onUpdateProfile` callback is provided, displays an informative SnackBar: `"Profile update integration will be enabled in the upcoming phase."`.
  * If `onUpdateProfile` is provided, awaits update execution, displays success, and pops back.
* **Delete Account Action**:
  * Danger-styled outlined button with trash icon.
  * Displays a confirmation dialog (`"Delete Account"`, `"Are you sure you want to delete your account? This action cannot be undone."`).
  * If confirmed without a backend handler, displays an informative SnackBar: `"Account deletion integration will be enabled in the upcoming phase."`. Never pretends an account was deleted.

---

## 4. Data Inputs, Callbacks, and Exact Navigation Changes

### ProfileScreen Inputs & Callbacks:
```dart
const ProfileScreen({
  this.user,
  this.watchlistMovies,
  this.historyMovies,
  this.isLoading = false,
  this.errorMessage,
  this.onEditProfile,
  this.onLogout,
  super.key,
});
```
* Compatible with `MainShellScreen`'s `const ProfileScreen()`.
* Does not instantiate Firebase, Auth, or Library Cubits in presentation during this UI phase.

### UpdateProfileScreen Inputs & Callbacks:
```dart
const UpdateProfileScreen({
  this.user,
  this.onUpdateProfile,
  this.onDeleteAccount,
  super.key,
});
```

### Route Updates:
* In `lib/app/app_router.dart`:
  * `RouteConstants.updateProfile`:
    ```dart
    GoRoute(
      path: RouteConstants.updateProfile,
      builder: (_, state) {
        final user = state.extra is AppUser ? state.extra as AppUser : null;
        return UpdateProfileScreen(user: user);
      },
    ),
    ```
  * `RouteConstants.movieDetails`: Added `key: ValueKey('movie_details_${movieId ?? -1}')`.

---

## 5. Avatar Assets and ID Mapping Used

Only the three real existing assets in `assets/images/auth/` are used:
* `'avatar_01'` -> `'assets/images/auth/avatar_01.png'`
* `'avatar_02'` -> `'assets/images/auth/avatar_02.png'`
* `'avatar_03'` -> `'assets/images/auth/avatar_03.png'`
* Default fallback: `'avatar_01'`.
* No nonexistent assets (`avatar_04` through `avatar_09`) were referenced or created.
* Centralized in `ProfileAvatars` (`lib/features/profile/presentation/constants/avatar_constants.dart`).

---

## 6. Validation, Controller Disposal, and Async Safety

* **Validation**: Reuses `AuthValidators.validateName`, `AuthValidators.validatePhoneNumber`, `AuthValidators.validateAvatarId`, `AuthValidators.normalizeName`, and `AuthValidators.normalizePhone`.
* **Controllers**:
  * `_nameController` and `_phoneController` in `_UpdateProfileScreenState` initialized in `initState()` and disposed in `dispose()`.
* **Async Safety**:
  * `_isSubmitting` flag in `UpdateProfileScreen` prevents concurrent duplicate submissions.
  * `mounted` guards protect all context and state updates following asynchronous operations.

---

## 7. Implemented Interactions vs. Intentionally Unavailable Backend Actions

* **Implemented Interactions**:
  * Full UI rendering, theme matching, and responsive layout.
  * Local tab switching between Watch List and History.
  * Navigation to Update Profile and back navigation.
  * Navigation to Forgot Password from Update Profile.
  * Avatar selection bottom sheet with active avatar selection.
  * Text validation with `AppException` error feedback.
  * Delete Account confirmation dialog.
  * Movie poster navigation to Movie Details.
* **Intentionally Unavailable Backend Actions**:
  * Backend profile mutation (shows SnackBar indicating upcoming integration).
  * Backend account deletion (shows SnackBar indicating upcoming integration).
  * Backend session logout (shows SnackBar indicating upcoming integration; does not navigate away to pretend logout occurred while leaving the session active).

---

## 8. Visual Approximations and Unresolved Issues

* **Visual Approximations**: Colors and tokens use established constants (`#121312` background, `#F6BD00` primary, `#282A28` input fill, `#CF6679` error). Spacing conforms to the 430x932 reference frame.
* **Unresolved Issues**: None. Strict code-only mode maintained without executing commands.

---

## 9. Manual Android Studio Validation Checklist

```text
MANUAL VALIDATION REQUIRED
```

Please perform the following verification steps in Android Studio:

### Profile Tab Checks
1. Select the **Profile** tab (index 3) from the bottom navigation bar.
2. Verify the profile header renders with the default avatar, `"Guest User"` or signed-in name, and email.
3. Verify that Watch List and History stat cards display `'-'` when no data is connected.
4. Verify tapping the **Watch List** and **History** tabs toggles the active gold highlight.
5. Verify an honest unavailable view appears when no list data is supplied.
6. Verify tapping **Logout** displays the explanatory SnackBar and does not simulate an invalid session logout.
7. Verify tapping **Edit Profile** navigates to the Update Profile screen.

### Update Profile Screen Checks
8. Verify the **Update Profile** screen opens with an app bar and back button.
9. When opened without a user session, verify it displays the `"Profile Unavailable"` state with a working `"Sign In"` button.
10. When opened with a user session, verify fields pre-populate with the user's name and phone number.
11. Tap the avatar or `"Change Avatar"`:
    - Verify a bottom sheet opens displaying the 3 avatars.
    - Verify tapping an avatar selects it, updates the screen avatar, and dismisses the bottom sheet.
12. Tap **Reset Password**:
    - Verify it opens the Forgot Password screen.
13. Leave the Name field blank and tap **Update Data**:
    - Verify an error SnackBar appears (`"Please enter your name."`).
14. Enter valid details and tap **Update Data**:
    - Verify the informative integration SnackBar appears without claiming premature success.
15. Tap **Delete Account**:
    - Verify the confirmation dialog appears with `"Cancel"` and `"Delete"` options.
    - Tap `"Delete"` and verify the integration SnackBar appears without pretending deletion occurred.
16. Tap the back button:
    - Verify it returns safely to the previous screen.

### Movie Details Lifecycle Check
17. Open a movie, then tap a similar movie:
    - Verify the screen immediately loads and updates to display the new movie details and suggestions.

---

## 10. Required Confirmations

* [x] **Confirmation**: No terminal was opened.
* [x] **Confirmation**: No command was executed.
* [x] **Confirmation**: No Flutter or Dart command ran (`flutter pub get`, `flutter analyze`, `flutter test`, `dart format`, etc.).
* [x] **Confirmation**: No test ran.
* [x] **Confirmation**: No build ran.
* [x] **Confirmation**: No application ran.
* [x] **Confirmation**: No emulator was created or launched.
* [x] **Confirmation**: No network request was made.
* [x] **Confirmation**: No package was installed.
* [x] **Confirmation**: No Git operation was performed.
