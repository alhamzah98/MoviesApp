import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';

class GetMovieDetails {
  const GetMovieDetails(this._repository);

  final MoviesRepository _repository;

  Future<Movie> call(int movieId) {
    if (movieId <= 0) {
      throw const AppException('Movie id must be greater than zero.');
    }
    return _repository.getMovieDetails(movieId);
  }
}
