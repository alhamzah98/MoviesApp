import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/constants/api_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';
import 'package:movies_app/features/search/presentation/cubit/search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit({required GetMovies getMovies})
      : _getMovies = getMovies,
        super(const SearchState());

  final GetMovies _getMovies;
  int _currentRequestId = 0;

  Future<void> search(String rawQuery) async {
    final trimmed = rawQuery.trim();

    if (trimmed.isEmpty) {
      clearSearch();
      return;
    }

    if (trimmed == state.query &&
        state.status == SearchStatus.success &&
        state.hasMovies) {
      return;
    }

    final requestId = ++_currentRequestId;

    emit(
      state.copyWith(
        status: SearchStatus.loading,
        query: trimmed,
        movies: const [],
        currentPage: 0,
        totalMovieCount: 0,
        hasReachedEnd: false,
        isLoadingMore: false,
        clearErrorMessage: true,
        clearPaginationErrorMessage: true,
      ),
    );

    final query = MoviesQuery(
      queryTerm: trimmed,
      page: ApiConstants.defaultPage,
      limit: ApiConstants.defaultLimit,
    );

    try {
      final page = await _getMovies(query);
      if (isClosed || requestId != _currentRequestId) {
        return;
      }

      emit(
        state.copyWith(
          status: SearchStatus.success,
          movies: page.movies,
          currentPage: page.pageNumber,
          totalMovieCount: page.movieCount,
          hasReachedEnd: page.hasReachedEnd || page.movies.isEmpty,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      if (isClosed || requestId != _currentRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: error.message,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _currentRequestId) {
        return;
      }
      emit(
        state.copyWith(
          status: SearchStatus.failure,
          errorMessage: 'Failed to search movies.',
          isLoadingMore: false,
        ),
      );
    }
  }

  void clearSearch() {
    ++_currentRequestId;
    emit(const SearchState());
  }

  Future<void> retry() async {
    if (state.query.trim().isEmpty) {
      clearSearch();
      return;
    }
    await search(state.query);
  }

  Future<void> loadNextPage() async {
    if (state.query.trim().isEmpty ||
        state.isLoadingMore ||
        state.status == SearchStatus.loading ||
        state.hasReachedEnd ||
        state.currentPage < 1) {
      return;
    }

    final requestId = _currentRequestId;
    final nextPage = state.currentPage + 1;

    emit(
      state.copyWith(
        isLoadingMore: true,
        clearPaginationErrorMessage: true,
      ),
    );

    final query = MoviesQuery(
      queryTerm: state.query,
      page: nextPage,
      limit: ApiConstants.defaultLimit,
    );

    try {
      final page = await _getMovies(query);
      if (isClosed || requestId != _currentRequestId) {
        return;
      }

      final merged = _mergeUniqueMovies(state.movies, page.movies);

      emit(
        state.copyWith(
          status: SearchStatus.success,
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
      if (isClosed || requestId != _currentRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: error.message,
        ),
      );
    } catch (_) {
      if (isClosed || requestId != _currentRequestId) {
        return;
      }
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: 'Failed to load more results.',
        ),
      );
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
