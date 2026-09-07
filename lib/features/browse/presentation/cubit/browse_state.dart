import 'package:equatable/equatable.dart';
import 'package:movies_app/features/browse/presentation/constants/browse_genres.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';

enum BrowseStatus { initial, loading, success, failure }

class BrowseState extends Equatable {
  const BrowseState({
    this.status = BrowseStatus.initial,
    this.selectedGenre = BrowseGenres.defaultGenre,
    this.movies = const [],
    this.currentPage = 0,
    this.totalMovieCount = 0,
    this.hasReachedEnd = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.errorMessage,
    this.paginationErrorMessage,
  });

  final BrowseStatus status;
  final String selectedGenre;
  final List<Movie> movies;
  final int currentPage;
  final int totalMovieCount;
  final bool hasReachedEnd;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? paginationErrorMessage;

  bool get isInitialLoading => status == BrowseStatus.loading && movies.isEmpty;

  bool get isEmptySuccess => status == BrowseStatus.success && movies.isEmpty;

  bool get hasMovies => movies.isNotEmpty;

  BrowseState copyWith({
    BrowseStatus? status,
    String? selectedGenre,
    List<Movie>? movies,
    int? currentPage,
    int? totalMovieCount,
    bool? hasReachedEnd,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    String? paginationErrorMessage,
    bool clearErrorMessage = false,
    bool clearPaginationErrorMessage = false,
  }) {
    return BrowseState(
      status: status ?? this.status,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      movies: movies ?? this.movies,
      currentPage: currentPage ?? this.currentPage,
      totalMovieCount: totalMovieCount ?? this.totalMovieCount,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isRefreshing: isRefreshing ?? this.isRefreshing,
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
    selectedGenre,
    movies,
    currentPage,
    totalMovieCount,
    hasReachedEnd,
    isRefreshing,
    isLoadingMore,
    errorMessage,
    paginationErrorMessage,
  ];
}
