import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';
import 'package:movies_app/shared/widgets/movies_primary_button.dart';

class AuthSocialButton extends StatelessWidget {
  const AuthSocialButton({
    required this.label,
    required this.iconAssetPath,
    required this.onPressed,
    super.key,
  });

  final String label;
  final String iconAssetPath;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: MoviesPrimaryButton.height,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.inputFill,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MoviesPrimaryButton.borderRadius),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(iconAssetPath, width: 26, height: 26),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColors.inputFill,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
