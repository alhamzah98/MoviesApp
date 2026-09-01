class RouteConstants {
  RouteConstants._();

  static const String movieIdParam = 'id';

  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String movieDetails = '/movie/:$movieIdParam';
  static const String updateProfile = '/update-profile';

  static String movieDetailsPath(int movieId) => '/movie/$movieId';
}
