import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';
import 'package:movies_app/features/library/domain/use_cases/add_to_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/observe_is_in_watchlist.dart';
import 'package:movies_app/features/library/domain/use_cases/record_history.dart';
import 'package:movies_app/features/library/domain/use_cases/remove_from_watchlist.dart';

class _UnusedLibraryRepository implements LibraryRepository {
  bool wasCalled = false;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() {
    wasCalled = true;
    return const Stream.empty();
  }

  @override
  Stream<bool> observeIsInWatchlist(int movieId) {
    wasCalled = true;
    return const Stream.empty();
  }

  @override
  Future<void> addToWatchlist(LibraryMovie movie) async {
    wasCalled = true;
  }

  @override
  Future<void> removeFromWatchlist(int movieId) async {
    wasCalled = true;
  }

  @override
  Stream<List<LibraryMovie>> observeHistory() {
    wasCalled = true;
    return const Stream.empty();
  }

  @override
  Future<void> recordHistory(LibraryMovie movie) async {
    wasCalled = true;
  }
}

void main() {
  group('Library use case validation', () {
    test('rejects invalid movie ids for watchlist and history writes', () {
      final repository = _UnusedLibraryRepository();
      const invalidMovie = LibraryMovie(movieId: 0, title: 'Dune');

      expect(
        () => AddToWatchlist(repository)(invalidMovie),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'invalid-movie-id',
          ),
        ),
      );
      expect(
        () => RecordHistory(repository)(invalidMovie),
        throwsA(isA<AppException>()),
      );
      expect(
        () => RemoveFromWatchlist(repository)(-1),
        throwsA(isA<AppException>()),
      );
      expect(
        () => ObserveIsInWatchlist(repository)(0),
        throwsA(isA<AppException>()),
      );
      expect(repository.wasCalled, isFalse);
    });
  });
}
