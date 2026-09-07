import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/constants/api_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/browse/presentation/constants/browse_genres.dart';
import 'package:movies_app/features/browse/presentation/cubit/browse_state.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';

class BrowseCubit extends Cubit<BrowseState> {
  BrowseCubit({
    required GetMovies getMovies,
    String initialGenre = BrowseGenres.defaultGenre,
  })  : _getMovies = getMovies,
        super(BrowseState(selectedGenre: initialGenre));

  final GetMovies _getMovies;
  int _requestVersion = 0;

  Future<void> loadInitial() async {
    if (state.hasMovies && state.status == BrowseStatus.success) {
      return;
    }
    await _loadGenre(state.selectedGenre, isRefresh: false);
  }

  Future<void> selectGenre(String genre) async {
    final trimmed = genre.trim();
    if (trimmed.isEmpty) {
      return;
    }
    if (trimmed == state.selectedGenre &&
        state.hasMovies &&
        state.status == BrowseStatus.success) {
      return;
    }
    await _loadGenre(trimmed, isRefresh: false);
  }

  Future<void> refresh() async {
    await _loadGenre(state.selectedGenre, isRefresh: true);
  }

  Future<void> retry() async {
    await _loadGenre(state.selectedGenre, isRefresh: false);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore ||
        state.isRefreshing ||
        state.status == BrowseStatus.loading ||
        state.hasReachedEnd ||
        state.currentPage < 1) {
      return;
    }

    final currentVersion = _requestVersion;
    final nextPage = state.currentPage + 1;

    emit(
      state.copyWith(
        isLoadingMore: true,
        clearPaginationErrorMessage: true,
      ),
    );

    final query = MoviesQuery(
      genre: state.selectedGenre,
      sortBy: 'rating',
      orderBy: 'desc',
      page: nextPage,
      limit: ApiConstants.defaultLimit,
    );

    try {
      final page = await _getMovies(query);
      if (isClosed || currentVersion != _requestVersion) {
        return;
      }

      final merged = _mergeUniqueMovies(state.movies, page.movies);

      emit(
        state.copyWith(
          status: BrowseStatus.success,
          movies: merged,
          currentPage: page.pageNumber,
          totalMovieCount: page.movieCount,
          hasReachedEnd: page.hasReachedEnd || page.movies.isEmpty,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || currentVersion != _requestVersion) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed || currentVersion != _requestVersion) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: 'Failed to load more movies.',
        ),
      );
    }
  }

  Future<void> _loadGenre(String genre, {required bool isRefresh}) async {
    final version = ++_requestVersion;

    if (isRefresh) {
      emit(
        state.copyWith(
          selectedGenre: genre,
          isRefreshing: true,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          selectedGenre: genre,
          status: BrowseStatus.loading,
          movies: const [],
          currentPage: 0,
          totalMovieCount: 0,
          hasReachedEnd: false,
          isRefreshing: false,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    }

    final query = MoviesQuery(
      genre: genre,
      sortBy: 'rating',
      orderBy: 'desc',
      page: ApiConstants.defaultPage,
      limit: ApiConstants.defaultLimit,
    );

    try {
      final page = await _getMovies(query);
      if (isClosed || version != _requestVersion) {
        return;
      }

      emit(
        state.copyWith(
          status: BrowseStatus.success,
          selectedGenre: genre,
          movies: page.movies,
          currentPage: page.pageNumber,
          totalMovieCount: page.movieCount,
          hasReachedEnd: page.hasReachedEnd || page.movies.isEmpty,
          isRefreshing: false,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || version != _requestVersion) {
        return;
      }
      if (isRefresh && state.hasMovies) {
        emit(
          state.copyWith(
            isRefreshing: false,
            paginationErrorMessage: error.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: BrowseStatus.failure,
            errorMessage: error.message,
            isRefreshing: false,
            isLoadingMore: false,
          ),
        );
      }
    } catch (_) {
      if (isClosed || version != _requestVersion) {
        return;
      }
      if (isRefresh && state.hasMovies) {
        emit(
          state.copyWith(
            isRefreshing: false,
            paginationErrorMessage: 'Failed to refresh movies.',
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: BrowseStatus.failure,
            errorMessage: 'Failed to load movies for $genre.',
            isRefreshing: false,
            isLoadingMore: false,
          ),
        );
      }
    }
  }

  List<Movie> _mergeUniqueMovies(List<Movie> existing, List<Movie> incoming) {
    if (incoming.isEmpty) {
      return existing;
    }
    final seenIds = <int>{for (final movie in existing) movie.id};
    final merged = List<Movie>.of(existing);

    for (final movie in incoming) {
      if (seenIds.add(movie.id)) {
        merged.add(movie);
      }
    }
    return merged;
  }
}
