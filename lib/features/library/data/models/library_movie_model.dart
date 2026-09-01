import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/library/domain/entities/library_movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class LibraryMovieModel {
  const LibraryMovieModel({
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

  factory LibraryMovieModel.fromMap(
    Map<String, dynamic> map, {
    String? documentId,
  }) {
    return LibraryMovieModel(
      movieId: JsonParsers.asInt(map['movieId']) ??
          JsonParsers.asInt(documentId) ??
          0,
      title: JsonParsers.asStringOrEmpty(map['title']).trim(),
      year: JsonParsers.asIntOr(map['year'], 0),
      rating: JsonParsers.asDoubleOr(map['rating'], 0),
      genres: JsonParsers.asList<String>(map['genres'], _genreFrom),
      summary: JsonParsers.asStringOrEmpty(map['summary']).trim(),
      mediumCoverImage: _nullableTrimmed(JsonParsers.asString(map['mediumCoverImage'])),
      largeCoverImage: _nullableTrimmed(JsonParsers.asString(map['largeCoverImage'])),
      backgroundImage: _nullableTrimmed(JsonParsers.asString(map['backgroundImage'])),
      addedAt: parseDateTime(map['addedAt']),
      lastViewedAt: parseDateTime(map['lastViewedAt']),
      viewCount: JsonParsers.asIntOr(map['viewCount'], 0),
    );
  }

  factory LibraryMovieModel.fromEntity(LibraryMovie movie) {
    return LibraryMovieModel(
      movieId: movie.movieId,
      title: movie.title.trim(),
      year: movie.year,
      rating: movie.rating,
      genres: List<String>.unmodifiable(movie.genres),
      summary: movie.summary.trim(),
      mediumCoverImage: _nullableTrimmed(movie.mediumCoverImage),
      largeCoverImage: _nullableTrimmed(movie.largeCoverImage),
      backgroundImage: _nullableTrimmed(movie.backgroundImage),
      addedAt: movie.addedAt,
      lastViewedAt: movie.lastViewedAt,
      viewCount: movie.viewCount,
    );
  }

  factory LibraryMovieModel.fromMovie(Movie movie) {
    return LibraryMovieModel.fromEntity(LibraryMovie.fromMovie(movie));
  }

  static DateTime? parseDateTime(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is double) {
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final dynamic dynamicValue = value;
      final toDate = dynamicValue.toDate;
      if (toDate is Function) {
        final result = toDate.call();
        if (result is DateTime) {
          return result;
        }
      }
      final millis = dynamicValue.millisecondsSinceEpoch;
      if (millis is int) {
        return DateTime.fromMillisecondsSinceEpoch(millis);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  LibraryMovie toEntity() {
    return LibraryMovie(
      movieId: movieId,
      title: title,
      year: year,
      rating: rating,
      genres: List<String>.unmodifiable(genres),
      summary: summary,
      mediumCoverImage: mediumCoverImage,
      largeCoverImage: largeCoverImage,
      backgroundImage: backgroundImage,
      addedAt: addedAt,
      lastViewedAt: lastViewedAt,
      viewCount: viewCount,
    );
  }

  Map<String, dynamic> toWatchlistWriteMap() {
    return {
      ..._snapshotMap(),
    };
  }

  Map<String, dynamic> toHistoryWriteMap() {
    return {
      ..._snapshotMap(),
    };
  }

  Map<String, dynamic> _snapshotMap() {
    return {
      'movieId': movieId,
      'title': title,
      'year': year,
      'rating': rating,
      'genres': genres,
      'summary': summary,
      'mediumCoverImage': mediumCoverImage,
      'largeCoverImage': largeCoverImage,
      'backgroundImage': backgroundImage,
    };
  }

  static String? _genreFrom(Object? value) {
    if (value is! String) {
      return null;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String? _nullableTrimmed(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }
}
