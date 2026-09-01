import 'package:flutter_test/flutter_test.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:movies_app/features/home/presentation/cubit/home_state.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';

class _FakeMoviesRepository implements MoviesRepository {
  _FakeMoviesRepository({
    this.availableNowMovies = const [],
    this.actionMovies = const [],
    this.failAvailableNow = false,
    this.failAction = false,
  });

  List<Movie> availableNowMovies;
  List<Movie> actionMovies;
  bool failAvailableNow;
  bool failAction;

  @override
  Future<MoviePage> getMovies(MoviesQuery query) async {
    final isAction = query.genre?.toLowerCase() == 'action';
    if (isAction) {
      if (failAction) {
        throw const AppException('Action section failed.');
      }
      return MoviePage(
        movies: actionMovies,
        movieCount: actionMovies.length,
        limit: query.limit,
        pageNumber: query.page,
      );
    }

    if (failAvailableNow) {
      throw const AppException('Available Now section failed.');
    }
    return MoviePage(
      movies: availableNowMovies,
      movieCount: availableNowMovies.length,
      limit: query.limit,
      pageNumber: query.page,
    );
  }

  @override
  Future<Movie> getMovieDetails(int movieId) {
    throw UnimplementedError();
  }

  @override
  Future<List<Movie>> getMovieSuggestions(int movieId) {
    throw UnimplementedError();
  }
}

void main() {
  const availableMovie = Movie(id: 1, title: 'Available Movie');
  const actionMovie = Movie(id: 2, title: 'Action Movie');

  group('HomeCubit partial success', () {
    test('keeps a successful section when the other section fails', () async {
      final cubit = HomeCubit(
        getMovies: GetMovies(
          _FakeMoviesRepository(
            availableNowMovies: const [availableMovie],
            failAction: true,
          ),
        ),
      );

      await cubit.load();

      expect(cubit.state.status, HomeStatus.partialSuccess);
      expect(cubit.state.availableNowMovies, const [availableMovie]);
      expect(cubit.state.actionMovies, isEmpty);
      expect(cubit.state.availableNowError, isNull);
      expect(cubit.state.actionError, 'Action section failed.');

      await cubit.close();
    });

    test('preserves previous successful movies when a refresh section fails',
        () async {
      final repository = _FakeMoviesRepository(
        availableNowMovies: const [availableMovie],
        actionMovies: const [actionMovie],
      );
      final cubit = HomeCubit(getMovies: GetMovies(repository));

      await cubit.load();
      expect(cubit.state.status, HomeStatus.success);

      repository.failAction = true;
      await cubit.refresh();

      expect(cubit.state.status, HomeStatus.partialSuccess);
      expect(cubit.state.availableNowMovies, const [availableMovie]);
      expect(cubit.state.actionMovies, const [actionMovie]);
      expect(cubit.state.actionError, 'Action section failed.');

      await cubit.close();
    });
  });
}
