import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/presentation/cubit/password_reset_state.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({this.coordinator, super.key});

  final AuthCoordinator? coordinator;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
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

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteConstants.login);
    }
  }

  Future<void> _onVerifyEmailPressed() async {
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

    try {
      AuthValidators.validateEmail(email);
    } on AppException catch (e) {
      _showMessage(l10n.translateError(errorCode: e.code, fallback: e.message));
      return;
    }

    final resetCubit = coordinator?.passwordResetCubit;
    if (resetCubit == null) {
      _showMessage(l10n.authServiceUnavailable);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await resetCubit.submit(AuthValidators.normalizeEmail(email));

      if (!mounted) return;

      if (resetCubit.state.status == PasswordResetStatus.success) {
        _showMessage(l10n.resetPasswordSuccess);
      } else if (resetCubit.state.status == PasswordResetStatus.failure) {
        _showMessage(
          l10n.translateError(
            errorCode: resetCubit.state.errorCode,
            fallback:
                resetCubit.state.errorMessage ?? l10n.resetPasswordFailure,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.resetPasswordFailure);
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AuthAppBar(
        title: l10n.forgotPasswordTitle,
        onBack: _handleBack,
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final illustrationHeight = (constraints.maxWidth * (430 / 430))
                .clamp(220.0, 430.0);

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 24,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: illustrationHeight * 0.85,
                      child: Image.asset(
                        'assets/images/auth/forgot_password_illustration.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (widget.coordinator?.isConfigurationUnavailable ?? false) ...[
                      const SizedBox(height: 12),
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
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _emailController,
                      hintText: l10n.email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 24),
                    MoviesPrimaryButton(
                      label: l10n.verifyEmail,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _onVerifyEmailPressed,
                    ),
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
