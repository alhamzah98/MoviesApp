import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/auth/auth_coordinator.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/errors/app_exception.dart';
import 'package:movies_app/core/localization/app_localizations.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/domain/auth_validators.dart';
import 'package:movies_app/features/auth/presentation/cubit/auth_state.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_language_switch.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/features/auth/presentation/widgets/avatar_selector.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.coordinator, super.key});

  final AuthCoordinator? coordinator;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _avatars = [
    'assets/images/auth/avatar_03.png',
    'assets/images/auth/avatar_01.png',
    'assets/images/auth/avatar_02.png',
  ];

  static const _avatarIds = [
    'avatar_03',
    'avatar_01',
    'avatar_02',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedAvatarIndex = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
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

  Future<void> _onCreateAccountPressed() async {
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

    final name = _nameController.text;
    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final phone = _phoneController.text;
    final avatarId = _avatarIds[_selectedAvatarIndex.clamp(0, _avatarIds.length - 1)];

    try {
      AuthValidators.validateName(name);
      AuthValidators.validateEmail(email);
      AuthValidators.validateRegistrationPassword(password);
      AuthValidators.validatePasswordConfirmation(
        password: password,
        confirmPassword: confirmPassword,
      );
      AuthValidators.validatePhoneNumber(phone);
      AuthValidators.validateAvatarId(avatarId);
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
      await authCubit.registerWithEmail(
        name: AuthValidators.normalizeName(name),
        email: AuthValidators.normalizeEmail(email),
        password: password,
        confirmPassword: confirmPassword,
        phoneNumber: AuthValidators.normalizePhone(phone),
        avatarId: avatarId,
      );

      if (!mounted) return;

      if (authCubit.state.status == AuthStatus.failure) {
        _showMessage(
          l10n.translateError(
            errorCode: authCubit.state.errorCode,
            fallback: authCubit.state.errorMessage ?? l10n.registrationFailed,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        _showMessage(l10n.registrationFailed);
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
        title: l10n.register,
        onBack: () => context.go(RouteConstants.login),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  children: [
                    AvatarSelector(
                      avatarAssetPaths: _avatars,
                      selectedIndex: _selectedAvatarIndex,
                      onSelected: (index) {
                        setState(() => _selectedAvatarIndex = index);
                      },
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
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _nameController,
                      hintText: l10n.name,
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _emailController,
                      hintText: l10n.email,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 24),
                    AuthPasswordField(
                      controller: _passwordController,
                      hintText: l10n.password,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 24),
                    AuthPasswordField(
                      controller: _confirmPasswordController,
                      hintText: l10n.confirmPassword,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _phoneController,
                      hintText: l10n.phoneNumber,
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textDirection: TextDirection.ltr,
                    ),
                    const SizedBox(height: 24),
                    MoviesPrimaryButton(
                      label: l10n.createAccount,
                      isLoading: _isSubmitting,
                      onPressed: _isSubmitting ? null : _onCreateAccountPressed,
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.2,
                          color: AppColors.onBackground,
                        ),
                        children: [
                          TextSpan(text: '${l10n.alreadyHaveAccount} '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go(RouteConstants.login),
                              child: Text(
                                l10n.login,
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
                    const SizedBox(height: 18),
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
