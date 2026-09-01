import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';

class LibraryValidators {
  LibraryValidators._();

  static void validateMovieId(int movieId) {
    if (movieId <= 0) {
      throw const AppException(
        'Movie id must be greater than zero.',
        code: 'invalid-movie-id',
      );
    }
  }

  static void validateSnapshot(LibraryMovie movie) {
    validateMovieId(movie.movieId);
    if (movie.title.trim().isEmpty) {
      throw const AppException(
        'A movie title is required to save this item.',
        code: 'invalid-movie',
      );
    }
  }
}
