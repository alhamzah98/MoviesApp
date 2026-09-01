import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class MoviePage extends Equatable {
  const MoviePage({
    required this.movies,
    required this.movieCount,
    required this.limit,
    required this.pageNumber,
  });

  final List<Movie> movies;
  final int movieCount;
  final int limit;
  final int pageNumber;

  bool get hasReachedEnd {
    if (movieCount <= 0) {
      return movies.isEmpty;
    }
    return pageNumber * limit >= movieCount || movies.isEmpty;
  }

  @override
  List<Object?> get props => [movies, movieCount, limit, pageNumber];
}
