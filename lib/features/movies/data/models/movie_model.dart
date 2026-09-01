import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/movies/data/models/cast_member_model.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

class MovieModel {
  const MovieModel({
    required this.id,
    required this.title,
    this.titleEnglish = '',
    this.titleLong = '',
    this.year = 0,
    this.rating = 0,
    this.runtime = 0,
    this.genres = const [],
    this.summary = '',
    this.descriptionFull = '',
    this.youtubeTrailerCode,
    this.language = '',
    this.mpaRating = '',
    this.likeCount = 0,
    this.downloadCount = 0,
    this.backgroundImage,
    this.backgroundImageOriginal,
    this.smallCoverImage,
    this.mediumCoverImage,
    this.largeCoverImage,
    this.cast = const [],
  });

  final int id;
  final String title;
  final String titleEnglish;
  final String titleLong;
  final int year;
  final double rating;
  final int runtime;
  final List<String> genres;
  final String summary;
  final String descriptionFull;
  final String? youtubeTrailerCode;
  final String language;
  final String mpaRating;
  final int likeCount;
  final int downloadCount;
  final String? backgroundImage;
  final String? backgroundImageOriginal;
  final String? smallCoverImage;
  final String? mediumCoverImage;
  final String? largeCoverImage;
  final List<CastMemberModel> cast;

  factory MovieModel.fromJson(Map<String, dynamic> json) {
    final genres = JsonParsers.asList<String>(json['genres'], (element) {
      if (element is! String) {
        return null;
      }
      final value = element.trim();
      if (value.isEmpty) {
        return null;
      }
      return value;
    });

    final cast = JsonParsers.asList<CastMemberModel>(
      json['cast'],
      CastMemberModel.tryParse,
    );

    return MovieModel(
      id: JsonParsers.asIntOr(json['id'], 0),
      title: JsonParsers.asStringOrEmpty(json['title']),
      titleEnglish: JsonParsers.asStringOrEmpty(json['title_english']),
      titleLong: JsonParsers.asStringOrEmpty(json['title_long']),
      year: JsonParsers.asIntOr(json['year'], 0),
      rating: JsonParsers.asDoubleOr(json['rating'], 0),
      runtime: JsonParsers.asIntOr(json['runtime'], 0),
      genres: genres,
      summary: JsonParsers.asStringOrEmpty(json['summary']),
      descriptionFull: JsonParsers.asStringOrEmpty(json['description_full']),
      youtubeTrailerCode: JsonParsers.asString(json['yt_trailer_code']),
      language: JsonParsers.asStringOrEmpty(json['language']),
      mpaRating: JsonParsers.asStringOrEmpty(json['mpa_rating']),
      likeCount: JsonParsers.asIntOr(json['like_count'], 0),
      downloadCount: JsonParsers.asIntOr(json['download_count'], 0),
      backgroundImage: JsonParsers.asString(json['background_image']),
      backgroundImageOriginal:
          JsonParsers.asString(json['background_image_original']),
      smallCoverImage: JsonParsers.asString(json['small_cover_image']),
      mediumCoverImage: JsonParsers.asString(json['medium_cover_image']),
      largeCoverImage: JsonParsers.asString(json['large_cover_image']),
      cast: cast,
    );
  }

  static MovieModel? tryParse(Object? value) {
    final map = JsonParsers.asMap(value);
    if (map == null) {
      return null;
    }
    final model = MovieModel.fromJson(map);
    if (model.id <= 0 || model.title.trim().isEmpty) {
      return null;
    }
    return model;
  }

  Movie toEntity() {
    return Movie(
      id: id,
      title: title,
      titleEnglish: titleEnglish,
      titleLong: titleLong,
      year: year,
      rating: rating,
      runtime: runtime,
      genres: genres,
      summary: summary,
      descriptionFull: descriptionFull,
      youtubeTrailerCode: youtubeTrailerCode,
      language: language,
      mpaRating: mpaRating,
      likeCount: likeCount,
      downloadCount: downloadCount,
      backgroundImage: backgroundImage,
      backgroundImageOriginal: backgroundImageOriginal,
      smallCoverImage: smallCoverImage,
      mediumCoverImage: mediumCoverImage,
      largeCoverImage: largeCoverImage,
      cast: cast.map((member) => member.toEntity()).toList(growable: false),
    );
  }
}
