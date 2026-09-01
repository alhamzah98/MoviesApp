import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/home/presentation/cubit/home_state.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetMovies getMovies,
  })  : _getMovies = getMovies,
        super(const HomeState());

  static const MoviesQuery availableNowQuery = MoviesQuery(
    page: 1,
    limit: 10,
    sortBy: 'date_added',
    orderBy: 'desc',
  );

  static const MoviesQuery actionQuery = MoviesQuery(
    page: 1,
    limit: 10,
    genre: 'Action',
    sortBy: 'rating',
    orderBy: 'desc',
  );

  final GetMovies _getMovies;

  Future<void> load() => _load();

  Future<void> refresh() => _load();

  Future<void> retryAvailableNow() => _retrySection(isAvailableNow: true);

  Future<void> retryAction() => _retrySection(isAvailableNow: false);

  Future<void> _load() async {
    if (state.isLoading) {
      return;
    }

    emit(
      state.copyWith(
        status: HomeStatus.loading,
        clearAvailableNowError: true,
        clearActionError: true,
      ),
    );

    final results = await Future.wait([
      _fetchSection(availableNowQuery),
      _fetchSection(actionQuery),
    ]);

    final availableResult = results[0];
    final actionResult = results[1];

    final availableMovies = availableResult.error == null
        ? availableResult.movies
        : state.availableNowMovies;
    final actionMovies = actionResult.error == null
        ? actionResult.movies
        : state.actionMovies;

    emit(
      HomeState(
        status: _resolveStatus(
          availableMovies: availableMovies,
          actionMovies: actionMovies,
          availableNowError: availableResult.error,
          actionError: actionResult.error,
        ),
        availableNowMovies: availableMovies,
        actionMovies: actionMovies,
        availableNowError: availableResult.error,
        actionError: actionResult.error,
      ),
    );
  }

  Future<void> _retrySection({required bool isAvailableNow}) async {
    if (state.isLoading) {
      return;
    }

    emit(
      state.copyWith(
        status: HomeStatus.loading,
        clearAvailableNowError: isAvailableNow,
        clearActionError: !isAvailableNow,
      ),
    );

    final result = await _fetchSection(
      isAvailableNow ? availableNowQuery : actionQuery,
    );

    final availableMovies = isAvailableNow
        ? (result.error == null ? result.movies : state.availableNowMovies)
        : state.availableNowMovies;
    final actionMovies = isAvailableNow
        ? state.actionMovies
        : (result.error == null ? result.movies : state.actionMovies);
    final availableError =
        isAvailableNow ? result.error : state.availableNowError;
    final actionError = isAvailableNow ? state.actionError : result.error;

    emit(
      HomeState(
        status: _resolveStatus(
          availableMovies: availableMovies,
          actionMovies: actionMovies,
          availableNowError: availableError,
          actionError: actionError,
        ),
        availableNowMovies: availableMovies,
        actionMovies: actionMovies,
        availableNowError: availableError,
        actionError: actionError,
      ),
    );
  }

  Future<({List<Movie> movies, String? error})> _fetchSection(
    MoviesQuery query,
  ) async {
    try {
      final page = await _getMovies(query);
      return (movies: page.movies, error: null);
    } on AppException catch (error) {
      return (movies: const <Movie>[], error: error.message);
    } catch (_) {
      return (
        movies: const <Movie>[],
        error: 'Unable to load movies. Please try again.',
      );
    }
  }

  HomeStatus _resolveStatus({
    required List<Movie> availableMovies,
    required List<Movie> actionMovies,
    required String? availableNowError,
    required String? actionError,
  }) {
    final availableFailed = availableNowError != null;
    final actionFailed = actionError != null;
    final hasMovies = availableMovies.isNotEmpty || actionMovies.isNotEmpty;

    if (availableFailed && actionFailed) {
      return hasMovies ? HomeStatus.partialSuccess : HomeStatus.failure;
    }

    if (availableFailed || actionFailed) {
      return HomeStatus.partialSuccess;
    }

    if (!hasMovies) {
      return HomeStatus.empty;
    }

    return HomeStatus.success;
  }
}
