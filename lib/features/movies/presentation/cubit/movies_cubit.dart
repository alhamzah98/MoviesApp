import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/constants/api_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';
import 'package:movies_app/features/movies/presentation/cubit/movies_state.dart';

class MoviesCubit extends Cubit<MoviesState> {
  MoviesCubit(this._getMovies) : super(const MoviesState());

  final GetMovies _getMovies;

  Future<void> loadInitial({MoviesQuery? query}) {
    final nextQuery = (query ?? const MoviesQuery())
        .copyWith(page: ApiConstants.defaultPage)
        .validated();
    return _load(query: nextQuery, append: false);
  }

  Future<void> refresh() {
    final nextQuery = state.query.copyWith(page: ApiConstants.defaultPage).validated();
    return _load(query: nextQuery, append: false);
  }

  Future<void> applyQuery(MoviesQuery query) {
    final nextQuery = query.copyWith(page: ApiConstants.defaultPage).validated();
    return _load(query: nextQuery, append: false);
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore ||
        state.status == MoviesStatus.loading ||
        state.hasReachedEnd ||
        state.currentPage < 1) {
      return;
    }

    final nextQuery = state.query
        .copyWith(page: state.currentPage + 1)
        .validated();

    emit(
      state.copyWith(
        isLoadingMore: true,
        clearPaginationErrorMessage: true,
      ),
    );

    try {
      final page = await _getMovies(nextQuery);
      final mergedMovies = _mergeUniqueMovies(state.movies, page.movies);

      emit(
        state.copyWith(
          status: MoviesStatus.success,
          movies: mergedMovies,
          query: nextQuery,
          currentPage: page.pageNumber,
          totalMovieCount: page.movieCount,
          hasReachedEnd: page.hasReachedEnd || page.movies.isEmpty,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: error.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
          paginationErrorMessage: 'Failed to load more movies.',
        ),
      );
    }
  }

  Future<void> _load({
    required MoviesQuery query,
    required bool append,
  }) async {
    emit(
      state.copyWith(
        status: MoviesStatus.loading,
        query: query,
        isLoadingMore: false,
        clearErrorMessage: true,
        clearPaginationErrorMessage: true,
        movies: append ? state.movies : const [],
        hasReachedEnd: false,
      ),
    );

    try {
      final page = await _getMovies(query);
      final movies = append
          ? _mergeUniqueMovies(state.movies, page.movies)
          : page.movies;

      emit(
        state.copyWith(
          status: MoviesStatus.success,
          movies: movies,
          query: query,
          currentPage: page.pageNumber,
          totalMovieCount: page.movieCount,
          hasReachedEnd: page.hasReachedEnd || page.movies.isEmpty,
          isLoadingMore: false,
          clearErrorMessage: true,
          clearPaginationErrorMessage: true,
        ),
      );
    } on AppException catch (error) {
      emit(
        state.copyWith(
          status: MoviesStatus.failure,
          errorMessage: error.message,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: MoviesStatus.failure,
          errorMessage: 'Failed to load movies.',
          isLoadingMore: false,
        ),
      );
    }
  }

  List<Movie> _mergeUniqueMovies(
    List<Movie> existing,
    List<Movie> incoming,
  ) {
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
