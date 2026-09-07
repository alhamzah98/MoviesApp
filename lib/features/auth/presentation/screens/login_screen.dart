import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_language_switch.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_social_button.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({this.coordinator, super.key});

  final AuthCoordinator? coordinator;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.inputFill,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onLoginPressed() async {
    if (_isSubmitting) {
      return;
    }

    final coordinator = widget.coordinator;
    if (coordinator != null && coordinator.isConfigurationUnavailable) {
      _showMessage(
        coordinator.bootstrapErrorMessage ??
            'Firebase configuration is absent. Please configure google-services.json.',
      );
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      AuthValidators.validateEmail(email);
      AuthValidators.validatePassword(password);
    } on AppException catch (e) {
      _showMessage(e.message);
      return;
    }

    final authCubit = coordinator?.authCubit;
    if (authCubit == null) {
      _showMessage('Authentication service is currently unavailable.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await authCubit.signInWithEmail(
        email: AuthValidators.normalizeEmail(email),
        password: password,
      );

      if (!mounted) return;

      if (authCubit.state.status == AuthStatus.failure) {
        _showMessage(
          authCubit.state.errorMessage ??
              'Authentication failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Authentication failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _onGoogleLoginPressed() async {
    if (_isSubmitting) {
      return;
    }

    final coordinator = widget.coordinator;
    if (coordinator != null && coordinator.isConfigurationUnavailable) {
      _showMessage(
        coordinator.bootstrapErrorMessage ??
            'Firebase configuration is absent. Please configure google-services.json.',
      );
      return;
    }

    final authCubit = coordinator?.authCubit;
    if (authCubit == null) {
      _showMessage('Authentication service is currently unavailable.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await authCubit.signInWithGoogle();

      if (!mounted) return;

      if (authCubit.state.status == AuthStatus.failure) {
        _showMessage(
          authCubit.state.errorMessage ??
              'Google sign-in failed. Please try again.',
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Google sign-in failed. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isConfigUnavailable =
        widget.coordinator?.isConfigurationUnavailable ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(19, 24, 19, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48,
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Image.asset(
                      'assets/images/splash/app_logo.png',
                      width: 121,
                      height: 118,
                      fit: BoxFit.contain,
                    ),
                    if (isConfigUnavailable) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                widget.coordinator?.bootstrapErrorMessage ??
                                    'Firebase configuration is absent. Please configure google-services.json.',
                                style: const TextStyle(
                                  color: AppColors.onBackground,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 48),
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 22),
                    AuthPasswordField(
                      controller: _passwordController,
                      hintText: 'Password',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 17),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () =>
                            context.push(RouteConstants.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Forget Password ?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    MoviesPrimaryButton(
                      label: 'Login',
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _onLoginPressed,
                    ),
                    const SizedBox(height: 23),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          color: AppColors.onBackground,
                        ),
                        children: [
                          const TextSpan(text: 'Don’t Have Account ? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go(RouteConstants.register),
                              child: const Text(
                                'Create One',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 28),
                    const _OrDivider(),
                    const SizedBox(height: 28),
                    AuthSocialButton(
                      label: 'Login With Google',
                      iconAssetPath: 'assets/images/auth/google_icon.png',
                      onPressed: _isSubmitting ? null : _onGoogleLoginPressed,
                    ),
                    const SizedBox(height: 32),
                    const AuthLanguageSwitch(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.primary, thickness: 1.12)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'OR',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.primary, thickness: 1.12)),
      ],
    );
  }
}
