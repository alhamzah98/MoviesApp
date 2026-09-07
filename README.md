# Movies App

A Flutter application for browsing movies, managing a personal Watch List, and tracking Viewing History using the YTS API and Firebase Firestore/Auth.

## Current Implementation Status

- **Implemented Features & Screens:**
  - **Splash & Onboarding:** Initial splash routing and persistent onboarding introduction.
  - **Authentication:** Email/Password and Google sign-in/registration flows, password reset, and session coordination.
  - **Home Screen:** Popular, trending, and categorized movie displays with responsive carousel and movie cards.
  - **Search & Browse:** Keyword search and genre-based browsing with pagination.
  - **Movie Details:** Comprehensive movie metadata, cast, screenshots, similar movie recommendations, and watch list bookmark control.
  - **Profile:** User profile display, profile editing, and integrated Watch List and Viewing History tabs with independent error handling and per-item removal.
  - **Security Rules:** Local Cloud Firestore security rules ([`firestore.rules`](firestore.rules)) enforcing strict owner-only access.

- **Pending Setup & Actions:**
  - **Firebase Configuration Pending:** Firebase configuration files (`google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`) and Gradle plugin applications remain to be configured manually by the developer.
  - **Unfinished Features:** Account deletion, interactive trailer playback, and multi-language localization remain unfinished.
  - **Verification Status:** Tests have been written as source code but were not executed during this upload task under the strict code-only execution policy. Compilation and runtime correctness have not been verified during this task.

## Implementation Reports

Detailed design and implementation reports are available in the [`docs/reports/`](docs/reports/) directory:
- [Search & Browse Implementation Report](docs/reports/search_browse_implementation_report.md)
- [Movie Details Implementation Report](docs/reports/movie_details_implementation_report.md)
- [Profile & Update Profile Implementation Report](docs/reports/profile_update_profile_implementation_report.md)
- [Authentication & Profile Integration Report](docs/reports/authentication_profile_integration_report.md)
- [Watch List & Viewing History Integration Report](docs/reports/watchlist_history_integration_report.md)
