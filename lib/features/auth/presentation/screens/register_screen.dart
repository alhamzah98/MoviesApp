import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_language_switch.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_password_field.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/features/auth/presentation/widgets/avatar_selector.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const _avatars = [
    'assets/images/auth/avatar_03.png',
    'assets/images/auth/avatar_01.png',
    'assets/images/auth/avatar_02.png',
  ];

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();

  int _selectedAvatarIndex = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Placeholder until account creation is implemented.
  void _onCreateAccountPressed() {}

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AuthAppBar(
        title: 'Register',
        onBack: () => context.go(RouteConstants.login),
      ),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + bottomInset),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
                child: Column(
                  children: [
                    AvatarSelector(
                      avatarAssetPaths: _avatars,
                      selectedIndex: _selectedAvatarIndex,
                      onSelected: (index) {
                        setState(() => _selectedAvatarIndex = index);
                      },
                    ),
                    const SizedBox(height: 12),
                    AuthTextField(
                      controller: _nameController,
                      hintText: 'Name',
                      prefixIcon: Icons.badge_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    AuthPasswordField(
                      controller: _passwordController,
                      hintText: 'Password',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    AuthPasswordField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _phoneController,
                      hintText: 'Phone Number',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 24),
                    MoviesPrimaryButton(
                      label: 'Create Account',
                      onPressed: _onCreateAccountPressed,
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
                          const TextSpan(text: 'Already Have Account ? '),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => context.go(RouteConstants.login),
                              child: const Text(
                                'Login',
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
