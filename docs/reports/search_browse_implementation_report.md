# Search and Browse Implementation Report

## 1. Exact Files Inspected

* `pubspec.yaml`
* `lib/app/app.dart`
* `lib/app/app_router.dart`
* `lib/core/constants/api_constants.dart`
* `lib/core/constants/route_constants.dart`
* `lib/core/di/app_dependencies.dart`
* `lib/core/errors/app_exception.dart`
* `lib/core/theme/app_colors.dart`
* `lib/core/theme/app_theme.dart`
* `lib/features/browse/presentation/screens/browse_screen.dart`
* `lib/features/home/presentation/cubit/home_cubit.dart`
* `lib/features/home/presentation/cubit/home_state.dart`
* `lib/features/home/presentation/screens/home_screen.dart`
* `lib/features/home/presentation/widgets/home_featured_carousel.dart`
* `lib/features/home/presentation/widgets/home_movie_card.dart`
* `lib/features/home/presentation/widgets/home_section_error.dart`
* `lib/features/home/presentation/widgets/home_section_header.dart`
* `lib/features/home/presentation/widgets/movie_poster_image.dart`
* `lib/features/main/presentation/screens/main_shell_screen.dart`
* `lib/features/main/presentation/widgets/movies_bottom_navigation_bar.dart`
* `lib/features/movie_details/presentation/screens/movie_details_screen.dart`
* `lib/features/movies/domain/entities/cast_member.dart`
* `lib/features/movies/domain/entities/movie.dart`
* `lib/features/movies/domain/entities/movie_page.dart`
* `lib/features/movies/domain/entities/movies_query.dart`
* `lib/features/movies/domain/repositories/movies_repository.dart`
* `lib/features/movies/domain/use_cases/get_movie_details.dart`
* `lib/features/movies/domain/use_cases/get_movie_suggestions.dart`
* `lib/features/movies/domain/use_cases/get_movies.dart`
* `lib/features/movies/presentation/cubit/movies_cubit.dart`
* `lib/features/movies/presentation/cubit/movies_state.dart`
* `lib/features/profile/presentation/screens/profile_screen.dart`
* `lib/features/search/presentation/screens/search_screen.dart`
* `test/app_smoke_test.dart`
* `test/features/home/home_cubit_test.dart`
* `test/features/main/bottom_navigation_test.dart`
* `test/features/movies/movie_model_test.dart`

---

## 2. Exact Files Created

* `lib/features/browse/presentation/constants/browse_genres.dart`
* `lib/features/browse/presentation/cubit/browse_state.dart`
* `lib/features/browse/presentation/cubit/browse_cubit.dart`
* `lib/features/search/presentation/cubit/search_state.dart`
* `lib/features/search/presentation/cubit/search_cubit.dart`
* `docs/reports/search_browse_implementation_report.md`

---

## 3. Exact Files Modified

* `lib/features/browse/presentation/screens/browse_screen.dart`
* `lib/features/search/presentation/screens/search_screen.dart`
* `lib/features/main/presentation/screens/main_shell_screen.dart`

---

## 4. Responsibility of Every Created File

* **`lib/features/browse/presentation/constants/browse_genres.dart`**:
  Defines the centralized, immutable list of 22 valid YTS movie genres (`Action`, `Adventure`, `Animation`, `Biography`, `Comedy`, `Crime`, `Documentary`, `Drama`, `Family`, `Fantasy`, `Film-Noir`, `History`, `Horror`, `Music`, `Musical`, `Mystery`, `Romance`, `Sci-Fi`, `Sport`, `Thriller`, `War`, `Western`) and specifies the default genre (`Action`).
* **`lib/features/browse/presentation/cubit/browse_state.dart`**:
  Represents immutable `Equatable` state for Browse including `selectedGenre`, `movies`, `status` (`initial`, `loading`, `success`, `failure`), pagination progress (`currentPage`, `totalMovieCount`, `hasReachedEnd`, `isLoadingMore`), refresh state (`isRefreshing`), primary `errorMessage`, and inline `paginationErrorMessage`.
* **`lib/features/browse/presentation/cubit/browse_cubit.dart`**:
  Manages business logic for the Browse tab via `GetMovies` constructor injection. Implements initial loading, genre switching, pull-to-refresh, page 1 to N pagination, movie deduplication by ID, and stale-response cancellation using a generation counter (`_requestVersion`).
* **`lib/features/search/presentation/cubit/search_state.dart`**:
  Represents immutable `Equatable` state for the Search tab with `query`, `movies`, `status` (`initial`, `loading`, `success`, `failure`), pagination metadata (`currentPage`, `totalMovieCount`, `hasReachedEnd`, `isLoadingMore`), `errorMessage`, and `paginationErrorMessage`. Provides convenience getters `isInitial`, `isInitialLoading`, `isEmptySuccess`, and `hasMovies`.
* **`lib/features/search/presentation/cubit/search_cubit.dart`**:
  Encapsulates Search business logic via `GetMovies` injection. Handles query trimming, immediate state clearing when queries are emptied, stale HTTP response discarding via an incrementing `_currentRequestId`, pagination, movie ID deduplication, and non-destructive pagination error handling.
* **`docs/reports/search_browse_implementation_report.md`**:
  Maintains the persistent project implementation record and Android Studio manual verification instructions.

---

## 5. Search State Structure

`SearchState` (`lib/features/search/presentation/cubit/search_state.dart`) contains:
* `status`: `SearchStatus { initial, loading, success, failure }`
* `query`: `String` (trimmed search keyword)
* `movies`: `List<Movie>` (results from YTS API)
* `currentPage`: `int` (last successfully retrieved page number, defaults to `0`)
* `totalMovieCount`: `int` (total matched results reported by API)
* `hasReachedEnd`: `bool` (whether all available pages have been retrieved)
* `isLoadingMore`: `bool` (true when an incremental pagination request is in-flight)
* `errorMessage`: `String?` (primary error displayed when initial query fails)
* `paginationErrorMessage`: `String?` (secondary error displayed inline when pagination fails)
* Getters: `isInitial`, `isInitialLoading`, `isEmptySuccess`, `hasMovies`
* `copyWith` supports explicit null resets via `clearErrorMessage` and `clearPaginationErrorMessage`.

---

## 6. Search Behavior Implemented

* Search field rendered with `#282A28` fill, radius 15, search icon, white input text, and muted placeholder text.
* Typing updates `_hasText` reactively to display or dismiss the clear button.
* Successful search results render in a 2-column grid using `HomeMovieCard`.
* Tapping a poster navigates to `RouteConstants.movieDetailsPath(movie.id)` using `context.push(...)`.
* If a search returns 0 movies, a friendly empty-state view displays the queried term.
* If a query fails with no existing movies, a retry button is displayed.
* When near the bottom of the grid, the next page is fetched without disrupting current movies.

---

## 7. Empty-Query Behavior

* When the search field contains only whitespace or is empty, no API request is sent.
* If the user clears the search field (either by deleting text or tapping the clear icon):
  * Any active debounce timer is cancelled.
  * `SearchCubit.clearSearch()` is called immediately.
  * The internal request ID (`_currentRequestId`) increments, invalidating any slower pending network responses.
  * State resets to `const SearchState()`, clearing old results.
  * The screen returns to the initial placeholder view ("Search for Movies") and does not display all movies.

---

## 8. Debounce Implementation

* An active `Timer? _debounceTimer` is maintained in `_SearchScreenState`.
* On each keystroke in `TextField.onChanged`:
  * Previous timer is cancelled via `_debounceTimer?.cancel()`.
  * If the trimmed text is empty, `clearSearch()` executes immediately without timer delay.
  * If non-empty, a 500-millisecond timer is started:
    ```dart
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _searchCubit.search(trimmed);
    });
    ```
* Tapping the clear icon button or disposing the widget cancels any pending timer immediately.

---

## 9. Stale Search-Response Protection

* `SearchCubit` maintains an internal `int _currentRequestId = 0;`.
* When `search(rawQuery)` is invoked, `final requestId = ++_currentRequestId;` is recorded.
* When an asynchronous response returns from `_getMovies(query)`:
  * The Cubit verifies: `if (isClosed || requestId != _currentRequestId) return;`.
  * If the user typed "bat" and then quickly typed "batman", the response for "bat" carries an older `requestId` and is dropped silently without replacing the "batman" results.
* `clearSearch()` also increments `++_currentRequestId`, ensuring any in-flight request cannot populate results after the user cleared the query.

---

## 10. Search Pagination Behavior

* `ScrollController` listener checks if `position.pixels >= position.maxScrollExtent - 300`.
* `SearchCubit.loadNextPage()` checks guards:
  * Ignores calls if `query` is empty, `isLoadingMore` is true, status is `loading`, `hasReachedEnd` is true, or `currentPage < 1`.
* Sets `isLoadingMore: true` and requests `page: state.currentPage + 1`.
* Merges incoming movies with existing movies using unique ID deduplication (`_mergeUniqueMovies`).
* If pagination fails:
  * `isLoadingMore` is set to `false`.
  * Existing movies are preserved on screen.
  * `paginationErrorMessage` is emitted and rendered at the bottom of the grid via `HomeSectionError` with a "Retry" button.

---

## 11. Browse State Structure

`BrowseState` (`lib/features/browse/presentation/cubit/browse_state.dart`) contains:
* `status`: `BrowseStatus { initial, loading, success, failure }`
* `selectedGenre`: `String` (defaults to `'Action'`)
* `movies`: `List<Movie>` (movies for the current genre)
* `currentPage`: `int` (last page loaded)
* `totalMovieCount`: `int`
* `hasReachedEnd`: `bool`
* `isRefreshing`: `bool` (indicates pull-to-refresh without blanking the screen)
* `isLoadingMore`: `bool` (indicates bottom pagination)
* `errorMessage`: `String?`
* `paginationErrorMessage`: `String?`
* Getters: `isInitialLoading`, `isEmptySuccess`, `hasMovies`.

---

## 12. Browse Genres

Centralized in `BrowseGenres` (`lib/features/browse/presentation/constants/browse_genres.dart`):
* `Action` (default)
* `Adventure`
* `Animation`
* `Biography`
* `Comedy`
* `Crime`
* `Documentary`
* `Drama`
* `Family`
* `Fantasy`
* `Film-Noir`
* `History`
* `Horror`
* `Music`
* `Musical`
* `Mystery`
* `Romance`
* `Sci-Fi`
* `Sport`
* `Thriller`
* `War`
* `Western`

---

## 13. Genre-Selection Behavior

* Rendered as a horizontally scrollable list of chips at the top of the Browse screen.
* Selected chip: Gold `#F6BD00` background (`AppColors.primary`), dark text `#121312` (`AppColors.onPrimary`).
* Unselected chip: Dark `#282A28` background (`AppColors.inputFill`), white text (`AppColors.onBackground`).
* Tapping a genre calls `BrowseCubit.selectGenre(genre)`.
* If the user taps the currently active genre while movies are already loaded, no redundant request is issued.
* Selecting a new genre resets pagination to page 1, clears previous movies, shows loading, and queries `MoviesQuery(genre: genre, sortBy: 'rating', orderBy: 'desc')`.

---

## 14. Stale Browse-Response Protection

* `BrowseCubit` maintains an internal `int _requestVersion = 0;`.
* Each genre switch increments `final version = ++_requestVersion;`.
* After `_getMovies(query)` resolves:
  * `if (isClosed || version != _requestVersion) return;`.
* If a user taps "Comedy" and immediately taps "Sci-Fi", the slower "Comedy" response carries an obsolete `version` and is discarded. Only "Sci-Fi" movies are emitted.

---

## 15. Browse Pagination Behavior

* `ScrollController` listener detects when scrolling within 300 pixels of the bottom.
* Duplicate calls are prevented by checking `isLoadingMore`, `isRefreshing`, `BrowseStatus.loading`, `hasReachedEnd`, and `currentPage < 1`.
* `BrowseCubit.loadNextPage()` sets `isLoadingMore: true` and queries `page: state.currentPage + 1`.
* Movies are deduplicated by `movie.id` via `_mergeUniqueMovies`.
* If pagination fails, already loaded movies remain intact on screen, and `paginationErrorMessage` is displayed with a Retry option.
* Pull-to-refresh (`RefreshIndicator`) refreshes page 1 while preserving current movies on screen until fresh data arrives.

---

## 16. Main-Shell Integration Changes

* `MainShellScreen` (`lib/features/main/presentation/screens/main_shell_screen.dart`):
  * Passes `widget.getMovies` into `SearchScreen(getMovies: widget.getMovies)` and `BrowseScreen(getMovies: widget.getMovies)`.
  * Preserves `IndexedStack` so Search and Browse stay alive in memory across bottom navigation tab switches.
  * Preserves tab order: `0: Home`, `1: Search`, `2: Browse`, `3: Profile`.
  * "See More" from `HomeScreen` continues to call `() => _selectTab(2)`, switching to Browse which is pre-loaded with `Action` movies.
  * Shared `MoviesBottomNavigationBar` remains single and unobstructed.

---

## 17. Error and Retry Behavior

* Raw `e.toString()` is never exposed to the user.
* When `AppException` is caught, its user-safe `message` is extracted and displayed.
* For unexpected errors, friendly fallbacks are emitted (`Failed to search movies.`, `Failed to load movies for [genre].`).
* Full-screen errors feature a styled "Try again" `ElevatedButton`.
* Pagination errors feature inline `HomeSectionError` with a "Retry" text button without wiping existing content.

---

## 18. Controllers / Timers Created and Disposal Confirmation

* **`SearchScreen`**:
  * `TextEditingController _searchController`: Disposed in `dispose()`.
  * `ScrollController _scrollController`: Listener removed and controller disposed in `dispose()`.
  * `Timer? _debounceTimer`: Cancelled in `dispose()`, `_clearSearch()`, and before starting a new timer.
  * `SearchCubit _searchCubit`: Closed via `_searchCubit.close()` in `dispose()`.
* **`BrowseScreen`**:
  * `ScrollController _scrollController`: Listener removed and controller disposed in `dispose()`.
  * `BrowseCubit _browseCubit`: Closed via `_browseCubit.close()` in `dispose()`.

---

## 19. Existing Shared Components Reused

* `HomeMovieCard` (`lib/features/home/presentation/widgets/home_movie_card.dart`)
* `HomeSectionError` (`lib/features/home/presentation/widgets/home_section_error.dart`)
* `MoviesBottomNavigationBar` (`lib/features/main/presentation/widgets/movies_bottom_navigation_bar.dart`)
* `AppColors` (`lib/core/theme/app_colors.dart`)
* `RouteConstants` (`lib/core/constants/route_constants.dart`)
* `ApiConstants` (`lib/core/constants/api_constants.dart`)
* `AppException` (`lib/core/errors/app_exception.dart`)
* `GetMovies` (`lib/features/movies/domain/use_cases/get_movies.dart`)
* `Movie` and `MoviesQuery` domain entities.

---

## 20. Assumptions and Unresolved Issues

* **Unverified Runtime**: Because this phase was performed under strict code-only mode, no compiler, analyzer, test runner, or emulator was executed. Code must be manually validated by the user in Android Studio.
* **Child Aspect Ratio**: Movie card grid uses `childAspectRatio: 0.68`, corresponding to standard 2:3 movie poster proportions with rating chip overlay.
* **Movie Details Navigation**: Movie cards navigate to `/movie/:id` via `RouteConstants.movieDetailsPath(movie.id)`. Full Movie Details screen implementation remains a future phase.

---

## 21. Manual Android Studio Validation Checklist

Follow the checklist in Section 10 below.

---

## 22–33. Required Confirmations

* [x] **22. Confirmation**: No terminal was opened.
* [x] **23. Confirmation**: No command was executed.
* [x] **24. Confirmation**: `flutter pub get` was not executed.
* [x] **25. Confirmation**: `flutter analyze` was not executed.
* [x] **26. Confirmation**: No tests were executed.
* [x] **27. Confirmation**: No build was executed.
* [x] **28. Confirmation**: No emulator was created or launched.
* [x] **29. Confirmation**: The application was not run.
* [x] **30. Confirmation**: No package was installed.
* [x] **31. Confirmation**: No Figma call was made.
* [x] **32. Confirmation**: Nothing was pushed to GitHub.
* [x] **33. Confirmation**: No later phase (Movie Details, Profile, Update Profile, Firebase) was started.

---

## MANUAL VALIDATION REQUIRED

Please execute the following verification steps manually in Android Studio:

### Search Validation Steps
1. Launch the app and select the **Search** tab (index 1) from the bottom navigation bar.
2. Verify that Search opens with an initial empty-search placeholder ("Search for Movies") and does **not** request or display all movies.
3. Type a movie title (e.g., `Batman`) into the search bar:
   - Verify typing debounces for ~500ms before sending a request.
   - Verify a loading indicator appears while fetching.
   - Verify matching movies render in a clean 2-column grid.
4. Tap the clear `(X)` icon in the search bar:
   - Verify the query is cleared immediately.
   - Verify old results disappear and the screen returns to the initial placeholder view.
5. Type an obscure search query that yields no results (e.g., `zzxxqq12345`):
   - Verify the empty-state view ("No movies found for ...") appears.
6. Simulate network disconnect or query failure:
   - Verify the error view appears with a "Try again" button.
   - Reconnect and tap "Try again" to confirm retry succeeds.
7. Scroll down through a long search result list:
   - Verify that approaching the bottom triggers pagination.
   - Verify the bottom loading indicator appears and new movies append smoothly.
   - Verify existing results remain visible even if pagination fails.
8. Tap any movie poster card:
   - Verify navigation to Movie Details route (`/movie/:id`).
9. Verify that the bottom navigation bar does not cover the bottom movie cards.
10. Open the keyboard and verify there is no layout overflow.

### Browse Validation Steps
1. Select the **Browse** tab (index 2) from the bottom navigation bar.
2. Verify that Browse opens with **Action** selected by default and loads Action movies sorted by rating.
3. Verify that genre chips at the top scroll horizontally.
4. Tap different genres (e.g., `Comedy`, `Horror`, `Sci-Fi`):
   - Verify the selected chip highlights in Gold (`#F6BD00`) with dark text.
   - Verify movies for that specific genre load.
5. Quickly switch between multiple genres:
   - Verify stale responses from earlier tapped genres are discarded and do not overwrite the current selection.
6. Scroll down through the movie grid:
   - Verify pagination loads additional movies for the selected genre.
7. Perform a pull-to-refresh swipe down:
   - Verify the refresh indicator spins and updates the list without flashing an empty screen.
8. Test error handling:
   - If a network error occurs, verify the error view and "Try again" button function properly.
9. Tap any movie poster card:
   - Verify navigation to Movie Details.
10. Switch to the **Home** tab (index 0) and tap **See More** on the Action section:
    - Verify it selects the Browse tab (index 2).
11. Verify the shared bottom navigation bar remains single, visible, and does not overlap content.
