import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/use_cases/add_to_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/remove_from_watchlist.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/watchlist_state.dart';

class _FakeWatchlistRepository implements LibraryRepository {
  StreamController<List<LibraryMovie>> streamController =
      StreamController<List<LibraryMovie>>.broadcast();

  bool shouldFailAdd = false;
  bool shouldFailRemove = false;
  int observeCalls = 0;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() {
    observeCalls++;
    return streamController.stream;
  }

  @override
  Stream<bool> observeIsInWatchlist(int movieId) => const Stream.empty();

  @override
  Future<void> addToWatchlist(LibraryMovie movie) async {
    if (shouldFailAdd) {
      throw const AppException('Failed to add movie');
    }
  }

  @override
  Future<void> removeFromWatchlist(int movieId) async {
    if (shouldFailRemove) {
      throw const AppException('Failed to remove movie');
    }
  }

  @override
  Stream<List<LibraryMovie>> observeHistory() => const Stream.empty();

  @override
  Future<void> recordHistory(LibraryMovie movie) async {}
}

void main() {
  group('WatchlistCubit regression checks', () {
    late _FakeWatchlistRepository repository;
    late WatchlistCubit cubit;

    setUp(() {
      repository = _FakeWatchlistRepository();
      cubit = WatchlistCubit(
        observeWatchlist: ObserveWatchlist(repository),
        addToWatchlist: AddToWatchlist(repository),
        removeFromWatchlist: RemoveFromWatchlist(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test(
      'preserves existing watchlist movies when addMovie mutation fails',
      () async {
        cubit.startObserving();
        const initialMovie = LibraryMovie(movieId: 1, title: 'Inception');
        repository.streamController.add([initialMovie]);
        await pumpEventQueue();

        expect(cubit.state.movies, [initialMovie]);
        expect(cubit.state.status, WatchlistStatus.ready);

        // Attempt to add movie with failure
        repository.shouldFailAdd = true;
        const newMovie = LibraryMovie(movieId: 2, title: 'Interstellar');
        await cubit.addMovie(newMovie);

        expect(cubit.state.status, WatchlistStatus.failure);
        expect(cubit.state.errorMessage, 'Failed to add movie');
        // Existing data must remain intact!
        expect(cubit.state.movies, [initialMovie]);
        expect(cubit.state.pendingMovieIds, isEmpty);
      },
    );

    test(
      'preserves existing watchlist movies when removeMovie mutation fails',
      () async {
        cubit.startObserving();
        const initialMovie = LibraryMovie(movieId: 1, title: 'Inception');
        repository.streamController.add([initialMovie]);
        await pumpEventQueue();

        expect(cubit.state.movies, [initialMovie]);

        // Attempt to remove movie with failure
        repository.shouldFailRemove = true;
        await cubit.removeMovie(1);

        expect(cubit.state.status, WatchlistStatus.failure);
        expect(cubit.state.errorMessage, 'Failed to remove movie');
        // Existing data must remain intact!
        expect(cubit.state.movies, [initialMovie]);
        expect(cubit.state.pendingMovieIds, isEmpty);
      },
    );

    test(
      'recovers from failed observation without zombie subscription blocking retry',
      () async {
        cubit.startObserving();
        expect(repository.observeCalls, 1);

        // Stream emits error
        repository.streamController.addError(
          const AppException('Connection lost'),
        );
        await pumpEventQueue();

        expect(cubit.state.status, WatchlistStatus.failure);

        // Replace controller for fresh recovery stream
        repository.streamController =
            StreamController<List<LibraryMovie>>.broadcast();

        // Calling retry must recreate subscription
        cubit.retry();
        expect(repository.observeCalls, 2);
        expect(cubit.state.status, WatchlistStatus.loading);

        const recoveredMovie = LibraryMovie(movieId: 5, title: 'Tenet');
        repository.streamController.add([recoveredMovie]);
        await pumpEventQueue();

        expect(cubit.state.status, WatchlistStatus.ready);
        expect(cubit.state.movies, [recoveredMovie]);
      },
    );
  });
}
