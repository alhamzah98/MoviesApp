import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/network/dio_client.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:movies_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:movies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source_impl.dart';
import 'package:movies_app/features/movies/data/repositories/movies_repository_impl.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';
import 'package:movies_app/features/movies/presentation/cubit/movie_details_cubit.dart';

/// Lightweight composition root for constructor-injected dependencies.
class AppDependencies {
  AppDependencies._({
    required this.appPreferences,
    required this.dioClient,
    required this.moviesRemoteDataSource,
    required this.moviesRepository,
    required this.getMovies,
    required this.getMovieDetails,
    required this.getMovieSuggestions,
    required this.authCoordinator,
  });

  final AppPreferences appPreferences;
  final DioClient dioClient;
  final MoviesRemoteDataSource moviesRemoteDataSource;
  final MoviesRepository moviesRepository;
  final GetMovies getMovies;
  final GetMovieDetails getMovieDetails;
  final GetMovieSuggestions getMovieSuggestions;
  final AuthCoordinator authCoordinator;

  static AppDependencies create({
    AppPreferences? appPreferences,
    DioClient? dioClient,
    MoviesRemoteDataSource? moviesRemoteDataSource,
    MoviesRepository? moviesRepository,
    AuthRepository? authRepository,
    AuthCoordinator? authCoordinator,
  }) {
    final preferences = appPreferences ?? AppPreferences();
    final client = dioClient ?? DioClient();
    final remoteDataSource =
        moviesRemoteDataSource ?? MoviesRemoteDataSourceImpl(client.client);
    final repository =
        moviesRepository ?? MoviesRepositoryImpl(remoteDataSource);
    final coordinator =
        authCoordinator ?? AuthCoordinator(authRepository: authRepository);

    return AppDependencies._(
      appPreferences: preferences,
      dioClient: client,
      moviesRemoteDataSource: remoteDataSource,
      moviesRepository: repository,
      getMovies: GetMovies(repository),
      getMovieDetails: GetMovieDetails(repository),
      getMovieSuggestions: GetMovieSuggestions(repository),
      authCoordinator: coordinator,
    );
  }

  HomeCubit createHomeCubit() => HomeCubit(getMovies: getMovies);

  MovieDetailsCubit createMovieDetailsCubit() => MovieDetailsCubit(
    getMovieDetails: getMovieDetails,
    getMovieSuggestions: getMovieSuggestions,
  );

  void dispose() {
    authCoordinator.dispose();
  }
}
