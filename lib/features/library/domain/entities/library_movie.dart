import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class LibraryMovie extends Equatable {
  const LibraryMovie({
    required this.movieId,
    required this.title,
    this.year = 0,
    this.rating = 0,
    this.genres = const [],
    this.summary = '',
    this.mediumCoverImage,
    this.largeCoverImage,
    this.backgroundImage,
    this.addedAt,
    this.lastViewedAt,
    this.viewCount = 0,
  });

  final int movieId;
  final String title;
  final int year;
  final double rating;
  final List<String> genres;
  final String summary;
  final String? mediumCoverImage;
  final String? largeCoverImage;
  final String? backgroundImage;
  final DateTime? addedAt;
  final DateTime? lastViewedAt;
  final int viewCount;

  factory LibraryMovie.fromMovie(Movie movie) {
    final summary = movie.summary.trim().isNotEmpty
        ? movie.summary.trim()
        : movie.descriptionFull.trim();

    return LibraryMovie(
      movieId: movie.id,
      title: movie.title.trim(),
      year: movie.year,
      rating: movie.rating,
      genres: List<String>.unmodifiable(movie.genres),
      summary: summary,
      mediumCoverImage: _nullableTrimmed(movie.mediumCoverImage),
      largeCoverImage: _nullableTrimmed(movie.largeCoverImage),
      backgroundImage: _nullableTrimmed(
        movie.backgroundImage ?? movie.backgroundImageOriginal,
      ),
    );
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  @override
  List<Object?> get props => [
    movieId,
    title,
    year,
    rating,
    genres,
    summary,
    mediumCoverImage,
    largeCoverImage,
    backgroundImage,
    addedAt,
    lastViewedAt,
    viewCount,
  ];
}
