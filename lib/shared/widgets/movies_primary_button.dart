import 'package:flutter/material.dart';
import 'package:movies_app/core/theme/app_colors.dart';

class MoviesPrimaryButton extends StatelessWidget {
  const MoviesPrimaryButton({
    String? label,
    String? text,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  }) : label = label ?? text ?? '';

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  static const double height = 55;
  static const double borderRadius = 15;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Text(label),
      ),
    );
  }
}
