import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/storage/app_preferences.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.preferences,
    super.key,
  });

  final AppPreferences preferences;

  static const Key screenKey = Key('splash_screen');

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _minimumDisplayDuration = Duration(seconds: 2);

  bool _didStartResolution = false;

  @override
  void initState() {
    super.initState();
    _resolveStartupDestination();
  }

  Future<void> _resolveStartupDestination() async {
    if (_didStartResolution) {
      return;
    }
    _didStartResolution = true;

    final minimumDelayFuture = Future<void>.delayed(_minimumDisplayDuration);
    final onboardingCompleted = await _readOnboardingCompletedSafely();

    await minimumDelayFuture;

    if (!mounted) {
      return;
    }

    final destination = onboardingCompleted
        ? RouteConstants.login
        : RouteConstants.onboarding;
    context.go(destination);
  }

  /// Preference failures must not crash startup.
  /// Fallback destination is Onboarding.
  Future<bool> _readOnboardingCompletedSafely() async {
    try {
      return await widget.preferences.isOnboardingCompleted();
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: SplashScreen.screenKey,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoWidth = (constraints.maxWidth * 0.28).clamp(96.0, 121.0);
            final logoHeight = logoWidth * (118 / 121);
            final routeWidth = (constraints.maxWidth * 0.42).clamp(140.0, 180.0);

            return Stack(
              children: [
                Align(
                  alignment: const Alignment(0, -0.18),
                  child: Image.asset(
                    'assets/images/splash/app_logo.png',
                    width: logoWidth,
                    height: logoHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/images/splash/route_logo.png',
                          width: routeWidth,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Supervised by Mohamed Nabil',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.onBackground,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 38 / 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
