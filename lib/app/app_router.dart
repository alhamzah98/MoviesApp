import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/di/app_dependencies.dart';
import 'package:movies_app/features/auth/domain/entities/app_user.dart';
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
    final coordinator = dependencies.authCoordinator;

    return GoRouter(
      initialLocation: RouteConstants.splash,
      refreshListenable: coordinator,
      redirect: (context, state) {
        final location = state.matchedLocation;
        final isSplash = location == RouteConstants.splash;
        final isOnboarding = location == RouteConstants.onboarding;
        final isLogin = location == RouteConstants.login;
        final isRegister = location == RouteConstants.register;
        final isForgotPassword = location == RouteConstants.forgotPassword;

        // Startup screens manage their own resolution.
        if (isSplash || isOnboarding) {
          return null;
        }

        final isAuthenticated = coordinator.isAuthenticated;

        // Redirect authenticated users away from unauthenticated auth entry screens.
        if (isAuthenticated && (isLogin || isRegister)) {
          return RouteConstants.home;
        }

        // Forgot password is intentionally allowed for both unauthenticated users
        // and signed-in users (from Update Profile).
        if (isForgotPassword) {
          return null;
        }

        // Protected routes:
        // /home, /movie/:id, /update-profile
        final isProtected = location.startsWith(RouteConstants.home) ||
            location.startsWith('/movie') ||
            location == RouteConstants.updateProfile;

        if (isProtected && !isAuthenticated) {
          return RouteConstants.login;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: RouteConstants.splash,
          builder: (_, _) => SplashScreen(
            preferences: dependencies.appPreferences,
            coordinator: coordinator,
          ),
        ),
        GoRoute(
          path: RouteConstants.onboarding,
          builder: (_, _) => OnboardingScreen(
            preferences: dependencies.appPreferences,
            coordinator: coordinator,
          ),
        ),
        GoRoute(
          path: RouteConstants.login,
          builder: (_, _) => LoginScreen(coordinator: coordinator),
        ),
        GoRoute(
          path: RouteConstants.register,
          builder: (_, _) => RegisterScreen(coordinator: coordinator),
        ),
        GoRoute(
          path: RouteConstants.forgotPassword,
          builder: (_, _) => ForgotPasswordScreen(coordinator: coordinator),
        ),
        GoRoute(
          path: RouteConstants.home,
          builder: (_, _) => MainShellScreen(
            getMovies: dependencies.getMovies,
            coordinator: coordinator,
          ),
        ),
        GoRoute(
          path: RouteConstants.movieDetails,
          builder: (_, state) {
            final movieId = int.tryParse(
              state.pathParameters[RouteConstants.movieIdParam] ?? '',
            );
            return MovieDetailsScreen(
              key: ValueKey('movie_details_${movieId ?? -1}'),
              movieId: movieId,
              getMovieDetails: dependencies.getMovieDetails,
              getMovieSuggestions: dependencies.getMovieSuggestions,
              watchlistCubit: coordinator.watchlistCubit,
              historyCubit: coordinator.historyCubit,
              coordinator: coordinator,
            );
          },
        ),
        GoRoute(
          path: RouteConstants.updateProfile,
          builder: (_, state) {
            final currentAuthUser = coordinator.currentUser;
            final extraUser =
                state.extra is AppUser ? state.extra as AppUser : null;
            final user = (currentAuthUser != null &&
                    extraUser != null &&
                    extraUser.uid == currentAuthUser.uid)
                ? extraUser
                : currentAuthUser;
            return UpdateProfileScreen(
              user: user,
              coordinator: coordinator,
            );
          },
        ),
      ],
    );
  }
}
