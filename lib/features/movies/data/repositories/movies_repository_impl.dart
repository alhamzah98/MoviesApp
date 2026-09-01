import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';

class MoviesRepositoryImpl implements MoviesRepository {
  const MoviesRepositoryImpl(this._remoteDataSource);

  final MoviesRemoteDataSource _remoteDataSource;

  @override
  Future<MoviePage> getMovies(MoviesQuery query) {
    return _guard(() => _remoteDataSource.getMovies(query));
  }

  @override
  Future<Movie> getMovieDetails(int movieId) {
    return _guard(() => _remoteDataSource.getMovieDetails(movieId));
  }

  @override
  Future<List<Movie>> getMovieSuggestions(int movieId) {
    return _guard(() => _remoteDataSource.getMovieSuggestions(movieId));
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AppException {
      rethrow;
    } catch (error) {
      throw AppException(
        'Failed to load movies data.',
        originalError: error,
      );
    }
  }
}
