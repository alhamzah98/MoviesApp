import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';

class GetMovies {
  const GetMovies(this._repository);

  final MoviesRepository _repository;

  Future<MoviePage> call(MoviesQuery query) {
    final validated = query.validated();
    if (validated.page < 1) {
      throw const AppException('Page must be greater than or equal to 1.');
    }
    if (validated.limit < 1 || validated.limit > 50) {
      throw const AppException('Limit must be between 1 and 50.');
    }
    return _repository.getMovies(validated);
  }
}
