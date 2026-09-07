import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_state.dart';

class _FakeAuthRepository implements AuthRepository {
  final StreamController<AppUser?> _authController =
      StreamController<AppUser?>.broadcast();
  AppUser? _user;

  void emitUser(AppUser? user) {
    _user = user;
    _authController.add(user);
  }

  @override
  Stream<AppUser?> authStateChanges() => _authController.stream;

  @override
  Future<AppUser?> getCurrentUser() async => _user;

  @override
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final user = AppUser(uid: 'uid_1', email: email);
    emitUser(user);
    return user;
  }

  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async {
    final user = AppUser(uid: 'uid_reg', email: email, name: name);
    emitUser(user);
    return user;
  }

  @override
  Future<AppUser?> signInWithGoogle() async {
    const user = AppUser(uid: 'uid_google', email: 'google@test.com');
    emitUser(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    emitUser(null);
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async {
    final updated = AppUser(
      uid: _user?.uid ?? 'uid_current',
      email: _user?.email ?? '',
      name: name,
      phoneNumber: phoneNumber,
      avatarId: avatarId,
    );
    emitUser(updated);
    return updated;
  }

  @override
  Future<void> deleteAccount() async {
    emitUser(null);
  }
}

class _FakeLibraryRepository implements LibraryRepository {
  StreamController<List<LibraryMovie>> watchlistController =
      StreamController<List<LibraryMovie>>.broadcast();
  StreamController<List<LibraryMovie>> historyController =
      StreamController<List<LibraryMovie>>.broadcast();

  int observeWatchlistCalls = 0;
  int observeHistoryCalls = 0;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() {
    observeWatchlistCalls++;
    return watchlistController.stream;
  }

  @override
  Stream<bool> observeIsInWatchlist(int movieId) {
    return watchlistController.stream
        .map((movies) => movies.any((m) => m.movieId == movieId));
  }

  @override
  Future<void> addToWatchlist(LibraryMovie movie) async {}

  @override
  Future<void> removeFromWatchlist(int movieId) async {}

  @override
  Stream<List<LibraryMovie>> observeHistory() {
    observeHistoryCalls++;
    return historyController.stream;
  }

  @override
  Future<void> recordHistory(LibraryMovie movie) async {}
}

void main() {
  group('AuthCoordinator Library Session Scope', () {
    late _FakeAuthRepository authRepo;
    late _FakeLibraryRepository libraryRepo;
    late AuthCoordinator coordinator;

    setUp(() {
      authRepo = _FakeAuthRepository();
      libraryRepo = _FakeLibraryRepository();
      coordinator = AuthCoordinator(
        authRepository: authRepo,
        libraryRepository: libraryRepo,
      );
    });

    tearDown(() {
      coordinator.dispose();
    });

    test(
      'resets and clears library data on sign-out so old-session data does not persist',
      () async {
        const userA = AppUser(uid: 'user_a', email: 'a@test.com');
        authRepo.emitUser(userA);
        await pumpEventQueue();

        expect(libraryRepo.observeWatchlistCalls, 1);

        // Emit watchlist data for user A
        const movieA = LibraryMovie(movieId: 101, title: 'User A Movie');
        libraryRepo.watchlistController.add([movieA]);
        await pumpEventQueue();

        expect(coordinator.watchlistCubit?.state.movies, [movieA]);
        expect(
          coordinator.watchlistCubit?.state.status,
          WatchlistStatus.ready,
        );

        // Sign out
        authRepo.emitUser(null);
        await pumpEventQueue();

        // Visible library data immediately cleared
        expect(coordinator.watchlistCubit?.state.movies, isEmpty);
        expect(
          coordinator.watchlistCubit?.state.status,
          WatchlistStatus.initial,
        );
      },
    );

    test(
      'restarts observation for new UID on session change without reusing previous user ready state',
      () async {
        const userA = AppUser(uid: 'user_a', email: 'a@test.com');
        authRepo.emitUser(userA);
        await pumpEventQueue();

        const movieA = LibraryMovie(movieId: 101, title: 'User A Movie');
        libraryRepo.watchlistController.add([movieA]);
        await pumpEventQueue();

        expect(coordinator.watchlistCubit?.state.movies, [movieA]);

        // User B signs in
        const userB = AppUser(uid: 'user_b', email: 'b@test.com');
        authRepo.emitUser(userB);
        await pumpEventQueue();

        // Scope was reset for user B; observe called again for the new UID
        expect(libraryRepo.observeWatchlistCalls, 2);

        // User A's data was cleared immediately
        expect(coordinator.watchlistCubit?.state.movies, isEmpty);

        // User B data arrives
        const movieB = LibraryMovie(movieId: 202, title: 'User B Movie');
        libraryRepo.watchlistController.add([movieB]);
        await pumpEventQueue();

        expect(coordinator.watchlistCubit?.state.movies, [movieB]);
      },
    );

    test(
      'ordinary profile updates for the same UID do not recreate subscriptions',
      () async {
        const userA = AppUser(uid: 'user_a', email: 'a@test.com', name: 'Original');
        authRepo.emitUser(userA);
        await pumpEventQueue();

        expect(libraryRepo.observeWatchlistCalls, 1);
        expect(libraryRepo.observeHistoryCalls, 1);

        // Emit profile update with the SAME UID
        const userAUpdated =
            AppUser(uid: 'user_a', email: 'a@test.com', name: 'Updated Name');
        authRepo.emitUser(userAUpdated);
        await pumpEventQueue();

        // Subscriptions must not have been recreated
        expect(libraryRepo.observeWatchlistCalls, 1);
        expect(libraryRepo.observeHistoryCalls, 1);
      },
    );
  });
}
