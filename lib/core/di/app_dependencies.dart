import 'package:movies_app/core/network/dio_client.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:movies_app/features/home/presentation/cubit/home_cubit.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source_impl.dart';
import 'package:movies_app/features/movies/data/repositories/movies_repository_impl.dart';
import 'package:movies_app/features/movies/domain/repositories/movies_repository.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_details.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movie_suggestions.dart';
import 'package:movies_app/features/movies/domain/use_cases/get_movies.dart';

/// Lightweight composition root for constructor-injected dependencies.
///
/// Firebase Authentication/Library sources are intentionally not created here.
class AppDependencies {
  AppDependencies._({
    required this.appPreferences,
    required this.dioClient,
    required this.moviesRemoteDataSource,
    required this.moviesRepository,
    required this.getMovies,
    required this.getMovieDetails,
    required this.getMovieSuggestions,
  });

  final AppPreferences appPreferences;
  final DioClient dioClient;
  final MoviesRemoteDataSource moviesRemoteDataSource;
  final MoviesRepository moviesRepository;
  final GetMovies getMovies;
  final GetMovieDetails getMovieDetails;
  final GetMovieSuggestions getMovieSuggestions;

  static AppDependencies create() {
    final appPreferences = AppPreferences();
    final dioClient = DioClient();
    final moviesRemoteDataSource = MoviesRemoteDataSourceImpl(dioClient.client);
    final moviesRepository = MoviesRepositoryImpl(moviesRemoteDataSource);

    return AppDependencies._(
      appPreferences: appPreferences,
      dioClient: dioClient,
      moviesRemoteDataSource: moviesRemoteDataSource,
      moviesRepository: moviesRepository,
      getMovies: GetMovies(moviesRepository),
      getMovieDetails: GetMovieDetails(moviesRepository),
      getMovieSuggestions: GetMovieSuggestions(moviesRepository),
    );
  }

  HomeCubit createHomeCubit() => HomeCubit(getMovies: getMovies);
}
