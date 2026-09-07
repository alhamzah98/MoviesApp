import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/cast_member.dart';

class Movie extends Equatable {
  const Movie({
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
    this.screenshotUrls = const [],
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
  final List<CastMember> cast;
  final List<String> screenshotUrls;

  String get bestCoverImage {
    return largeCoverImage ??
        mediumCoverImage ??
        smallCoverImage ??
        backgroundImageOriginal ??
        backgroundImage ??
        '';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    titleEnglish,
    titleLong,
    year,
    rating,
    runtime,
    genres,
    summary,
    descriptionFull,
    youtubeTrailerCode,
    language,
    mpaRating,
    likeCount,
    downloadCount,
    backgroundImage,
    backgroundImageOriginal,
    smallCoverImage,
    mediumCoverImage,
    largeCoverImage,
    cast,
    screenshotUrls,
  ];
}
