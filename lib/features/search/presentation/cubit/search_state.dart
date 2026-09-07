import 'package:equatable/equatable.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

enum SearchStatus { initial, loading, success, failure }

class SearchState extends Equatable {
  const SearchState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.movies = const [],
    this.currentPage = 0,
    this.totalMovieCount = 0,
    this.hasReachedEnd = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.paginationErrorMessage,
  });

  final SearchStatus status;
  final String query;
  final List<Movie> movies;
  final int currentPage;
  final int totalMovieCount;
  final bool hasReachedEnd;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? paginationErrorMessage;

  bool get isInitial => status == SearchStatus.initial;

  bool get isInitialLoading => status == SearchStatus.loading && movies.isEmpty;

  bool get isEmptySuccess => status == SearchStatus.success && movies.isEmpty;

  bool get hasMovies => movies.isNotEmpty;

  SearchState copyWith({
    SearchStatus? status,
    String? query,
    List<Movie>? movies,
    int? currentPage,
    int? totalMovieCount,
    bool? hasReachedEnd,
    bool? isLoadingMore,
    String? errorMessage,
    String? paginationErrorMessage,
    bool clearErrorMessage = false,
    bool clearPaginationErrorMessage = false,
  }) {
    return SearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      totalMovieCount: totalMovieCount ?? this.totalMovieCount,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      paginationErrorMessage: clearPaginationErrorMessage
          ? null
          : (paginationErrorMessage ?? this.paginationErrorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    query,
    movies,
    currentPage,
    totalMovieCount,
    hasReachedEnd,
    isLoadingMore,
    errorMessage,
    paginationErrorMessage,
  ];
}
