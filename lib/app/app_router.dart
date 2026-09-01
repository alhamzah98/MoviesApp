import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/di/app_dependencies.dart';
import 'package:movies_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:movies_app/features/auth/presentation/screens/login_screen.dart';
import 'package:movies_app/features/auth/presentation/screens/register_screen.dart';
import 'package:movies_app/features/main/presentation/screens/main_shell_screen.dart';
import 'package:movies_app/features/movie_details/presentation/screens/movie_details_screen.dart';
import 'package:movies_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:movies_app/features/profile/presentation/screens/update_profile_screen.dart';
import 'package:movies_app/features/splash/presentation/screens/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static GoRouter create(AppDependencies dependencies) {
    return GoRouter(
      initialLocation: RouteConstants.splash,
      routes: [
        GoRoute(
          path: RouteConstants.splash,
          builder: (_, _) => SplashScreen(
            preferences: dependencies.appPreferences,
          ),
        ),
        GoRoute(
          path: RouteConstants.onboarding,
          builder: (_, _) => OnboardingScreen(
            preferences: dependencies.appPreferences,
          ),
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (_, _) => const LoginScreen(),
        ),
        GoRoute(
          path: RouteConstants.register,
          builder: (_, _) => const RegisterScreen(),
        ),
        GoRoute(
          path: RouteConstants.forgotPassword,
          builder: (_, _) => const ForgotPasswordScreen(),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (_, _) => MainShellScreen(
            getMovies: dependencies.getMovies,
          ),
        ),
        GoRoute(
          path: RouteConstants.movieDetails,
          builder: (_, state) {
            final movieId = int.tryParse(
              state.pathParameters[RouteConstants.movieIdParam] ?? '',
            );
            return MovieDetailsScreen(movieId: movieId);
          },
        ),
        GoRoute(
          path: RouteConstants.updateProfile,
          builder: (_, _) => const UpdateProfileScreen(),
        ),
      ],
    );
  }
}
