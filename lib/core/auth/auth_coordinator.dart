import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:movies_app/features/auth/data/data_sources/auth_firebase_data_source.dart';
import 'package:movies_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/auth/domain/use_cases/delete_account.dart';
import 'package:movies_app/features/auth/domain/use_cases/get_current_user.dart';
import 'package:movies_app/features/auth/domain/use_cases/observe_auth_state.dart';
import 'package:movies_app/features/auth/domain/use_cases/register_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/send_password_reset_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_email.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_in_with_google.dart';
import 'package:movies_app/features/auth/domain/use_cases/sign_out.dart';
import 'package:movies_app/features/auth/domain/use_cases/update_profile.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:movies_app/features/auth/presentation/cubit/password_reset_cubit.dart';
import 'package:movies_app/features/auth/presentation/cubit/profile_cubit.dart';
import 'package:movies_app/features/library/data/data_sources/library_firestore_data_source.dart';
import 'package:movies_app/features/library/data/repositories/library_repository_impl.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/domain/use_cases/add_to_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_history.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/record_history.dart';
import 'package:movies_app/features/library/domain/use_cases/remove_from_watchlist.dart';
import 'package:movies_app/features/library/presentation/cubit/history_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_cubit.dart';

/// Current status of the Firebase and authentication bootstrap.
enum AuthBootstrapStatus {
  uninitialized,
  initializing,
  available,
  configurationUnavailable,
  failed,
}

/// Central application-level owner for authentication lifecycle, session state,
/// router coordination, and authenticated library scope composition.
///
/// Kept synchronous on creation; initiates Firebase bootstrap when [bootstrap]
/// is invoked by an owned startup component (such as SplashScreen).
class AuthCoordinator extends ChangeNotifier {
  AuthCoordinator({
    AuthRepository? authRepository,
    LibraryRepository? libraryRepository,
  }) {
    if (authRepository != null) {
      _initServices(authRepository, libraryRepository: libraryRepository);
      _status = AuthBootstrapStatus.available;
    }
  }

  AuthBootstrapStatus _status = AuthBootstrapStatus.uninitialized;
  AuthBootstrapStatus get status => _status;

  String? _bootstrapErrorMessage;
  String? get bootstrapErrorMessage => _bootstrapErrorMessage;

  AuthRepository? _authRepository;
  AuthRepository? get authRepository => _authRepository;

  LibraryRepository? _libraryRepository;
  LibraryRepository? get libraryRepository => _libraryRepository;

  AuthCubit? _authCubit;
  AuthCubit? get authCubit => _authCubit;

  ProfileCubit? _profileCubit;
  ProfileCubit? get profileCubit => _profileCubit;

  PasswordResetCubit? _passwordResetCubit;
  PasswordResetCubit? get passwordResetCubit => _passwordResetCubit;

  WatchlistCubit? _watchlistCubit;
  WatchlistCubit? get watchlistCubit => _watchlistCubit;

  HistoryCubit? _historyCubit;
  HistoryCubit? get historyCubit => _historyCubit;

  StreamSubscription<AuthState>? _authCubitSubscription;
  Future<void>? _bootstrapFuture;
  String? _activeSessionUid;

  bool get isAvailable => _status == AuthBootstrapStatus.available;
  bool get isConfigurationUnavailable =>
      _status == AuthBootstrapStatus.configurationUnavailable;
  bool get isFailed => _status == AuthBootstrapStatus.failed;
  bool get isInitializing => _status == AuthBootstrapStatus.initializing;
  bool get isAuthenticated =>
      isAvailable && _authCubit?.state.status == AuthStatus.authenticated;
  AppUser? get currentUser => _authCubit?.state.user;

  void _initServices(
    AuthRepository repository, {
    LibraryRepository? libraryRepository,
  }) {
    _authRepository = repository;

    final observeAuthState = ObserveAuthState(repository);
    final signInWithEmail = SignInWithEmail(repository);
    final registerWithEmail = RegisterWithEmail(repository);
    final signInWithGoogle = SignInWithGoogle(repository);
    final signOut = SignOut(repository);
    final getCurrentUser = GetCurrentUser(repository);
    final updateProfile = UpdateProfile(repository);
    final deleteAccount = DeleteAccount(repository);
    final sendPasswordResetEmail = SendPasswordResetEmail(repository);

    _authCubit = AuthCubit(
      observeAuthState: observeAuthState,
      signInWithEmail: signInWithEmail,
      registerWithEmail: registerWithEmail,
      signInWithGoogle: signInWithGoogle,
      signOut: signOut,
    );

    _profileCubit = ProfileCubit(
      getCurrentUser: getCurrentUser,
      updateProfile: updateProfile,
      deleteAccount: deleteAccount,
    );

    _passwordResetCubit = PasswordResetCubit(sendPasswordResetEmail);

    if (libraryRepository != null) {
      _initLibraryServices(libraryRepository);
    }

    _authCubitSubscription = _authCubit!.stream.listen((authState) {
      final user = authState.user;
      final isAuth =
          authState.status == AuthStatus.authenticated && user != null;

      if (isAuth) {
        if (user.uid != _activeSessionUid) {
          _activeSessionUid = user.uid;
          _watchlistCubit?.reset();
          _historyCubit?.reset();
          _watchlistCubit?.startObserving();
          _historyCubit?.startObserving();
        }
      } else {
        if (_activeSessionUid != null) {
          _activeSessionUid = null;
          _watchlistCubit?.reset();
          _historyCubit?.reset();
        }
      }
      notifyListeners();
    });

    _authCubit!.startListening();
  }

  void _initLibraryServices(LibraryRepository repository) {
    _libraryRepository = repository;

    final observeWatchlist = ObserveWatchlist(repository);
    final addToWatchlist = AddToWatchlist(repository);
    final removeFromWatchlist = RemoveFromWatchlist(repository);
    final observeHistory = ObserveHistory(repository);
    final recordHistory = RecordHistory(repository);

    _watchlistCubit = WatchlistCubit(
      observeWatchlist: observeWatchlist,
      addToWatchlist: addToWatchlist,
      removeFromWatchlist: removeFromWatchlist,
    );

    _historyCubit = HistoryCubit(
      observeHistory: observeHistory,
      recordHistory: recordHistory,
    );
  }

  /// Initiates asynchronous Firebase bootstrap.
  /// Prevents concurrent or duplicate runs.
  Future<void> bootstrap() {
    if (_bootstrapFuture != null) {
      return _bootstrapFuture!;
    }
    _bootstrapFuture = _runBootstrap();
    return _bootstrapFuture!;
  }

  Future<void> _runBootstrap() async {
    if (_status == AuthBootstrapStatus.available) {
      return;
    }

    _status = AuthBootstrapStatus.initializing;
    _bootstrapErrorMessage = null;
    notifyListeners();

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final firebaseAuth = FirebaseAuth.instance;
      final firebaseFirestore = FirebaseFirestore.instance;
      final googleSignIn = GoogleSignIn();

      final remoteDataSource = AuthFirebaseDataSource(
        firebaseAuth: firebaseAuth,
        firebaseFirestore: firebaseFirestore,
        googleSignIn: googleSignIn,
      );

      final repository = AuthRepositoryImpl(remoteDataSource);

      final libraryDataSource = LibraryFirestoreDataSource(
        firebaseAuth: firebaseAuth,
        firebaseFirestore: firebaseFirestore,
      );
      final libraryRepo = LibraryRepositoryImpl(libraryDataSource);

      _initServices(repository, libraryRepository: libraryRepo);

      _status = AuthBootstrapStatus.available;
      notifyListeners();
    } on FirebaseException catch (e) {
      final message = (e.message ?? '').toLowerCase();
      final code = e.code.toLowerCase();
      final isConfigMissing = code.contains('no-app') ||
          code.contains('not-found') ||
          message.contains('no firebaseapp') ||
          message.contains('google-services') ||
          message.contains('options') ||
          message.contains('not initialized');

      if (isConfigMissing) {
        _status = AuthBootstrapStatus.configurationUnavailable;
        _bootstrapErrorMessage = e.message ??
            'Firebase configuration is missing. Please add google-services.json to android/app.';
      } else {
        _status = AuthBootstrapStatus.failed;
        _bootstrapErrorMessage = e.message ??
            'Unable to initialize Firebase services. Please check connection and retry.';
      }
      notifyListeners();
    } catch (_) {
      _status = AuthBootstrapStatus.failed;
      _bootstrapErrorMessage =
          'Unexpected error during startup initialization. Please retry.';
      notifyListeners();
    }
  }

  /// Retries Firebase bootstrap if previously failed or unavailable.
  Future<void> retryBootstrap() {
    _bootstrapFuture = null;
    return bootstrap();
  }

  /// Updates the shared in-memory user across the application without app restart.
  void updateSharedUser(AppUser updatedUser) {
    _authCubit?.updateUser(updatedUser);
    notifyListeners();
  }

  @override
  void dispose() {
    _authCubitSubscription?.cancel();
    _authCubitSubscription = null;
    _authCubit?.close();
    _profileCubit?.close();
    _passwordResetCubit?.close();
    _watchlistCubit?.close();
    _historyCubit?.close();
    super.dispose();
  }
}
