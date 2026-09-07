import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context);
    final coordinator = widget.coordinator;
    if (coordinator != null && coordinator.isConfigurationUnavailable) {
      _showMessage(
        coordinator.bootstrapErrorMessage ?? l10n.firebaseConfigMissing,
      );
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      AuthValidators.validateEmail(email);
      AuthValidators.validatePassword(password);
    } on AppException catch (e) {
      _showMessage(l10n.translateError(errorCode: e.code, fallback: e.message));
      return;
    }

    final authCubit = coordinator?.authCubit;
    if (authCubit == null) {
      _showMessage(l10n.authServiceUnavailable);
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
          l10n.translateError(
            errorCode: authCubit.state.errorCode,
            fallback: authCubit.state.errorMessage ?? l10n.authFailed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.authFailed);
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

    final l10n = AppLocalizations.of(context);
    final coordinator = widget.coordinator;
    if (coordinator != null && coordinator.isConfigurationUnavailable) {
      _showMessage(
        coordinator.bootstrapErrorMessage ?? l10n.firebaseConfigMissing,
      );
      return;
    }

    final authCubit = coordinator?.authCubit;
    if (authCubit == null) {
      _showMessage(l10n.authServiceUnavailable);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await authCubit.signInWithGoogle();

      if (!mounted) return;

      if (authCubit.state.status == AuthStatus.failure) {
        _showMessage(
          l10n.translateError(
            errorCode: authCubit.state.errorCode,
            fallback: authCubit.state.errorMessage ?? l10n.authFailed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.authFailed);
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                                    l10n.firebaseConfigMissing,
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
                      hintText: l10n.email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 22),
                    AuthPasswordField(
                      controller: _passwordController,
                      hintText: l10n.password,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 17),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton(
                        onPressed: () =>
                            context.push(RouteConstants.forgotPassword),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          l10n.forgotPasswordPrompt,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 34),
                    MoviesPrimaryButton(
                      label: l10n.login,
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
                          TextSpan(text: '${l10n.dontHaveAccount} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go(RouteConstants.register),
                              child: Text(
                                l10n.createOne,
                                style: const TextStyle(
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
                    _OrDivider(label: l10n.orDivider.toUpperCase()),
                    const SizedBox(height: 28),
                    AuthSocialButton(
                      label: l10n.loginWithGoogle,
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
  const _OrDivider({this.label = 'OR'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.primary, thickness: 1.12)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              height: 1.2,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.primary, thickness: 1.12)),
      ],
    );
  }
}
