# Movies App

A Flutter application for browsing movies, managing a personal Watch List, and tracking Viewing History using the YTS API and Firebase Firestore/Auth.

## Current Implementation Status

- **Implemented Features & Screens:**
  - **Splash & Onboarding:** Initial splash routing and persistent onboarding introduction.
  - **Authentication:** Email/Password registration, login, session coordination, profile management, and account deletion with reauthentication.
  - **Home Screen, Search & Browse:** Responsive movie carousels, categorized lists, keyword search, and genre-based browsing with pagination.
  - **Movie Details & Media:** Comprehensive metadata, cast, screenshots, similar movies, trailer launching, and watch list bookmarking.
  - **Profile & Library:** User profile display, avatar customization, profile editing, and integrated Watch List and Viewing History tabs.
  - **Localization:** Arabic and English multi-language localization with persistent user preference and dynamic switching.
  - **Security Rules & Android Setup:** Local Cloud Firestore rules ([`firestore.rules`](firestore.rules)) enforcing strict owner-only access; declarative Google Services plugin configured in Gradle.
  - **API Connectivity:** Centralized API base URL updated to `https://yts.gg/api/v2/` to restore movie loading.

- **Verified by Manual Testing:**
  - Application launches successfully.
  - Email/password registration and login confirmed functional.
  - Movie loading, carousel displays, and details verified on Android.

- **Deferred Setup & Manual Validation:**
  - **Google Sign-In:** Requires real `google-services.json` with registered SHA-1 fingerprint (see [`docs/firebase_android_setup.md`](docs/firebase_android_setup.md)).
  - **Automated Test Execution:** Comprehensive automated test suite execution remains deferred to the developer.

## Implementation Reports & Documentation

- [Manual Firebase Android Setup Guide](docs/firebase_android_setup.md)
- [Movies API Endpoint Fix Report](docs/reports/movies_api_endpoint_fix_report.md)
- [Firebase Android Preparation Report](docs/reports/firebase_android_preparation_report.md)
- [Account Deletion Corrections Report](docs/reports/account_deletion_corrections_report.md)
- [Account Deletion Implementation Report](docs/reports/account_deletion_implementation_report.md)
- [Localization & Trailer Implementation Report](docs/reports/localization_trailer_implementation_report.md)
- [Watch List & Viewing History Integration Report](docs/reports/watchlist_history_integration_report.md)
- [Authentication & Profile Integration Report](docs/reports/authentication_profile_integration_report.md)
- [Profile & Update Profile Implementation Report](docs/reports/profile_update_profile_implementation_report.md)
- [Movie Details Implementation Report](docs/reports/movie_details_implementation_report.md)
- [Search & Browse Implementation Report](docs/reports/search_browse_implementation_report.md)
