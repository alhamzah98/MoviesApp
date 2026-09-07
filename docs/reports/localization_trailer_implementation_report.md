# Localization & Movie-Trailer Launching Implementation Report

**MoviesApp Phase**: Arabic/English Localization & Movie-Trailer Launching  
**Execution Policy**: Strict Code-Only Mode (No terminal, no commands, no package resolution, no tests, no emulators)  
**Date**: September 7, 2026  

---

## 1. Executive Summary & Provider Clarification

### Actual Movies API Provider Found in Source
- Earlier upload notes mentioned TMDb, while previous architecture reports identified YTS.
- **Source Inspection Finding**: As verified in [`lib/core/network/api_constants.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/network/api_constants.dart#L4) (`baseUrl = 'https://yts.mx/api/v2/'`) and [`lib/features/movies/data/data_sources/movies_remote_data_source_impl.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movies/data/data_sources/movies_remote_data_source_impl.dart), the project connects strictly to the **YTS (Yify)** API.
- **Scope Integrity**: No endpoints were changed, no provider migration was attempted, and no API credentials/keys were added.

### Key Milestones Achieved
1. **Centralized Direct-Source Localization**: Built pure Dart/Flutter localization classes ([`AppLocalizations`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/app_localizations.dart) and [`_AppLocalizationsDelegate`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/app_localizations.dart#L391)) supporting English (`en`) and Arabic (`ar`) without code generation or external JSON asset dependencies.
2. **State-Preserving Locale Architecture**: [`LocaleCubit`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/locale_cubit.dart) manages the active locale at the application root. Language changes rebuild MaterialApp directionality and text while keeping the router instance, navigator history, auth state, current tabs, form inputs, and loaded movies intact.
3. **Locale Persistence**: Asynchronously persisted using the lazy [`AppPreferences`](file:///f:/FlutterProjects/MoviesApp/lib/core/storage/app_preferences.dart) abstraction under the dedicated key `app_language`, without blocking startup or mutating `onboarding_completed`.
4. **Interactive Language Controls**:
   - Replaced static auth flag image with an accessible, compact toggle button ([`AuthLanguageSwitch`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/widgets/auth_language_switch.dart)) on Login and Register.
   - Added an unobtrusive language selector ([`_ProfileLanguageSelector`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/profile_screen.dart#L1068)) in the Profile screen for signed-in users.
5. **Secure YouTube Movie Trailer Launching**:
   - Implemented [`TrailerLauncher`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/services/trailer_launcher.dart) validating video IDs against strict alphanumeric patterns (`^[a-zA-Z0-9_-]+$`) and constructing secure HTTPS URIs (`Uri.https('www.youtube.com', '/watch', {'v': code})`).
   - Wired both the central hero play button and the primary red Watch button on Movie Details to a shared handler with disabled states during launch or missing IDs.
   - External application launching via `url_launcher` (`LaunchMode.externalApplication`) without triggering viewing history records or arbitrary URL injection.

---

## 2. Exact Files Created and Modified

### Newly Created Files
1. [`lib/core/localization/app_localizations.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/app_localizations.dart): Central translation class with typed getters for English/Arabic, genre translation (`translateGenre`), and error mapping (`translateError`). Includes built-in `_AppLocalizationsDelegate`.
2. [`lib/core/localization/locale_cubit.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/localization/locale_cubit.dart): State owner for active locale, startup asynchronous preference loading, error handling, and language toggling.
3. [`lib/features/movie_details/services/trailer_launcher.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/services/trailer_launcher.dart): Service for sanitizing YouTube trailer codes, constructing URIs, and executing external app launch with an injectable `UrlLauncherCallback`.
4. [`test/core/localization/app_localizations_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/core/localization/app_localizations_test.dart): Unit test verifying complete parity between English and Arabic keys, genre translation, and error mapping.
5. [`test/core/storage/locale_preferences_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/core/storage/locale_preferences_test.dart): Unit test verifying `app_language` persistence, non-blocking defaults, and non-interference with `onboarding_completed`.
6. [`test/features/movie_details/trailer_launcher_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/movie_details/trailer_launcher_test.dart): Unit test verifying YouTube URI construction, character validation, whitespace trimming, and fake launcher execution.
7. [`test/features/localization/locale_cubit_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/localization/locale_cubit_test.dart): Unit test verifying startup loading, locale switching, and state preservation.

### Modified Files
1. [`pubspec.yaml`](file:///f:/FlutterProjects/MoviesApp/pubspec.yaml):
   - Added `flutter_localizations: sdk: flutter` under dependencies.
   - Added `url_launcher: ^6.3.2` under dependencies.
   - Lockfile was NOT manually modified.
2. [`lib/core/storage/app_preferences.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/storage/app_preferences.dart):
   - Added `_appLanguageKey = 'app_language'`.
   - Added `getAppLanguage()` and `setAppLanguage()` with concurrent save protection.
3. [`lib/core/di/app_dependencies.dart`](file:///f:/FlutterProjects/MoviesApp/lib/core/di/app_dependencies.dart):
   - Initialized and exposed `LocaleCubit`.
   - Cleanly closed `localeCubit` in `dispose()`.
4. [`lib/app/app.dart`](file:///f:/FlutterProjects/MoviesApp/lib/app/app.dart):
   - Connected `LocaleCubit` to `MaterialApp.router` via `BlocBuilder`.
   - Registered `AppLocalizations.delegate` alongside `GlobalMaterialLocalizations.delegate`, `GlobalWidgetsLocalizations.delegate`, and `GlobalCupertinoLocalizations.delegate`.
   - Defined `supportedLocales = AppLocalizations.supportedLocales`.
5. [`lib/features/auth/presentation/widgets/auth_language_switch.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/widgets/auth_language_switch.dart):
   - Replaced static PNG image with an interactive, accessible, segmented EN/AR toggle.
6. [`lib/features/auth/presentation/widgets/auth_text_field.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/widgets/auth_text_field.dart):
   - Added optional `textDirection` parameter to ensure email and phone entries maintain LTR formatting in RTL mode.
7. [`lib/features/auth/presentation/widgets/auth_password_field.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/widgets/auth_password_field.dart):
   - Added optional `textDirection` parameter.
8. [`lib/features/auth/presentation/widgets/auth_app_bar.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/widgets/auth_app_bar.dart):
   - Directional alignment (`AlignmentDirectional.centerStart`) and RTL-aware back icon.
9. [`lib/features/auth/presentation/cubit/auth_state.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/auth_state.dart):
   - Added optional `errorCode` and `clearErrorCode` for backward-compatible localized error mapping.
10. [`lib/features/auth/presentation/cubit/auth_cubit.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/auth_cubit.dart):
    - Propagated error codes from `AppException` into `AuthState`.
11. [`lib/features/auth/presentation/cubit/password_reset_state.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/password_reset_state.dart):
    - Added optional `errorCode` and `clearErrorCode`.
12. [`lib/features/auth/presentation/cubit/password_reset_cubit.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/cubit/password_reset_cubit.dart):
    - Propagated error codes on password reset failures.
13. [`lib/features/auth/presentation/screens/login_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/login_screen.dart):
    - Full localization of copy, hints, labels, errors, and LTR input styling.
14. [`lib/features/auth/presentation/screens/register_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/register_screen.dart):
    - Full localization of inputs, labels, validation messages, and errors.
15. [`lib/features/auth/presentation/screens/forgot_password_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/auth/presentation/screens/forgot_password_screen.dart):
    - Full localization of instructions, inputs, button label, and feedback.
16. [`lib/features/onboarding/presentation/models/onboarding_page_data.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/onboarding/presentation/models/onboarding_page_data.dart):
    - Added `localizedPages(AppLocalizations l10n)` to supply translated titles, descriptions, and button labels.
17. [`lib/features/onboarding/presentation/screens/onboarding_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/onboarding/presentation/screens/onboarding_screen.dart):
    - Integrated localized pages and save error handling.
18. [`lib/features/onboarding/presentation/widgets/onboarding_content_panel.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/onboarding/presentation/widgets/onboarding_content_panel.dart):
    - Localized "Back" button copy.
19. [`lib/features/main/presentation/widgets/movies_bottom_navigation_bar.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/main/presentation/widgets/movies_bottom_navigation_bar.dart):
    - Added localized tooltips and preserved logical tab indexing.
20. [`lib/features/home/presentation/screens/home_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/home/presentation/screens/home_screen.dart):
    - Localized headings ("Available Now", "Watch Now", genre titles, empty states, and "Try again").
21. [`lib/features/home/presentation/widgets/home_section_header.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/home/presentation/widgets/home_section_header.dart):
    - Mirrored section arrow icon in RTL.
22. [`lib/features/home/presentation/widgets/home_section_error.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/home/presentation/widgets/home_section_error.dart):
    - Localized "Retry" action button.
23. [`lib/features/search/presentation/screens/search_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/search/presentation/screens/search_screen.dart):
    - Localized search input hint, clear tooltip, initial view copy, dynamic empty state, and retry button.
24. [`lib/features/browse/presentation/screens/browse_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/browse/presentation/screens/browse_screen.dart):
    - Localized genre chip labels using `translateGenre()` while retaining canonical English query keys; localized empty and error views.
25. [`lib/features/movie_details/presentation/screens/movie_details_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/screens/movie_details_screen.dart):
    - Connected shared trailer launcher handler without triggering viewing history; localized bookmark feedback, error views, and tooltips.
26. [`lib/features/movie_details/presentation/widgets/watch_button.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/watch_button.dart):
    - Labeled "Watch Trailer" / "مشاهدة الإعلان", disabled state handling for missing IDs / pending launch.
27. [`lib/features/movie_details/presentation/widgets/hero_header.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/hero_header.dart):
    - Interactive central play control with loading indicator and tooltip; RTL-aware back button.
28. [`lib/features/movie_details/presentation/widgets/summary_section.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/summary_section.dart):
    - Localized "Summary" heading.
29. [`lib/features/movie_details/presentation/widgets/genres_section.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/genres_section.dart):
    - Localized "Genres" heading and translated chip labels.
30. [`lib/features/movie_details/presentation/widgets/cast_section.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/cast_section.dart):
    - Localized "Cast" heading and missing actor fallback.
31. [`lib/features/movie_details/presentation/widgets/screenshots_section.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/screenshots_section.dart):
    - Localized "Screenshots" heading.
32. [`lib/features/movie_details/presentation/widgets/similar_movies_section.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/similar_movies_section.dart):
    - Localized "Similar Movies" heading.
33. [`lib/features/movie_details/presentation/widgets/statistics_row.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/movie_details/presentation/widgets/statistics_row.dart):
    - Localized rating and year tooltips.
34. [`lib/features/profile/presentation/screens/profile_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/profile_screen.dart):
    - Localized stats, tabs (Watch List, History), logout dialog, account deletion prompt, and added `_ProfileLanguageSelector`.
35. [`lib/features/profile/presentation/screens/update_profile_screen.dart`](file:///f:/FlutterProjects/MoviesApp/lib/features/profile/presentation/screens/update_profile_screen.dart):
    - Localized update form, avatar picker sheet, feedback banners, and button labels.

---

## 3. Localization Architecture & State Preservation

### Localization Structure
- **Domain Independence**: Localization lives exclusively within `lib/core/localization/` and the presentation layer. Domain entities (`Movie`, `AppUser`, `LibraryMovie`) and repositories do not import Flutter UI libraries.
- **Supported Locales**: `en` (English, default) and `ar` (Arabic).
- **Genre Handling**: Movie genres in API responses and query parameters remain canonical English strings (e.g. `'Action'`, `'Comedy'`). The presentation layer uses `l10n.translateGenre(genre)` for chip display and headers.
- **Untranslated Content Preserved**: Movie titles, descriptions/summaries from YTS, actor names, character names, and user email addresses are preserved as returned or entered and are not machine-translated.

### State Preservation Across Language Changes
When the user changes language (either via the auth screen switch or the profile selector):
- The `MaterialApp.router` listens to `LocaleCubit` without re-instantiating `GoRouter`.
- The active route and navigation stack are preserved.
- Active authentication subscriptions (`AuthCoordinator`) and library session streams remain uninterrupted.
- The active tab in the main navigation and the active tab in Profile (Watch List vs. History) remain on their current indices.
- Current page index on Onboarding is maintained.
- Form inputs in login, registration, and update profile controllers remain intact.
- Loaded movies in Home, Search, Browse, and Movie Details are not discarded or refetched.

### RTL / LTR Directionality
- Material and Cupertino delegates handle directional layouts and text alignments automatically.
- Inputs for email addresses, passwords, and phone numbers are explicitly assigned `textDirection: TextDirection.ltr` so characters, domains, and plus-prefixed digits remain readable while keeping hint and field alignment natural.
- Arrow icons for back actions and "See More" navigation use `Directionality.of(context)` checks to mirror appropriately.
- Movie poster images, cover art, and actor photos are NOT mirrored.

---

## 4. Movie-Trailer Launching Architecture

### Security and URI Construction
- **Validation**: Accepts only non-empty, trimmed video IDs matching `^[a-zA-Z0-9_-]+$`.
- **Fixed-Host Construction**: Uses `Uri.https('www.youtube.com', '/watch', {'v': videoId})`.
- **Injection Prevention**: Arbitrary external URLs, URL schemes, or parameter injections supplied by API fields or malicious inputs are rejected, returning `false` without launching.
- **Non-blocking Execution**: Uses `url_launcher` with `LaunchMode.externalApplication`. Does not gate solely on `canLaunchUrl`.
- **Error Handling**: Missing IDs, failed launches, or platform exceptions display user-friendly localized messages without crashing.
- **History Dispatch Policy**: Launching the trailer opens external content and explicitly does NOT dispatch a viewing-history entry to Firestore.
- **Controls**:
  - Central Hero Play Button: displays loading indicator when launching, disabled if `youtubeTrailerCode` is missing or invalid.
  - Primary Red Watch Button: labeled "Watch Trailer" / "مشاهدة الإعلان", disabled when invalid or pending launch.

---

## 5. Dependency Management

### Modifications in `pubspec.yaml`
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  url_launcher: ^6.3.2
```
- **Lockfile Integrity**: `pubspec.lock` was untouched. No automated package resolution was executed.

> [!IMPORTANT]
> **MANUAL ACTION REQUIRED**:  
> Because the development environment operates under a strict code-only policy, you must run package resolution in your terminal or Android Studio before running the application:
> ```bash
> flutter pub get
> ```

---

## 6. Verification and Tests Written (Source-Only)

Four comprehensive test suites were written and placed in the project without executing them:
1. [`test/core/localization/app_localizations_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/core/localization/app_localizations_test.dart):
   - Validates that every getter returns non-empty strings in both English and Arabic.
   - Verifies `translateGenre()` for known and unknown genres.
   - Verifies `translateError()` maps known auth and validation codes.
2. [`test/core/storage/locale_preferences_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/core/storage/locale_preferences_test.dart):
   - Verifies missing `app_language` returns null safely.
   - Verifies valid language code persistence.
   - Verifies that `onboarding_completed` is not mutated by language changes.
3. [`test/features/movie_details/trailer_launcher_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/movie_details/trailer_launcher_test.dart):
   - Verifies valid YouTube URI generation with parameter `v`.
   - Verifies whitespace trimming and rejection of malformed or malicious inputs.
   - Tests success, failure, and exception handling using an injected fake `UrlLauncherCallback`.
4. [`test/features/localization/locale_cubit_test.dart`](file:///f:/FlutterProjects/MoviesApp/test/features/localization/locale_cubit_test.dart):
   - Tests default English locale, startup persistence loading, and locale toggling.

---

## 7. Manual Validation Checklist for User

After running `flutter pub get`, execute the following manual tests:

- [ ] **Language Switching on Auth**:
  - Open the Login or Register screen.
  - Tap the EN/AR toggle button at the bottom.
  - Confirm the layout switches immediately between LTR and RTL.
  - Confirm email and password fields keep their entered text and readable LTR orientation.
- [ ] **Language Switching in Profile**:
  - Sign in or navigate to the Profile screen.
  - Locate the Language section in the profile action list.
  - Tap "English" or "العربية". Confirm the language changes without resetting the current tab or signing out.
- [ ] **Persistence Across Restarts**:
  - Switch the language to Arabic.
  - Restart the application.
  - Verify that the app launches in Arabic.
- [ ] **Trailer Launching**:
  - Navigate to a movie with a valid trailer code (e.g. from Home or Search).
  - Tap the central play button in the hero header. Confirm the external YouTube player or browser opens the video.
  - Return to the app and tap the red "Watch Trailer" / "مشاهدة الإعلان" button. Confirm it triggers the same action.
  - Check the History tab in Profile to confirm that watching a trailer did NOT register a new viewing history record.
- [ ] **Missing Trailer Handling**:
  - Open a movie without a trailer code.
  - Verify that both trailer controls are disabled with appropriate tooltips.

---

## 8. Remaining Items & Preserved Scope
- **Account Deletion**: Remains visibly disabled and indicates "Under Development" via dialog until its dedicated phase.
- **Firebase Configuration**: Untouched; awaits user's local `google-services.json` setup for real cloud testing.
- **Strict Policy Confirmation**: No commands, builds, pub gets, tests, or Git commits were executed.
