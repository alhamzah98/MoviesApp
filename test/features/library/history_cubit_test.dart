import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_history.dart';
import 'package:movies_app/features/library/domain/use_cases/record_history.dart';
import 'package:movies_app/features/library/presentation/cubit/history_cubit.dart';
import 'package:movies_app/features/library/presentation/cubit/history_state.dart';

class _FakeHistoryRepository implements LibraryRepository {
  StreamController<List<LibraryMovie>> streamController =
      StreamController<List<LibraryMovie>>.broadcast();

  int observeCalls = 0;
  int recordCalls = 0;
  bool shouldFailRecord = false;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() => const Stream.empty();

  @override
  Stream<bool> observeIsInWatchlist(int movieId) => const Stream.empty();

  @override
  Future<void> addToWatchlist(LibraryMovie movie) async {}

  @override
  Future<void> removeFromWatchlist(int movieId) async {}

  @override
  Stream<List<LibraryMovie>> observeHistory() {
    observeCalls++;
    return streamController.stream;
  }

  @override
  Future<void> recordHistory(LibraryMovie movie) async {
    recordCalls++;
    if (shouldFailRecord) {
      throw const AppException('Record failed');
    }
  }
}

void main() {
  group('HistoryCubit regression checks', () {
    late _FakeHistoryRepository repository;
    late HistoryCubit cubit;

    setUp(() {
      repository = _FakeHistoryRepository();
      cubit = HistoryCubit(
        observeHistory: ObserveHistory(repository),
        recordHistory: RecordHistory(repository),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('recovers from failed history observation upon retry()', () async {
      cubit.startObserving();
      expect(repository.observeCalls, 1);

      repository.streamController.addError(
        const AppException('History sync error'),
      );
      await pumpEventQueue();

      expect(cubit.state.status, HistoryStatus.failure);

      // Refresh stream controller
      repository.streamController =
          StreamController<List<LibraryMovie>>.broadcast();

      cubit.retry();
      expect(repository.observeCalls, 2);
      expect(cubit.state.status, HistoryStatus.loading);

      const movie = LibraryMovie(movieId: 10, title: 'Memento');
      repository.streamController.add([movie]);
      await pumpEventQueue();

      expect(cubit.state.status, HistoryStatus.ready);
      expect(cubit.state.movies, [movie]);
    });

    test('reset() clears movies and resets to initial status', () async {
      cubit.startObserving();
      const movie = LibraryMovie(movieId: 10, title: 'Memento');
      repository.streamController.add([movie]);
      await pumpEventQueue();

      expect(cubit.state.movies, [movie]);

      cubit.reset();
      expect(cubit.state.movies, isEmpty);
      expect(cubit.state.status, HistoryStatus.initial);
    });

    test('record failure does not lose previously loaded movies', () async {
      cubit.startObserving();
      const movie = LibraryMovie(movieId: 10, title: 'Memento');
      repository.streamController.add([movie]);
      await pumpEventQueue();

      repository.shouldFailRecord = true;
      const movie2 = LibraryMovie(movieId: 11, title: 'Oppenheimer');
      await cubit.recordMovieView(movie2);

      expect(cubit.state.status, HistoryStatus.failure);
      expect(cubit.state.movies, [movie]);
      expect(cubit.state.pendingMovieIds, isEmpty);
    });
  });
}
