import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';

abstract class MoviesRemoteDataSource {
  Future<MoviePage> getMovies(MoviesQuery query);

  Future<Movie> getMovieDetails(int movieId);

  Future<List<Movie>> getMovieSuggestions(int movieId);
}
