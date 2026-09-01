import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/data/data_sources/library_remote_data_source.dart';
import 'package:movies_app/features/library/data/library_error_mapper.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/library/domain/repositories/library_repository.dart';

class LibraryRepositoryImpl implements LibraryRepository {
  const LibraryRepositoryImpl(this._remoteDataSource);

  final LibraryRemoteDataSource _remoteDataSource;

  @override
  Stream<List<LibraryMovie>> observeWatchlist() {
    return _guardStream(_remoteDataSource.observeWatchlist);
  }

  @override
  Stream<bool> observeIsInWatchlist(int movieId) {
    return _guardStream(() => _remoteDataSource.observeIsInWatchlist(movieId));
  }

  @override
  Future<void> addToWatchlist(LibraryMovie movie) {
    return _guard(() => _remoteDataSource.addToWatchlist(movie));
  }

  @override
  Future<void> removeFromWatchlist(int movieId) {
    return _guard(() => _remoteDataSource.removeFromWatchlist(movieId));
  }

  @override
  Stream<List<LibraryMovie>> observeHistory() {
    return _guardStream(_remoteDataSource.observeHistory);
  }

  @override
  Future<void> recordHistory(LibraryMovie movie) {
    return _guard(() => _remoteDataSource.recordHistory(movie));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw LibraryErrorMapper.fromError(
        error,
        fallbackMessage: 'Unable to update your library. Please try again.',
      );
    }
  }

  Stream<T> _guardStream<T>(Stream<T> Function() create) {
    try {
      return create().handleError((Object error, StackTrace stackTrace) {
        final mapped = LibraryErrorMapper.fromError(
          error,
          fallbackMessage: 'Unable to load your library. Please try again.',
        );
        Error.throwWithStackTrace(mapped, stackTrace);
      });
    } on AppException catch (error) {
      return Stream<T>.error(error);
    } catch (error) {
      return Stream<T>.error(
        LibraryErrorMapper.fromError(
          error,
          fallbackMessage: 'Unable to load your library. Please try again.',
        ),
      );
    }
  }
}
