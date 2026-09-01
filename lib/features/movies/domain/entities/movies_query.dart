import 'package:equatable/equatable.dart';
import 'package:movies_app/core/constants/api_constants.dart';

class MoviesQuery extends Equatable {
  const MoviesQuery({
    this.limit = ApiConstants.defaultLimit,
    this.page = ApiConstants.defaultPage,
    this.quality,
    this.minimumRating,
    this.queryTerm,
    this.genre,
    this.sortBy,
    this.orderBy,
    this.withRtRatings,
  });

  final int limit;
  final int page;
  final String? quality;
  final double? minimumRating;
  final String? queryTerm;
  final String? genre;
  final String? sortBy;
  final String? orderBy;
  final bool? withRtRatings;

  MoviesQuery copyWith({
    int? limit,
    int? page,
    String? quality,
    double? minimumRating,
    String? queryTerm,
    String? genre,
    String? sortBy,
    String? orderBy,
    bool? withRtRatings,
    bool clearQuality = false,
    bool clearMinimumRating = false,
    bool clearQueryTerm = false,
    bool clearGenre = false,
    bool clearSortBy = false,
    bool clearOrderBy = false,
    bool clearWithRtRatings = false,
  }) {
    return MoviesQuery(
      limit: limit ?? this.limit,
      page: page ?? this.page,
      quality: clearQuality ? null : (quality ?? this.quality),
      minimumRating:
          clearMinimumRating ? null : (minimumRating ?? this.minimumRating),
      queryTerm: clearQueryTerm ? null : (queryTerm ?? this.queryTerm),
      genre: clearGenre ? null : (genre ?? this.genre),
      sortBy: clearSortBy ? null : (sortBy ?? this.sortBy),
      orderBy: clearOrderBy ? null : (orderBy ?? this.orderBy),
      withRtRatings:
          clearWithRtRatings ? null : (withRtRatings ?? this.withRtRatings),
    );
  }

  MoviesQuery validated() {
    final safeLimit = limit.clamp(1, ApiConstants.maxLimit);
    final safePage = page < 1 ? ApiConstants.defaultPage : page;
    final safeRating = minimumRating == null
        ? null
        : minimumRating!.clamp(ApiConstants.minRating, ApiConstants.maxRating);

    return copyWith(
      limit: safeLimit,
      page: safePage,
      minimumRating: safeRating,
      clearMinimumRating: minimumRating == null,
    );
  }

  Map<String, dynamic> toQueryParameters() {
    final parameters = <String, dynamic>{
      'limit': limit,
      'page': page,
    };

    final qualityValue = quality?.trim();
    if (qualityValue != null && qualityValue.isNotEmpty) {
      parameters['quality'] = qualityValue;
    }

    if (minimumRating != null) {
      parameters['minimum_rating'] = minimumRating;
    }

    final queryTermValue = queryTerm?.trim();
    if (queryTermValue != null && queryTermValue.isNotEmpty) {
      parameters['query_term'] = queryTermValue;
    }

    final genreValue = genre?.trim();
    if (genreValue != null && genreValue.isNotEmpty) {
      parameters['genre'] = genreValue;
    }

    final sortByValue = sortBy?.trim();
    if (sortByValue != null && sortByValue.isNotEmpty) {
      parameters['sort_by'] = sortByValue;
    }

    final orderByValue = orderBy?.trim();
    if (orderByValue != null && orderByValue.isNotEmpty) {
      parameters['order_by'] = orderByValue;
    }

    if (withRtRatings != null) {
      parameters['with_rt_ratings'] = withRtRatings;
    }

    return parameters;
  }

  @override
  List<Object?> get props => [
        limit,
        page,
        quality,
        minimumRating,
        queryTerm,
        genre,
        sortBy,
        orderBy,
        withRtRatings,
      ];
}
