class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://yts.mx/api/v2/';

  static const String listMoviesEndpoint = 'list_movies.json';
  static const String movieDetailsEndpoint = 'movie_details.json';
  static const String movieSuggestionsEndpoint = 'movie_suggestions.json';

  static const int defaultPage = 1;
  static const int defaultLimit = 20;
  static const int maxLimit = 50;
  static const double minRating = 0;
  static const double maxRating = 9;

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
