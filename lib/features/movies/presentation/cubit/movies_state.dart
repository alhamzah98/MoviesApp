import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';

enum MoviesStatus {
  initial,
  loading,
  success,
  failure,
}

class MoviesState extends Equatable {
  const MoviesState({
    this.status = MoviesStatus.initial,
    this.movies = const [],
    this.query = const MoviesQuery(),
    this.currentPage = 0,
    this.totalMovieCount = 0,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.isLoadingMore = false,
    this.paginationErrorMessage,
  });

  final MoviesStatus status;
  final List<Movie> movies;
  final MoviesQuery query;
  final int currentPage;
  final int totalMovieCount;
  final bool hasReachedEnd;
  final String? errorMessage;
  final bool isLoadingMore;
  final String? paginationErrorMessage;

  bool get isInitialLoading =>
      status == MoviesStatus.loading && movies.isEmpty;

  bool get isEmptySuccess =>
      status == MoviesStatus.success && movies.isEmpty;

  MoviesState copyWith({
    MoviesStatus? status,
    List<Movie>? movies,
    MoviesQuery? query,
    int? currentPage,
    int? totalMovieCount,
    bool? hasReachedEnd,
    String? errorMessage,
    bool? isLoadingMore,
    String? paginationErrorMessage,
    bool clearErrorMessage = false,
    bool clearPaginationErrorMessage = false,
  }) {
    return MoviesState(
      status: status ?? this.status,
      movies: movies ?? this.movies,
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
      totalMovieCount: totalMovieCount ?? this.totalMovieCount,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      paginationErrorMessage: clearPaginationErrorMessage
          ? null
          : (paginationErrorMessage ?? this.paginationErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        movies,
        query,
        currentPage,
        totalMovieCount,
        hasReachedEnd,
        errorMessage,
        isLoadingMore,
        paginationErrorMessage,
      ];
}
