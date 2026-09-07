import 'package:dio/dio.dart';
import 'package:movies_app/core/constants/api_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/utils/json_parsers.dart';
import 'package:movies_app/features/movies/data/data_sources/movies_remote_data_source.dart';
import 'package:movies_app/features/movies/data/models/movie_model.dart';
import 'package:movies_app/features/movies/data/models/movie_page_model.dart';
import 'package:movies_app/features/movies/domain/entities/movie.dart';
import 'package:movies_app/features/movies/domain/entities/movie_page.dart';
import 'package:movies_app/features/movies/domain/entities/movies_query.dart';

class MoviesRemoteDataSourceImpl implements MoviesRemoteDataSource {
  MoviesRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<MoviePage> getMovies(MoviesQuery query) async {
    final validated = query.validated();
    final response = await _request(
      endpoint: ApiConstants.listMoviesEndpoint,
      queryParameters: validated.toQueryParameters(),
    );

    final data = _requireDataMap(response);
    return MoviePageModel.fromJson(data).toEntity();
  }

  @override
  Future<Movie> getMovieDetails(int movieId) async {
    _ensureValidMovieId(movieId);

    final response = await _request(
      endpoint: ApiConstants.movieDetailsEndpoint,
      queryParameters: {
        'movie_id': movieId,
        'with_images': true,
        'with_cast': true,
      },
    );

    final data = _requireDataMap(response);
    final movieJson = JsonParsers.asMap(data['movie']);
    if (movieJson == null) {
      throw const AppException(
        'Movie details are missing from the API response.',
      );
    }

    final movie = MovieModel.tryParse(movieJson);
    if (movie == null) {
      throw const AppException('Movie details could not be parsed.');
    }

    return movie.toEntity();
  }

  @override
  Future<List<Movie>> getMovieSuggestions(int movieId) async {
    _ensureValidMovieId(movieId);

    final response = await _request(
      endpoint: ApiConstants.movieSuggestionsEndpoint,
      queryParameters: {'movie_id': movieId},
    );

    final data = _requireDataMap(response);
    final movies = JsonParsers.asList<MovieModel>(
      data['movies'],
      MovieModel.tryParse,
    );

    return movies.map((movie) => movie.toEntity()).toList(growable: false);
  }

  Future<Map<String, dynamic>> _request({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        endpoint,
        queryParameters: queryParameters,
      );

      final payload = JsonParsers.asMap(response.data);
      if (payload == null) {
        throw AppException(
          'Unexpected API response format.',
          statusCode: response.statusCode,
        );
      }

      final status = JsonParsers.asString(payload['status'])?.toLowerCase();
      if (status != 'ok') {
        final message =
            JsonParsers.asString(payload['status_message']) ??
            'The movies API returned an error.';
        throw AppException(message, statusCode: response.statusCode);
      }

      return payload;
    } on AppException {
      rethrow;
    } on DioException catch (error) {
      throw _mapDioException(error);
    } catch (error) {
      throw AppException(
        'An unexpected error occurred while contacting the movies API.',
        originalError: error,
      );
    }
  }

  Map<String, dynamic> _requireDataMap(Map<String, dynamic> payload) {
    final data = JsonParsers.asMap(payload['data']);
    if (data == null) {
      throw const AppException('API response data is missing.');
    }
    return data;
  }

  void _ensureValidMovieId(int movieId) {
    if (movieId <= 0) {
      throw const AppException('Movie id must be greater than zero.');
    }
  }

  AppException _mapDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return AppException(
          'Connection timed out. Please try again.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.sendTimeout:
        return AppException(
          'Sending the request timed out. Please try again.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.receiveTimeout:
        return AppException(
          'The server took too long to respond. Please try again.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.connectionError:
        return AppException(
          'Unable to connect. Check your internet connection.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.badResponse:
        return AppException(
          'The movies API returned an unexpected response.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.cancel:
        return AppException(
          'The request was cancelled.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.unknown:
        return AppException(
          'An unexpected network error occurred.',
          statusCode: error.response?.statusCode,
          originalError: error,
        );
    }
  }
}
