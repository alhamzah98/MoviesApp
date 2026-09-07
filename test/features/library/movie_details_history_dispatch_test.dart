import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_history.dart';
import 'package:movies_app/features/library/domain/use_cases/record_history.dart';
import 'package:movies_app/features/library/presentation/cubit/history_cubit.dart';
import 'package:movies_app/features/movie_details/presentation/screens/movie_details_screen.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';

class _FakeAuthRepo implements AuthRepository {
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  @override
  Stream<AppUser?> authStateChanges() => _controller.stream;
  @override
  Future<AppUser?> getCurrentUser() async =>
      const AppUser(uid: 'uid_test', email: 'test@example.com');
  @override
  Future<AppUser> signInWithEmail({required String email, required String password}) async =>
      throw UnimplementedError();
  @override
  Future<AppUser> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phoneNumber,
    required String avatarId,
  }) async => throw UnimplementedError();
  @override
  Future<AppUser?> signInWithGoogle() async => throw UnimplementedError();
  @override
  Future<void> signOut() async {}
  @override
  Future<void> sendPasswordResetEmail(String email) async {}
  @override
  Future<AppUser> updateProfile({
    required String name,
    required String phoneNumber,
    required String avatarId,
  }) async => throw UnimplementedError();
  @override
  Future<void> deleteAccount() async {}
}

class _FakeLibraryRepo implements LibraryRepository {
  int recordHistoryCalls = 0;
  final List<int> recordedMovieIds = [];

  @override
  Stream<List<LibraryMovie>> observeWatchlist() => const Stream.empty();
  @override
  Stream<bool> observeIsInWatchlist(int movieId) => const Stream.empty();
  @override
  Future<void> addToWatchlist(LibraryMovie movie) async {}
  @override
  Future<void> removeFromWatchlist(int movieId) async {}
  @override
  Stream<List<LibraryMovie>> observeHistory() => const Stream.empty();
  @override
  Future<void> recordHistory(LibraryMovie movie) async {
    recordHistoryCalls++;
    recordedMovieIds.add(movie.movieId);
  }
}

class _FakeMoviesRepo implements MoviesRepository {
  final Completer<List<Movie>> suggestionsCompleter = Completer<List<Movie>>();
  int getSuggestionsCalls = 0;

  @override
  Future<List<Movie>> getMovies({int page = 1, int limit = 20, int minimumRating = 0, String? queryTerm, String? genre, String? sortBy, String? orderBy}) async => [];

  @override
  Future<Movie> getMovieDetails(int id) async {
    return Movie(
      id: id,
      title: 'Dune: Part Two',
      year: 2024,
      rating: 8.6,
      genres: const ['Action', 'Sci-Fi'],
      summary: 'Paul Atreides unites with Chani and the Fremen.',
    );
  }

  @override
  Future<List<Movie>> getMovieSuggestions(int id) {
    getSuggestionsCalls++;
    return suggestionsCompleter.future;
  }
}

void main() {
  group('MovieDetails History duplicate-dispatch regression check', () {
    testWidgets(
      'records history once on movie details load and does NOT dispatch again on suggestions completion or rebuild',
      (tester) async {
        final authRepo = _FakeAuthRepo();
        final libraryRepo = _FakeLibraryRepo();
        final moviesRepo = _FakeMoviesRepo();

        final historyCubit = HistoryCubit(
          observeHistory: ObserveHistory(libraryRepo),
          recordHistory: RecordHistory(libraryRepo),
        );

        final coordinator = AuthCoordinator(
          authRepository: authRepo,
          libraryRepository: libraryRepo,
        );

        final getMovieDetails = GetMovieDetails(moviesRepo);
        final getMovieSuggestions = GetMovieSuggestions(moviesRepo);

        await tester.pumpWidget(
          MaterialApp(
            home: MovieDetailsScreen(
              movieId: 100,
              getMovieDetails: getMovieDetails,
              getMovieSuggestions: getMovieSuggestions,
              historyCubit: historyCubit,
              coordinator: coordinator,
            ),
          ),
        );

        // Initial pump: loading movie details
        expect(libraryRepo.recordHistoryCalls, 0);

        // Let details load complete
        await tester.pumpAndSettle();

        // Exactly one history recording dispatched
        expect(libraryRepo.recordHistoryCalls, 1);
        expect(libraryRepo.recordedMovieIds, [100]);

        // Complete suggestions asynchronously
        const suggestionMovie = Movie(id: 101, title: 'Blade Runner 2049');
        moviesRepo.suggestionsCompleter.complete([suggestionMovie]);
        await tester.pumpAndSettle();

        // Must still be 1 (suggestions completion must NOT trigger another record dispatch!)
        expect(libraryRepo.recordHistoryCalls, 1);

        // Trigger widget rebuilds
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Rebuilds must NOT trigger another dispatch!
        expect(libraryRepo.recordHistoryCalls, 1);

        historyCubit.close();
        coordinator.dispose();
      },
    );
  });
}
