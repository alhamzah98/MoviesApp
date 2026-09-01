import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';

class GetMovieSuggestions {
  const GetMovieSuggestions(this._repository);

  final MoviesRepository _repository;

  Future<List<Movie>> call(int movieId) {
    if (movieId <= 0) {
      throw const AppException('Movie id must be greater than zero.');
    }
    return _repository.getMovieSuggestions(movieId);
  }
}
