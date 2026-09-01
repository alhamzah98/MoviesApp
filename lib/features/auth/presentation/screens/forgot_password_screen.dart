import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:movies_app/core/constants/route_constants.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_app_bar.dart';
import 'package:movies_app/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  /// Placeholder until password-reset email verification is implemented.
  void _onVerifyEmailPressed() {}

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AuthAppBar(
        title: 'Forget Password',
        onBack: () => context.go(RouteConstants.login),
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
                constraints: BoxConstraints(minHeight: constraints.maxHeight - 24),
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
                    const SizedBox(height: 24),
                    AuthTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 24),
                    MoviesPrimaryButton(
                      label: 'Verify Email',
                      onPressed: _onVerifyEmailPressed,
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
