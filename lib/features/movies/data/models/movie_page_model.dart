import 'package:movies_app/core/constants/api_constants.dart';
import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/movies/data/models/movie_model.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';

class MoviePageModel {
  const MoviePageModel({
    required this.movies,
    required this.movieCount,
    required this.limit,
    required this.pageNumber,
  });

  final List<MovieModel> movies;
  final int movieCount;
  final int limit;
  final int pageNumber;

  factory MoviePageModel.fromJson(Map<String, dynamic> json) {
    final movies = JsonParsers.asList<MovieModel>(
      json['movies'],
      MovieModel.tryParse,
    );

    return MoviePageModel(
      movies: movies,
      movieCount: JsonParsers.asIntOr(json['movie_count'], movies.length),
      limit: JsonParsers.asIntOr(json['limit'], ApiConstants.defaultLimit),
      pageNumber: JsonParsers.asIntOr(json['page_number'], ApiConstants.defaultPage),
    );
  }

  MoviePage toEntity() {
    return MoviePage(
      movies: movies.map((movie) => movie.toEntity()).toList(growable: false),
      movieCount: movieCount,
      limit: limit,
      pageNumber: pageNumber,
    );
  }
}
